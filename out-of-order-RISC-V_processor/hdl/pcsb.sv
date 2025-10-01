module pcsb
import rv32i_types::*;
#(
    // parameter DATA_WIDTH_PCSB = 65,
    parameter BUFFER_DEPTH = 5
)
(
    input logic clk, 
    input logic rst,

    // From LSQ (dfp_data)
    // input   logic   [3:0]   lsq_rmask,
    input   logic   [31:0]  lsq_addr,           // Non byte aligned addr
    // input   lsq_t           lsq_entry_head,
    input   logic           empty_lsq,
    input   logic           store_buffer_commit,
    input   logic   [3:0]   lsq_store_wmask,
    input   logic   [31:0]  lsq_store_wdata,
    input   logic   [3:0]   lsq_rmask,


    // To LSQ (for loads)
    // output  logic   [31:0]  forward_addr_load,
    // output  logic           dequeue,

    output  logic           full,

    // To D-Cache
    output   logic   [3:0]   dfp_wmask,
    output   logic   [31:0]  dfp_wdata,
    output   logic   [31:0]  dfp_addr,
    // From D-cache
    input logic dfp_resp,

    // Arbiter
    input logic load,
    output  logic           forward_resp_load,
    output  logic   [31:0]  forward_rdata_load,
    output logic mask_loads,

    input logic invalid_dfp_flush,
    output logic mask_conflict
);

    localparam DEPTH_WIDTH_BUF = $clog2(BUFFER_DEPTH);
    localparam REM_ZEROS = 32 - DEPTH_WIDTH_BUF;
    // Internal signals
    // logic [DATA_WIDTH_PCSB-1 : 0] queue [BUFFER_DEPTH-1:0];  
    pcsb_t queue [BUFFER_DEPTH-1:0];                           // Queue storage
    logic [DEPTH_WIDTH_BUF-1:0] head, tail, head_next, tail_next;
    //  current;       // Head and Tail pointers
    // int current;
    logic overflow_bit;                                                          // Extra bit to track when tail laps head
    
    logic enqueue;     
    logic dequeue;                                                 // Actual Data inside the LSQ array
    logic empty;

    logic service_store;

    // if load comes in when store is being serviced (lsq was empty but not now)
    // logic mask_loads;

    // logic [DEPTH_WIDTH_BUF:0] num_elements; // One extra bit to handle full queue
    // assign num_elements = (tail >= head) ? 4'(tail - head) : 4'(BUFFER_DEPTH - head + tail);

    // Full and Empty logic
    assign empty = (head == tail) && !overflow_bit;                         // Empty when head == tail and no overflow
    assign full = (head == tail) && overflow_bit;                           // Full when head == tail and overflow
    // assign dequeue =  ((lsq_entry_head.rvfi_packet.inst[6:0] == op_b_store && full) || empty_lsq_pcsb) ? 1'b1 : 1'b0;
    assign service_store = !invalid_dfp_flush && queue[head].valid && ((lsq_store_wmask != '0 && full) || empty_lsq || mask_loads || mask_conflict);
    assign dequeue = service_store  && dfp_resp;
    assign enqueue = store_buffer_commit;

    always_ff @(posedge clk) begin
        if (rst) begin
            mask_loads <= 1'b0;
        end else if (service_store) begin
            mask_loads <= 1'b1;
        end else begin
            mask_loads <= 1'b0;
        end
        // else if (dequeue) begin
        //     mask_loads <= 1'b0;
        // end
    end

    logic read;

    always_ff @(posedge clk) begin
        if (rst) begin
            read <= 1'b0;
        end else if (load) begin
            read <= 1'b1;
        end else if (read) begin
            read <= 1'b0;
        end
    end

    logic [3:0] local_rmask;

    always_ff @(posedge clk) begin
        if (rst) begin
            local_rmask <= '0;
        end else if (load) begin
            local_rmask <= lsq_rmask;
        end 
    end    


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
                tail_next = DEPTH_WIDTH_BUF'(({REM_ZEROS'(0),tail} + 1) % BUFFER_DEPTH);  // Move tail forward
            end 
        
            // Only dequeue (pop)
            if (dequeue && !empty) begin
                head_next = DEPTH_WIDTH_BUF'(({REM_ZEROS'(0),head} + 1) % BUFFER_DEPTH);  // Move head forward
            end
        end        
    end

    // Need to check between which dfp_addr to use based on whether it is a store or load
    // Only when dequeue happens in this pcsb is when you want to use the dfp_addr from here otherwise use the one from LSQ

    // Enqueue and Dequeue logic
    always_ff @(posedge clk) begin
        if (rst) begin
            head <= '0;
            tail <= '0;
            overflow_bit <= 1'b0;
            for(int i = 0; i < BUFFER_DEPTH; i++) begin
                // queue[i][64] <= 1'b0;
                // queue[i][63:0] <= 'x;
                queue[i].valid <= 1'b0;
                queue[i].data <= 'x;
                queue[i].addr <= 'x;
                queue[i].wmask <= 'x;
            end
        end else begin
            // Only enqueue (push)
            if (enqueue && !full) begin
                // queue[tail][64] <= 1'b1;
                // queue[tail][63:0] <= {dfp_wdata, lsq_addr};
                queue[tail].valid <= 1'b1;
                queue[tail].data <= lsq_store_wdata;
                queue[tail].addr <= lsq_addr;
                queue[tail].wmask <= lsq_store_wmask;
                tail <= tail_next;
                if (tail_next == head_next)
                    overflow_bit <= 1'b1;
            end 
            
            // Only dequeue (pop)
            if (dequeue && !empty) begin
                // queue[head][64] <= 1'b0;
                // queue[head][63:0] <= 'x;
                queue[head].valid <= 1'b0;
                head <= head_next;
                if (head_next == tail_next)        // If head catches up to tail
                    overflow_bit <= 1'b0;          // Clear overflow bit
            end 
        end            
    end

    // Store ports to D-Cache
    always_comb begin
        dfp_wmask = '0;
        dfp_addr = 'x;
        dfp_wdata = 'x;
        if (service_store && !dfp_resp) begin
            dfp_wmask = queue[head].wmask;
            dfp_wdata = queue[head].data;
            dfp_addr = queue[head].addr;
        end
    end

    // forwarding data to load
    always_comb begin

        // dfp_addr = {queue[head][31:2], 2'b00};
        // forward_addr_load = 'x;
        forward_resp_load = 1'b0;
        forward_rdata_load = 'x;
        mask_conflict = 1'b0;

        if (read) begin
            for (int unsigned i = BUFFER_DEPTH; i > 0; i--) begin
                // int current = ((tail + BUFFER_DEPTH -i) % BUFFER_DEPTH);
                if (queue[((tail + BUFFER_DEPTH -i) % BUFFER_DEPTH)].valid && queue[((tail + BUFFER_DEPTH -i) % BUFFER_DEPTH)].addr == lsq_addr) begin
                    // forward_addr_load = queue[current][31:0];
                    if (local_rmask == queue[((tail + BUFFER_DEPTH -i) % BUFFER_DEPTH)].wmask) begin
                        forward_rdata_load = queue[((tail + BUFFER_DEPTH -i) % BUFFER_DEPTH)].data;
                        forward_resp_load = 1'b1;
                    end else begin
                        mask_conflict = 1'b1;
                    end
                    break;
                end
            end
        end
    end

endmodule : pcsb