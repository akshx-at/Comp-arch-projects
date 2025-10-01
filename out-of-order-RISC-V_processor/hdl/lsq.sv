module LSQ 
import rv32i_types::*;
#(
    parameter QUEUE_DEPTH_LSQ = 5,       // No. of LSQ Entry
    parameter QUEUE_DEPTH_ROB = 16
)
(
    input logic clk,
    input logic rst,

    input logic enqueue, // this is the signal when we want to enqueue, this will come from resp/load, which will get updated

    // To Rename/Dispatch
    output logic full,                  
    output logic empty,                  

    // From Rename/Dispatch
    input lsq_t wdata_LSQ,
    
    //To Reservation Station
    output logic    [2:0]   LSQ_idx,

    // From adder_address
    input logic [31:0] output_addr_val,
    input logic lsq_wfe,
    input logic [31:0] ps2_val_from_adder,
    input logic [31:0] ps1_val_from_adder,
    input logic [2:0] lsq_entry_res,

    // From ROB -> the head to initate cache interactions for stores
    // input rob_t head_val_from_rob, 
    input logic [$clog2(QUEUE_DEPTH_ROB)-1:0] head_idx_from_rob,

    // RVFI Stuff
    output rvfi_t rvfi_ls_fu,

    //To send stuff to the data cache
    output   logic   [31:0]  dfp_addr, // also goes to PCSB
    output   logic   [3:0]   dfp_rmask, // also goes to PCSB
    // output   logic   [3:0]   dfp_wmask_to_pcsb,
    // output   logic   [31:0]  dfp_wdata_to_pcsb,
    input    logic           dfp_resp,  
    input    logic   [31:0]  dfp_rdata,

    //output CDB
    output cdb_t cdb_output_ls,


    // To PCSB
    // output logic [31:0] lsq_addr_store_buf, 
    // output logic [3:0]  lsq_rmask_store_buf,

    output logic        store_buffer_commit,

    // output lsq_t        lsq_entry_head,
    // output logic        empty_pcsb,

    output   logic   [3:0]   dfp_wmask_to_pcsb,
    output   logic   [31:0]  dfp_wdata_to_pcsb,  

    // From store_buffer
    // input  logic   [31:0]  forward_addr_load,
    // input  logic           forward_resp_load,
    // input  logic   [31:0]  forward_rdata_load,
    input  logic           full_pcsb,

    input logic flush
);

    localparam DEPTH_WIDTH_LSQ = $clog2(QUEUE_DEPTH_LSQ);
    localparam REM_ZEROS = 32 - DEPTH_WIDTH_LSQ;
    // Internal signalsQ
    // logic [DATA_WIDTH_LSQ-1:0] queue [QUEUE_DEPTH_LSQ-1:0];                 // Queue storage
    lsq_t queue [QUEUE_DEPTH_LSQ-1:0];                 // Queue storage
    logic [DEPTH_WIDTH_LSQ-1:0] head, tail, head_next, tail_next;       // Head and Tail pointers
    logic overflow_bit;                                             // Extra bit to track when tail laps head

    // logic [DATA_WIDTH_LSQ-1:0] wdata_LSQ; 
    // lsq_t wdata_LSQ; 
    
    logic dequeue;                             // Actual Data inside the LSQ array

    lsq_t lsq_entry_head;
    lsq_t lsq_entry_head_for_mem;

    // logic  [3:0]  dfp_wmask_to_pcsb;
    // logic  [31:0] dfp_wdata_to_pcsb;
    logic [31:0] rd_v;
    // logic invalid_dfp_flush;

    // post_commit_store_buffer
    // logic [31:0]    addr_val_load;
    // logic [31:0]    rdata_val_load;

    // Full and Empty logic
    assign empty = (head == tail) && !overflow_bit;                 // Empty when head == tail and no overflow
    assign full = (head == tail) && overflow_bit;                   // Full when head == tail and overflow

    assign LSQ_idx = tail;

    // dequeue when lsq_commit at head is 1
    // assign dequeue = queue[head][DATA_WIDTH_LSQ - 1] && !empty ? 1'b1 : 1'b0;
    // assign dequeue = (queue[head].lsq_commit && !empty && !invalid_dfp_flush && (dfp_resp || store_buffer_commit)) ? 1'b1 : 1'b0;
    assign dequeue = (queue[head].lsq_commit && !empty && (dfp_resp || store_buffer_commit)) ? 1'b1 : 1'b0;

    assign lsq_entry_head = queue[head];

    assign lsq_entry_head_for_mem = dfp_resp ? queue[head_next] : queue[head];

    // PCSB
    // assign lsq_addr_store_buf = lsq_entry_head.address_lsq;
    // assign lsq_rmask_store_buf = dfp_rmask;
    // assign addr_val_load = forward_resp_load ? forward_addr_load : lsq_entry_head.address_lsq;
    // assign rdata_val_load = forward_resp_load ? forward_rdata_load : dfp_rdata;
    // assign empty_pcsb = empty;

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
                tail_next = DEPTH_WIDTH_LSQ'(({REM_ZEROS'(0),tail} + 1) % QUEUE_DEPTH_LSQ);  // Move tail forward
            end 
        
            // Only dequeue (pop)
            if (dequeue && !empty) begin
                head_next = DEPTH_WIDTH_LSQ'(({REM_ZEROS'(0),head} + 1) % QUEUE_DEPTH_LSQ);  // Move head forward
            end
        end        
    end 

    //output to RRF logic
    // always_comb begin
    //     if (dequeue && !empty && dfp_resp) begin
    //         // pd = queue[head][5:0];
    //         // rd = queue[head][10:6];
    //         pd = queue[head].pd_lsq;
    //         // rd = queue[head].rd_LSQ;
    //         commit_inst = 1'b1;
    //     end
    //     else begin
    //         pd = 'x;
    //         rd = 'x;
    //         commit_inst = 1'b0;
    //     end
    // end

    // Enqueue and Dequeue logic
    always_ff @(posedge clk) begin
        if (rst || flush) begin
            // Reset logic
            head <= '0;
            tail <= '0;
            overflow_bit <= 1'b0;
            // queue[head].lsq_commit <= 1'b0;

            for(int i = 0; i < QUEUE_DEPTH_LSQ; i++) begin
                queue[i].lsq_commit <= 1'b0;
            end
        end else begin
            // Only enqueue (push)
            if (enqueue && !full) begin
                queue[tail] <= wdata_LSQ;
                // LSQ_idx <= tail;
                // tail <= DEPTH_WIDTH'((tail + 1) % QUEUE_DEPTH);  // Move tail forward
                tail <= tail_next;
                if (tail_next == head_next)                  // If tail laps head
                    overflow_bit <= 1'b1;          // Set overflow bit
            end 
            
            // Only dequeue (pop) // change lsq_commit here to data[head].lsq_commit
            if (dequeue && !empty) begin
                // rdata <= queue[head];
                // head <= DEPTH_WIDTH'((head + 1) % QUEUE_DEPTH);  // Move head forward
                queue[head].lsq_commit <= 1'b0;
                head <= head_next;
                if (head_next == tail_next)                  // If head catches up to tail
                    overflow_bit <= 1'b0;          // Clear overflow bit
            end

            if (lsq_wfe) begin
                queue[lsq_entry_res].lsq_commit <= 1'b1; 
                queue[lsq_entry_res].address_lsq <= output_addr_val;
                // queue[lsq_entry_res].rvfi_packet <= rvfi_ls_fu;    
                queue[lsq_entry_res].ps2_val_to_lsq <= ps2_val_from_adder;
                queue[lsq_entry_res].ps1_val_to_lsq <= ps1_val_from_adder;    
            end            
        end
    end

    always_comb begin
        dfp_wmask_to_pcsb = '0;
        dfp_rmask = '0;
        dfp_wdata_to_pcsb = '0;
        store_buffer_commit = 1'b0;
        dfp_addr = {lsq_entry_head.address_lsq[31:2], 2'b00}; // we will send these value to cache 
        if(lsq_entry_head.lsq_commit && !dfp_resp) begin
            case(lsq_entry_head.rvfi_packet.inst[6:0])
                op_b_load: begin
                    unique case(lsq_entry_head.rvfi_packet.inst[14:12])   
                    load_f3_lb, load_f3_lbu: dfp_rmask = 4'b0001 << lsq_entry_head.address_lsq[1:0];
                    load_f3_lh, load_f3_lhu: dfp_rmask = 4'b0011 << lsq_entry_head.address_lsq[1:0];
                    load_f3_lw             : dfp_rmask = 4'b1111;
                    default : begin
                        dfp_rmask = '0;
                        dfp_wmask_to_pcsb = '0;
                        dfp_wdata_to_pcsb = '0;
                        store_buffer_commit = 1'b0;
                    end
                    endcase
                end
                op_b_store: begin
                    // for store we only set and send these values to ethe next stage once the head of the rob is equal to the rob
                    if(lsq_entry_head.rob_entry_res == head_idx_from_rob) begin
                        store_buffer_commit = full_pcsb ? 1'b0 : 1'b1;
                        unique case(lsq_entry_head.rvfi_packet.inst[14:12])
                            store_f3_sb: begin 
                                dfp_wmask_to_pcsb = 4'b0001 << lsq_entry_head.address_lsq[1:0];
                                dfp_wdata_to_pcsb[8 *lsq_entry_head.address_lsq[1:0] +: 8 ] = lsq_entry_head.ps2_val_to_lsq[7 :0]; // Need to change the rs2_v for all stores 
                            end
                            store_f3_sh: begin 
                                dfp_wmask_to_pcsb = 4'b0011 << lsq_entry_head.address_lsq[1:0];
                                dfp_wdata_to_pcsb[16*lsq_entry_head.address_lsq[1]   +: 16] = lsq_entry_head.ps2_val_to_lsq[15:0];
                            end
                            store_f3_sw: begin
                                dfp_wmask_to_pcsb = 4'b1111;
                                dfp_wdata_to_pcsb = lsq_entry_head.ps2_val_to_lsq;
                            end
                            default : begin
                                dfp_rmask = '0;
                                dfp_wmask_to_pcsb = '0;
                                dfp_wdata_to_pcsb = '0;
                                store_buffer_commit = 1'b0;
                            end
                        endcase
                    end
                end
            endcase
        end
    end

    always_comb begin
        rd_v = 'x;
        if (dfp_resp) begin
            if (lsq_entry_head.rvfi_packet.inst[6:0] == op_b_load) begin
                unique case (lsq_entry_head.rvfi_packet.inst[14:12])
                    load_f3_lb : rd_v = {{24{dfp_rdata[7 +8 *lsq_entry_head.address_lsq[1:0]]}}, dfp_rdata[8 *lsq_entry_head.address_lsq[1:0] +: 8 ]};
                    load_f3_lbu: rd_v = {{24{1'b0}}                          , dfp_rdata[8 *lsq_entry_head.address_lsq[1:0] +: 8 ]};
                    load_f3_lh : rd_v = {{16{dfp_rdata[15+16*lsq_entry_head.address_lsq[1]  ]}}, dfp_rdata[16*lsq_entry_head.address_lsq[1]   +: 16]};
                    load_f3_lhu: rd_v = {{16{1'b0}}                          , dfp_rdata[16*lsq_entry_head.address_lsq[1]   +: 16]};
                    load_f3_lw : rd_v = dfp_rdata;
                    default    : rd_v = 'x;
                endcase   
            end
        end 
    end    

    // // Edge case load flushing
    // always_ff @(posedge clk) begin
    //     if (rst) begin
    //         invalid_dfp_flush <= 1'b0;
    //     end else if (flush && !dfp_resp && lsq_entry_head.lsq_commit && (dfp_rmask != '0)) begin
    //         invalid_dfp_flush <= 1'b1;
    //     end else if (dfp_resp && invalid_dfp_flush) begin
    //         invalid_dfp_flush <= 1'b0;
    //     end
    // end

    // This logic will also need to change because of pcsb

    always_ff @(posedge clk) begin
        if(rst || flush) begin
            cdb_output_ls <= '0;
            rvfi_ls_fu <= '0;
            cdb_output_ls.address_br <= 'x;
        end
        else if (dfp_rmask != '0) begin
            rvfi_ls_fu.mem_addr <= dfp_addr;
            rvfi_ls_fu.mem_rmask <= dfp_rmask;
            rvfi_ls_fu.mem_wmask <= dfp_wmask_to_pcsb;
            // rvfi_ls_fu.mem_rdata <= dfp_rdata;
            rvfi_ls_fu.mem_wdata <= dfp_wdata_to_pcsb;
            cdb_output_ls.regf_we <= 1'b0;
        end
        // else if ((dfp_resp && !invalid_dfp_flush)) begin
        else if (dfp_resp) begin
            cdb_output_ls.rob_entry_res <= lsq_entry_head.rob_entry_res;
            cdb_output_ls.phys_reg <= lsq_entry_head.pd_lsq;
            cdb_output_ls.arch_reg <= lsq_entry_head.rd_lsq;
            // cdb_output_ls.result <= dfp_rdata;
            cdb_output_ls.result <= rd_v;
            cdb_output_ls.regf_we <= 1'b1; // we dont want to write back to the register if it is a store 
            
            // RVFI
            // This will come in from rename dispatch
            rvfi_ls_fu.inst  <= lsq_entry_head.rvfi_packet.inst;
            rvfi_ls_fu.pc    <=    lsq_entry_head.rvfi_packet.pc;
            rvfi_ls_fu.pc_next <= lsq_entry_head.rvfi_packet.pc + 'd4;
            rvfi_ls_fu.rs1_s <= lsq_entry_head.rvfi_packet.rs1_s;
            rvfi_ls_fu.rs2_s <= lsq_entry_head.rvfi_packet.rs2_s;
            rvfi_ls_fu.rd_s  <=  lsq_entry_head.rvfi_packet.rd_s;
            rvfi_ls_fu.order <= lsq_entry_head.rvfi_packet.order;

            rvfi_ls_fu.rs1_rdata <= lsq_entry_head.ps1_val_to_lsq;
            rvfi_ls_fu.rs2_rdata <= lsq_entry_head.ps2_val_to_lsq;
            rvfi_ls_fu.rd_wdata <= rd_v;

            // rvfi_ls_fu.mem_addr <= dfp_addr;
            // rvfi_ls_fu.mem_rmask <= dfp_rmask;
            // rvfi_ls_fu.mem_wmask <= dfp_wmask_to_pcsb;
            rvfi_ls_fu.mem_rdata <= dfp_rdata;
            // rvfi_ls_fu.mem_wdata <= dfp_wdata_to_pcsb;            
        end 
        else if (store_buffer_commit) begin
            rvfi_ls_fu.mem_addr <= dfp_addr;
            rvfi_ls_fu.mem_rmask <= dfp_rmask;
            rvfi_ls_fu.mem_wmask <= dfp_wmask_to_pcsb;
            rvfi_ls_fu.mem_wdata <= dfp_wdata_to_pcsb;
            // cdb_output_ls.regf_we <= 1'b0;

            cdb_output_ls.rob_entry_res <= lsq_entry_head.rob_entry_res;
            cdb_output_ls.phys_reg <= lsq_entry_head.pd_lsq;
            cdb_output_ls.arch_reg <= lsq_entry_head.rd_lsq;
            cdb_output_ls.result <= rd_v;
            cdb_output_ls.regf_we <= 1'b1; // we dont want to write back to the register if it is a store 
            
            // RVFI
            // This will come in from rename dispatch
            rvfi_ls_fu.inst  <= lsq_entry_head.rvfi_packet.inst;
            rvfi_ls_fu.pc    <=    lsq_entry_head.rvfi_packet.pc;
            rvfi_ls_fu.pc_next <= lsq_entry_head.rvfi_packet.pc + 'd4;
            rvfi_ls_fu.rs1_s <= lsq_entry_head.rvfi_packet.rs1_s;
            rvfi_ls_fu.rs2_s <= lsq_entry_head.rvfi_packet.rs2_s;
            rvfi_ls_fu.rd_s  <=  lsq_entry_head.rvfi_packet.rd_s;
            rvfi_ls_fu.order <= lsq_entry_head.rvfi_packet.order;

            rvfi_ls_fu.rs1_rdata <= lsq_entry_head.ps1_val_to_lsq;
            rvfi_ls_fu.rs2_rdata <= lsq_entry_head.ps2_val_to_lsq;
            rvfi_ls_fu.rd_wdata <= rd_v;
            rvfi_ls_fu.mem_rdata <= 'x;
        end
        else begin
            cdb_output_ls.regf_we <= 1'b0;
        end
    end

endmodule : LSQ
