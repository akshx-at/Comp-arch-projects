module ROB 
import rv32i_types::*;
#(
    parameter DATA_WIDTH_ROB = 12+136,      // width of ROB entry
    parameter QUEUE_DEPTH_ROB = 16       // No. of ROB Entry
)
(
    input logic clk,
    input logic rst,

    input logic enqueue,

    // To Rename/Dispatch
    output logic full,                  
    output logic empty,                  

    // From Rename/Dispatch
    input logic rob_commit,
    input logic [4:0]   rd_rob,
    input logic [5:0]   pd_rob,
    input logic [31:0] order, pc,

    input logic [6:0] opcode_b_pred,
    input predictor_t branch_pred,
    input predictor_gshare_t branch_pred_gshare,
    input tournament_t tournament_pred,

    //To Reservation Station
    output logic    [$clog2(QUEUE_DEPTH_ROB)-1:0]   rob_idx,

    // From CDB
    input cdb_t cdb_in_add, cdb_in_mul, cdb_in_div,cdb_in_ls,

    // TO RRF
    output logic [4:0]   rd,
    output logic [5:0]   pd,
    output logic commit_inst,

    // RVFI Stuff
    input rvfi_t rvfi_add_fu, rvfi_mul_fu, rvfi_div_fu, rvfi_ls_fu,
    output rob_t rob_entry_at_head,

    // To LSQ
    output logic [$clog2(QUEUE_DEPTH_ROB)-1:0] head_idx,

    // For flushing due to misprediction (branch_not_taken)
    output logic    flush_out,
    output logic [31:0] order_br, pc_br,

    // output logic [4:0] rd_rob_head,
    // output logic [5:0] pd_rob_head

    // To arbiter
    // input logic wresp_gshare,
    input logic wresp,
    output logic write_branch_pred,
    output predictor_t wdata_branch_pred,
    output tournament_t wdata_tournament,

    output predictor_gshare_t wdata_branch_pred_gshare


);

    localparam  DEPTH_WIDTH_ROB = $clog2(QUEUE_DEPTH_ROB);
    localparam REM_ZEROS = 32 - DEPTH_WIDTH_ROB;
    // Internal signals
    // logic [DATA_WIDTH_ROB-1:0] queue [QUEUE_DEPTH_ROB-1:0];                 // Queue storage
    rob_t queue [QUEUE_DEPTH_ROB-1:0];                 // Queue storage
    logic [DEPTH_WIDTH_ROB-1:0] head, tail, head_next, tail_next;       // Head and Tail pointers
    logic overflow_bit;                                             // Extra bit to track when tail laps head

    // logic [DATA_WIDTH_ROB-1:0] wdata_rob; 
    rob_t wdata_rob; 
    
    logic dequeue;                             // Actual Data inside the ROB array

    // Full and Empty logic
    assign empty = (head == tail) && !overflow_bit;                 // Empty when head == tail and no overflow
    assign full = (head == tail) && overflow_bit;                   // Full when head == tail and overflow

    // assign wdata_rob = {'0,rob_commit, rd_rob, pd_rob};
    assign wdata_rob.rvfi_packet = '0;
    assign wdata_rob.rob_commit = rob_commit;
    assign wdata_rob.rd_rob = rd_rob;
    assign wdata_rob.pd_rob = pd_rob;
    assign wdata_rob.flush_rob = 1'b0;
    assign wdata_rob.order_br = order;
    assign wdata_rob.pc_br = pc;

    assign wdata_rob.opcode_b_pred = opcode_b_pred;
    assign wdata_rob.branch_pred = branch_pred;
    assign wdata_rob.tournament_pred = tournament_pred;
    assign wdata_rob.branch_pred_gshare = branch_pred_gshare;

    assign rob_idx = tail;
    assign head_idx = head;

    // dequeue when rob_commit at head is 1
    // assign dequeue = queue[head][DATA_WIDTH_ROB - 1] && !empty ? 1'b1 : 1'b0;
    // assign dequeue = queue[head].rob_commit && !empty ? 1'b1 : 1'b0;

    assign wdata_branch_pred = queue[head].branch_pred;
    assign wdata_branch_pred_gshare = queue[head].branch_pred_gshare;
    assign wdata_tournament = queue[head].tournament_pred;

    always_comb begin
        write_branch_pred = 1'b0;
        dequeue = 1'b0;
        if (queue[head].rob_commit && !empty) begin
            if(queue[head].opcode_b_pred == op_b_br) begin
                write_branch_pred = 1'b1;
                dequeue = wresp ? 1'b1 : 1'b0;
            end else begin
                dequeue = 1'b1;
            end
        end
    end

    assign rob_entry_at_head = queue[head];
    // assign rd_rob_head = rob_entry_at_head.rd_rob;
    // assign pd_rob_head = rob_entry_at_head.pd_rob;

    assign order_br = rob_entry_at_head.order_br;
    assign pc_br = rob_entry_at_head.pc_br;

    assign flush_out = rob_entry_at_head.flush_rob && rob_entry_at_head.rob_commit && dequeue;

    // head_next and tail_next logic
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
                tail_next = DEPTH_WIDTH_ROB'(({REM_ZEROS'(0),tail} + 1) % QUEUE_DEPTH_ROB);  // Move tail forward
            end 
            
            // Only dequeue (pop)
            if (dequeue && !empty) begin
                head_next = DEPTH_WIDTH_ROB'(({REM_ZEROS'(0),head} + 1) % QUEUE_DEPTH_ROB);  // Move head forward
            end
        end        
    end 

    //output to RRF logic
    always_comb begin
        if (dequeue && !empty) begin
            // pd = queue[head][5:0];
            // rd = queue[head][10:6];
            pd = queue[head].pd_rob;
            rd = queue[head].rd_rob;
            commit_inst = 1'b1;
        end
        else begin
            pd = 'x;
            rd = 'x;
            commit_inst = 1'b0;
        end
    end

    // Enqueue and Dequeue logic
    always_ff @(posedge clk) begin
        if (rst || flush_out) begin
            // Reset logic
            head <= '0;
            tail <= '0;
            overflow_bit <= 1'b0;
            // queue[head].rob_commit <= 1'b0;

            for (int i = 0; i < QUEUE_DEPTH_ROB; i++) begin
                queue[i].rob_commit <= 1'b0;
                queue[i].flush_rob <= 1'b0;
            end
        end else begin
            // Only enqueue (push)
            if (enqueue && !full) begin
                queue[tail] <= wdata_rob;
                // rob_idx <= tail;
                // tail <= DEPTH_WIDTH'((tail + 1) % QUEUE_DEPTH);  // Move tail forward
                tail <= tail_next;
                if (tail_next == head_next)                  // If tail laps head
                    overflow_bit <= 1'b1;          // Set overflow bit
            end 
            
            // Only dequeue (pop) // change rob_commit here to data[head].rob_commit
            if (dequeue && !empty) begin
                // rdata <= queue[head];
                // head <= DEPTH_WIDTH'((head + 1) % QUEUE_DEPTH);  // Move head forward
                queue[head].rob_commit <= 1'b0;
                head <= head_next;
                if (head_next == tail_next)                  // If head catches up to tail
                    overflow_bit <= 1'b0;          // Clear overflow bit
            end

            if (cdb_in_add.regf_we) begin
                // queue[cdb_in_add.rob_entry_res][11] <= 1'b1; 
                // queue[cdb_in_add.rob_entry_res][147:12] <= rvfi_add_fu;
                queue[cdb_in_add.rob_entry_res].rob_commit <= 1'b1; 
                queue[cdb_in_add.rob_entry_res].rvfi_packet <= rvfi_add_fu;         
                queue[cdb_in_add.rob_entry_res].flush_rob <= cdb_in_add.flush_rob; 
                if (queue[cdb_in_add.rob_entry_res].opcode_b_pred == op_b_br) begin
                    // queue[cdb_in_add.rob_entry_res].tournament_pred =
                    case (queue[cdb_in_add.rob_entry_res].branch_pred.b_counter)
                        2'b00: queue[cdb_in_add.rob_entry_res].branch_pred.b_counter <= cdb_in_add.flush_rob ? 2'b01 : 2'b00;
                        2'b01: queue[cdb_in_add.rob_entry_res].branch_pred.b_counter <= cdb_in_add.flush_rob ? 2'b10 : 2'b00;
                        2'b10: queue[cdb_in_add.rob_entry_res].branch_pred.b_counter <= cdb_in_add.flush_rob ? 2'b01 : 2'b11;
                        2'b11: queue[cdb_in_add.rob_entry_res].branch_pred.b_counter <= cdb_in_add.flush_rob ? 2'b10 : 2'b11;
                    endcase

                    case (queue[cdb_in_add.rob_entry_res].branch_pred_gshare.b_counter_gshare)
                        2'b00: queue[cdb_in_add.rob_entry_res].branch_pred_gshare.b_counter_gshare <= cdb_in_add.flush_rob ? 2'b01 : 2'b00;
                        2'b01: queue[cdb_in_add.rob_entry_res].branch_pred_gshare.b_counter_gshare <= cdb_in_add.flush_rob ? 2'b10 : 2'b00;
                        2'b10: queue[cdb_in_add.rob_entry_res].branch_pred_gshare.b_counter_gshare <= cdb_in_add.flush_rob ? 2'b01 : 2'b11;
                        2'b11: queue[cdb_in_add.rob_entry_res].branch_pred_gshare.b_counter_gshare <= cdb_in_add.flush_rob ? 2'b10 : 2'b11;
                    endcase                    
                end

                queue[cdb_in_add.rob_entry_res].pc_br <= cdb_in_add.address_br;    
            end

            if (cdb_in_mul.regf_we) begin
                // queue[cdb_in_mul.rob_entry_res][11] <= 1'b1; 
                // queue[cdb_in_mul.rob_entry_res][147:12] <= rvfi_mul_fu;
                queue[cdb_in_mul.rob_entry_res].rob_commit <= 1'b1; 
                queue[cdb_in_mul.rob_entry_res].rvfi_packet <= rvfi_mul_fu;                 
            end

            if (cdb_in_div.regf_we) begin
                // queue[cdb_in_div.rob_entry_res][11] <= 1'b1; 
                // queue[cdb_in_div.rob_entry_res][147:12] <= rvfi_div_fu;
                queue[cdb_in_div.rob_entry_res].rob_commit <= 1'b1; 
                queue[cdb_in_div.rob_entry_res].rvfi_packet <= rvfi_div_fu;                 
            end

            if (cdb_in_ls.regf_we) begin
                // queue[cdb_in_div.rob_entry_res][11] <= 1'b1; 
                // queue[cdb_in_div.rob_entry_res][147:12] <= rvfi_div_fu;
                queue[cdb_in_ls.rob_entry_res].rob_commit <= 1'b1; 
                queue[cdb_in_ls.rob_entry_res].rvfi_packet <= rvfi_ls_fu;                 
            end               

        end
    end

endmodule : ROB
