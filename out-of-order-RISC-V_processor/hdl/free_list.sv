module free_list
#(
    parameter DATA_WIDTH = 8,      // Width of data bus
    parameter QUEUE_DEPTH = 16     // Depth of FIFO queue
)
(
    input logic clk,
    input logic rst,

    input logic [DATA_WIDTH-1:0] wdata,  // Input data to enqueue
    input logic enqueue,                 // Enqueue signal

    output logic [DATA_WIDTH-1:0] rdata, // Output data to dequeue
    input logic dequeue,                 // Dequeue signal
    
    output logic full,                   // Full flag
    output logic empty,                   // Empty flag

    input logic flush
);
    localparam  DEPTH_WIDTH = $clog2(QUEUE_DEPTH);
    localparam REM_ZEROS = 32 - DEPTH_WIDTH;
    // Internal signals
    logic [DATA_WIDTH-1:0] queue [QUEUE_DEPTH-1:0]; // Queue storage
    logic [DEPTH_WIDTH-1:0] head, tail, head_next, tail_next;     // Head and Tail pointers
    logic overflow_bit;                             // Extra bit to track when tail laps head

    // Full and Empty logic
    assign empty = (head == tail) && !overflow_bit; // Empty when head == tail and no overflow
    assign full = (head == tail) && overflow_bit;   // Full when head == tail and overflow

    always_comb begin
        if (rst) begin
            // Reset logic
            head_next = '0;
            tail_next = '0;
        end else begin
            head_next = head;
            tail_next = tail;
            // Only enqueue (push)
            if (enqueue && !full) begin
                tail_next = DEPTH_WIDTH'(({REM_ZEROS'(0),tail} + 1) % QUEUE_DEPTH);  // Move tail forward
            end 
            
            // Only dequeue (pop)
            if (dequeue && !empty) begin
                head_next = DEPTH_WIDTH'(({REM_ZEROS'(0),head} + 1) % QUEUE_DEPTH);  // Move head forward
            end
        end        
    end 

    // Enqueue and Dequeue logic
    always_ff @(posedge clk) begin
        if (rst) begin
            // Reset logic
            for (int unsigned i = 0; i < 32; i++) begin
                // queue[i] <= i[5:0] + 6'd32;
                queue[i] <= 6'(i) + 6'd32;
            end
            head <= '0;
            tail <= '0;
            overflow_bit <= 1'b1;
        end else if (flush) begin
            if(enqueue) queue[tail] <= wdata;

            // head <= tail;
            tail <= '0;
            head <= '0;
            // tail <= head;
            overflow_bit <= 1'b1;        
        end else begin
            // Only enqueue (push)
            if (enqueue && !full) begin
                queue[tail] <= wdata;
                // tail <= DEPTH_WIDTH'((tail + 1) % QUEUE_DEPTH);  // Move tail forward
                tail <= tail_next;
                if (tail_next == head_next)                  // If tail laps head
                    overflow_bit <= 1'b1;          // Set overflow bit
            end 
            
            // Only dequeue (pop)
            if (dequeue && !empty) begin
                // rdata <= queue[head];
                // head <= DEPTH_WIDTH'((head + 1) % QUEUE_DEPTH);  // Move head forward
                head <= head_next;
                if (head_next == tail_next)                  // If head catches up to tail
                    overflow_bit <= 1'b0;          // Clear overflow bit
            end
        end
    end

    assign rdata = !empty && dequeue ? queue[head] : 'x;

endmodule
