// import "DPI-C" function string getenv(input string env_name);
// module top_tb;

//     timeunit 1ps;
//     timeprecision 1ps;

//     // Parameters
//     parameter DATA_WIDTH = 8;
//     parameter QUEUE_DEPTH = 16;

//     // Clock period setup (in ps)
//     int clock_half_period_ps = 5000; // Example value, can be adjusted as needed
//     bit clk;
//     int random_seed;

//     // Clock generation
//     always #(clock_half_period_ps) clk = ~clk;

//     // Signals
//     logic rst;
//     logic enqueue, dequeue;
//     logic [DATA_WIDTH-1:0] wdata, rdata;
//     logic full, empty;

//     // Timeout for the testbench
//     int timeout = 100000; // In cycles, adjust as needed

//     // Instantiate FIFO DUT
//     FIFO #(
//         .DATA_WIDTH(DATA_WIDTH),
//         .QUEUE_DEPTH(QUEUE_DEPTH)
//     ) fifo (
//         .clk(clk),
//         .rst(rst),
//         .wdata(wdata),
//         .enqueue(enqueue),
//         .rdata(rdata),
//         .dequeue(dequeue),
//         .full(full),
//         .empty(empty)
//     );

//     initial begin
//         // Dump waveforms for debugging
//         $fsdbDumpfile("dump.fsdb");
//         $fsdbDumpvars(0, "+all");
//         // random_seed = 32'd12345;
//         // $urandom(random_seed);  // Seed the random generator

//         // // Initialize signals
//         // clk <= 1'b0;
//         // rst <= 1'b1;
//         // enqueue <= 1'b0;
//         // dequeue <= 1'b0;
//         // wdata <= 8'h00;

//         // // Apply reset
//         // repeat (2) @(posedge clk);
//         // rst <= 1'b0;

//         // // Run test scenarios
//         // test_fifo();

//         // // Finish the testbench
//         // $finish;

//             // Initialize signals
//         clk <= 1'b0;
//         rst <= 1'b1;
//         enqueue <= 1'b0;
//         dequeue <= 1'b0;
//         wdata <= 8'h00;

//         // Apply reset
//         repeat (2) @(posedge clk);
//         rst <= 1'b0;

//         // Run test scenarios
//         test_full_condition();
//         test_empty_condition();
//         test_full_enqueue();
//         test_empty_condition();
//         test_empty_dequeue();
//         test_reset_behavior();
//         test_single_element();
//         test_simultaneous_enqueue_dequeue();
//         test_fifo_underflow();
//         test_fifo_overflow_protection();
//         test_enqueue_full_dequeue_partial();
//         // test_randomized_operations();

//         // Finish the testbench
//         $finish;
//     end
    
//         // Test 1: Fill the FIFO completely and check full flag
//     task test_full_condition;
//         $display("Starting Full Condition Test...");
//         for (int i = 0; i < QUEUE_DEPTH; i++) begin
//             @(posedge clk);
//             enqueue <= 1'b1;
//             wdata <= 8'(i);                 // Push data into FIFO
//         end
//         @(posedge clk);
//         enqueue <= 1'b0;
//         @(posedge clk);
//         if (full) begin
//             $display("Test Passed: FIFO is full after enqueuing max elements.");
//         end else begin
//             $error("Test Failed: FIFO should be full.");
//         end
//     endtask

//     // Test 2: Dequeue all elements and check empty flag
//     task test_empty_condition;
//         $display("Starting Empty Condition Test...");
//         for (int i = 0; i < QUEUE_DEPTH; i++) begin
//             @(posedge clk);
//             dequeue <= 1'b1;
//         end
//         @(posedge clk);
//         dequeue <= 1'b0;
//         @(posedge clk);
//         if (empty) begin
//             $display("Test Passed: FIFO is empty after dequeuing all elements.");
//         end else begin
//             $error("Test Failed: FIFO should be empty.");
//         end
//     endtask

//     // Test 3: Try to enqueue when FIFO is full
//     task test_full_enqueue;
//         $display("Starting Full Enqueue Test...");
//         for (int i = 0; i < QUEUE_DEPTH; i++) begin
//             @(posedge clk);
//             enqueue <= 1'b1;
//             wdata <= 8'(i);
//         end
//         @(posedge clk);
//         enqueue <= 1'b1;
//         wdata <= 8'hFF;  // Try to enqueue when full
//         @(posedge clk);
//         enqueue <= 1'b0;
//         @(posedge clk);
//         if (full) begin
//             $display("Test Passed: No enqueue possible when FIFO is full.");
//         end else begin
//             $error("Test Failed: Enqueued when FIFO was full.");
//         end
//     endtask

//     // Test 4: Try to dequeue when FIFO is empty
//     task test_empty_dequeue;
//         $display("Starting Empty Dequeue Test...");
//         @(posedge clk);
//         dequeue <= 1'b1;  // Try to dequeue when empty
//         @(posedge clk);
//         dequeue <= 1'b0;
//         @(posedge clk);
//         if (empty) begin
//             $display("Test Passed: No dequeue possible when FIFO is empty.");
//         end else begin
//             $error("Test Failed: Dequeued when FIFO was empty.");
//         end
//     endtask

//     // Test 5: Reset behavior
//     task test_reset_behavior;
//         $display("Starting Reset Behavior Test...");
//         // Fill FIFO halfway
//         for (int i = 0; i < QUEUE_DEPTH / 2; i++) begin
//             @(posedge clk);
//             enqueue <= 1'b1;
//             wdata <= 8'(i);
//         end
//         @(posedge clk);
//         enqueue <= 1'b0;

//         // Apply reset
//         @(posedge clk);
//         rst <= 1'b1;
//         @(posedge clk);
//         rst <= 1'b0;
        
//         // Check if FIFO is empty after reset
//         @(posedge clk);
//         if (empty && !full) begin
//             $display("Test Passed: FIFO correctly reset.");
//         end else begin
//             $error("Test Failed: FIFO reset did not behave as expected.");
//         end
//     endtask

//     // Test 6: Single element enqueue and dequeue
//     task test_single_element;
//         $display("Starting Single Element Test...");
//         @(posedge clk);
//         enqueue <= 1'b1;
//         wdata <= 8'hAA;  // Enqueue one element
//         @(posedge clk);
//         enqueue <= 1'b0;

//         @(posedge clk);
//         dequeue <= 1'b1;  // Dequeue that one element
//         @(posedge clk);
//         dequeue <= 1'b0;

//         @(posedge clk);
//         @(posedge clk);
//         if (empty && !full) begin
//             $display("Test Passed: Single element enqueue/dequeue works correctly.");
//         end else begin
//             $error("Test Failed: Single element behavior is incorrect.");
//         end
//     endtask
//         // Test 7: Simultaneous enqueue and dequeue (back-to-back)
//     task test_simultaneous_enqueue_dequeue;
//         $display("Starting Back-to-Back Enqueue/Dequeue Test...");
        
//         // Enqueue an element
//         @(posedge clk);
//         enqueue <= 1'b1;
//         wdata <= 8'h11;
//         @(posedge clk);
//         enqueue <= 1'b0;

//         // Immediately dequeue the element on the next clock cycle
//         @(posedge clk);
//         dequeue <= 1'b1;
//         @(posedge clk);
//         dequeue <= 1'b0;

//         // Assert that FIFO is empty after the dequeue
//         @(posedge clk);
//         if (empty) begin
//             $display("Test Passed: FIFO is empty after back-to-back enqueue/dequeue.");
//         end else begin
//             $error("Test Failed: FIFO is not empty after back-to-back enqueue/dequeue.");
//         end
//     endtask

//     // Test 8: FIFO underflow scenario (dequeue more than enqueued)
//     task test_fifo_underflow;
//         $display("Starting FIFO Underflow Test...");
        
//         // Enqueue one element
//         @(posedge clk);
//         enqueue <= 1'b1;
//         wdata <= 8'h22;
//         @(posedge clk);
//         enqueue <= 1'b0;

//         // Dequeue the element
//         @(posedge clk);
//         dequeue <= 1'b1;
//         @(posedge clk);
//         dequeue <= 1'b0;

//         // Try to dequeue again when the FIFO is empty (underflow)
//         @(posedge clk);
//         dequeue <= 1'b1;
//         @(posedge clk);
//         dequeue <= 1'b0;

//         // Assert that FIFO is still empty after underflow attempt
//         @(posedge clk);
//         if (empty) begin
//             $display("Test Passed: FIFO correctly handled underflow.");
//         end else begin
//             $error("Test Failed: FIFO underflow did not behave correctly.");
//         end
//     endtask

//     // Test 9: FIFO overflow protection
//     task test_fifo_overflow_protection;
//         $display("Starting FIFO Overflow Protection Test...");
        
//         // Enqueue elements until the FIFO is full
//         for (int i = 0; i < QUEUE_DEPTH; i++) begin
//             @(posedge clk);
//             enqueue <= 1'b1;
//             wdata <= 8'(i);
//         end
//         @(posedge clk);
//         enqueue <= 1'b0;

//         // Try to enqueue one more element (should not be allowed)
//         @(posedge clk);
//         enqueue <= 1'b1;
//         wdata <= 8'hFF;  // Overflow attempt
//         @(posedge clk);
//         enqueue <= 1'b0;

//         // Assert the FIFO remains full and no new data is overwritten
//         @(posedge clk);
//         if (full) begin
//             $display("Test Passed: FIFO remains full, no data was overwritten.");
//         end else begin
//             $error("Test Failed: FIFO should remain full, no new data should be enqueued.");
//         end
//     endtask

//     // Test 10: Enqueue until full, dequeue partially, then enqueue again
//     task test_enqueue_full_dequeue_partial;
//         $display("Starting Partial Dequeue and Re-Enqueue Test...");
        
//         // Enqueue elements until full
//         for (int i = 0; i < QUEUE_DEPTH; i++) begin
//             @(posedge clk);
//             enqueue <= 1'b1;
//             wdata <= 8'(i);
//         end
//         @(posedge clk);
//         enqueue <= 1'b0;

//         // Dequeue half of the elements
//         for (int i = 0; i < QUEUE_DEPTH / 2; i++) begin
//             @(posedge clk);
//             dequeue <= 1'b1;
//         end
//         @(posedge clk);
//         dequeue <= 1'b0;

//         // Enqueue new elements to fill the FIFO again
//         for (int i = 0; i < QUEUE_DEPTH / 2; i++) begin
//             @(posedge clk);
//             enqueue <= 1'b1;
//             wdata <= 8'(i + QUEUE_DEPTH);  // New data
//         end
//         @(posedge clk);
//         enqueue <= 1'b0;

//         // Assert the FIFO is full again after partial dequeue and re-enqueue
//         @(posedge clk);
//         if (full) begin
//             $display("Test Passed: FIFO is full after partial dequeue and re-enqueue.");
//         end else begin
//             $error("Test Failed: FIFO should be full after partial dequeue and re-enqueue.");
//         end
//     endtask


//     // // Test 11: Randomized push and pop operations
//     // task test_randomized_operations;
//     //     $display("Starting Randomized Operations Test...");

//     //     // Perform 100 random enqueue or dequeue operations
//     //     for (int i = 0; i < 100; i++) begin
//     //         @(posedge clk);
//     //         if ($urandom_range(0, 1)) begin
//     //             if (!full) begin
//     //                 enqueue <= 1'b1;
//     //                 wdata <= $urandom_range(0, 255)[7:0];  // Random data
//     //                 $display("Random Enqueue: %h", wdata);
//     //             end
//     //         end else if (!empty) begin
//     //             dequeue <= 1'b1;
//     //             $display("Random Dequeue: %h", rdata);
//     //         end
//     //         @(posedge clk);
//     //         enqueue <= 1'b0;
//     //         dequeue <= 1'b0;
//     //     end
//     // endtask


//     // Task to run FIFO test cases
//     // task test_fifo;
//     //     // Basic FIFO Test: Enqueue and Dequeue
//     //     @(posedge clk);
        
//     //     // Enqueue elements until full
//     //     $display("Starting FIFO Enqueue...");
//     //     for (int i = 0; i < QUEUE_DEPTH; i++) begin
//     //         $display("Dsiplaying the tags full = ", full," Empty = ", empty);
//     //         @(posedge clk);
//     //         if (!rst && !full) begin
//     //             wdata <= 8'(i);                 // Push data into FIFO
//     //             enqueue <= 1'b1;
//     //             $display("Enqueueing: %0d", wdata);
//     //             $display("Enqueue value: ", enqueue);
//     //         end else begin
//     //             enqueue <= 1'b0;               // Stop enqueueing if full
//     //             $display("FIFO is full.");
//     //         end
//     //     end
//     //     @(posedge clk);
//     //     enqueue <= 1'b0; // Stop pushing

//     //     // Dequeue elements until empty
//     //     $display("Starting FIFO Dequeue...");
//     //     for (int i = 0; i < QUEUE_DEPTH; i++) begin
//     //         @(posedge clk);
//     //         $display("Dsiplaying the tags full = ", full," Empty = ", empty);
//     //         if (!empty) begin
//     //             dequeue <= 1'b1;
//     //             @(posedge clk);   // To capture correct rdata after the dequeue
//     //             $display("Dequeuing: %0d", rdata);
//     //         end else begin
//     //             dequeue <= 1'b0;               // Stop dequeuing if empty
//     //             $display("FIFO is empty.");
//     //         end
//     //     end
//     //     @(posedge clk);
//     //     dequeue <= 1'b0; // Stop popping

//     //     // Check if FIFO is empty at the end
//     //     if (empty) begin
//     //         $display("Test Passed: FIFO is empty after all pops.");
//     //     end else begin
//     //         $error("Test Failed: FIFO is not empty.");
//     //     end
//     // endtask

//     // Monitor block to detect timeout or errors
//     always @(posedge clk) begin
//         if (timeout == 0) begin
//             $error("TB Error: Timed out");
//             $finish;
//         end
//         timeout <= timeout - 1;
//     end


// endmodule
