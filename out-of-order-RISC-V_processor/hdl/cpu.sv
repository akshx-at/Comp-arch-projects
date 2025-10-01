module cpu
import rv32i_types::*;
(
    input   logic               clk,
    input   logic               rst,

    output  logic   [31:0]      bmem_addr,
    output  logic               bmem_read,
    output  logic               bmem_write,
    output  logic   [63:0]      bmem_wdata,
    input   logic               bmem_ready,

    input   logic   [31:0]      bmem_raddr,
    input   logic   [63:0]      bmem_rdata,
    input   logic               bmem_rvalid

    // output logic flush_mon
);

    logic [31:0] imem_addr;
    logic imem_resp;
    logic [3:0] imem_rmask;
    logic [31:0] instruction, pc, pc_next;

    logic [31:0] i_cache_line_addr;
    logic i_cache_line_read;
    logic i_cache_line_write;
    logic i_cache_line_resp;

    logic [255:0] i_cache_line_rdata;
    logic [255:0] i_cache_line_wdata;

    logic [31:0] d_cache_line_addr;
    logic d_cache_line_read;
    logic d_cache_line_write;
    logic d_cache_line_resp;

    logic [255:0] d_cache_line_rdata;
    logic [255:0] d_cache_line_wdata;

    logic [31:0] arb_cache_line_addr;
    logic arb_cache_line_read;
    logic arb_cache_line_write;
    logic arb_cache_line_resp;

    logic [255:0] arb_cache_line_rdata;
    logic [255:0] arb_cache_line_wdata;

    logic [31:0] dfp_addr_data;

    logic [3:0] dfp_rmask_data, dfp_wmask_data;
    logic dfp_resp_data;
    logic [31:0] dfp_rdata_data;
    logic [31:0] dfp_wdata_data;

    // Parameters
    parameter DATA_WIDTH = 64;
    parameter QUEUE_DEPTH = 16; 

    parameter DATA_WIDTH_FL = 6;
    parameter QUEUE_DEPTH_FL = 32;

    parameter DATA_WIDTH_ROB = 12;
    parameter QUEUE_DEPTH_ROB = 16;

    parameter RES_ADD_ENTRIES = 5;
    parameter RES_DIV_ENTRIES = 5;
    parameter RES_MUL_ENTRIES = 5;
    parameter RES_LS_ENTRIES = 5;

    parameter QUEUE_DEPTH_LSQ = 5;

    parameter LHT_LENGTH = 6;
    parameter PHT_LENGTH = 11;

    parameter GHR_LENGTH = 6;
    parameter COUNTER_WIDTH = 2;
    parameter CHOOSER_PHT_SIZE = 64;

    parameter NUM_LINES = 1;
    parameter BUFFER_DEPTH = 4;

    // Inst FIFO
    // logic [DATA_WIDTH-1:0] rdata;
    instr_fifo_t rdata;
    // logic [(DATA_WIDTH) - 1 : 0] enqueue_wdata;
    instr_fifo_t enqueue_wdata;
    logic enqueue, dequeue, full, empty;
    
    // Freelist FIFO
    logic enqueue_fl, dequeue_fl, full_fl, empty_fl;
    logic [(DATA_WIDTH_FL) - 1: 0] enqueue_wdata_fl;
    logic [DATA_WIDTH_FL-1:0] rdata_fl;
    // logic [4:0] rd_fl; 

    // LSQ
    logic enqueue_lsq, full_lsq, empty_lsq;
    lsq_t wdata_LSQ;
    logic [2:0] LSQ_idx_to_ren_disp;

    logic [31:0] ps1_val_to_lsq;

    logic [2:0] lsq_entry_res;
    logic [$clog2(QUEUE_DEPTH_ROB)-1:0] head_idx_from_rob;

    // ROB
    logic [$clog2(QUEUE_DEPTH_ROB)-1:0] rob_idx;
    logic full_rob, empty_rob, enqueue_rob;
    logic [4:0] rd_rob_head;
    logic [5:0] pd_rob_head;

    logic [6:0] opcode_b_pred;

    // Rename/Dispatch
    id_ex_stage_reg_t id_ex_reg_next;

    logic [4:0] rd;
    logic [5:0] pd;
    logic regf_we;
    logic [4:0] rs1;
    logic [4:0] rs2;

    logic [4:0] rd_rob;
    logic [5:0] pd_rob;
    logic ready_commit_rob;

    reservation_station_t res_entry;
    reservation_station_ls_t res_entry_ls;

    logic ps1_valid, ps2_valid;
    logic [5:0] ps1, ps2;

    logic stall;

    // Res Station
    logic rs_add_full, rs_mul_full, rs_div_full, rs_ls_full;
    logic regf_we_rs_add, regf_we_rs_mul, regf_we_rs_div, regf_we_rs_ls;

    id_ex_stage_reg_t decode_packet_from_add, decode_packet_from_mul, decode_packet_from_div, decode_packet_from_ls;

    logic activate_add, activate_mul, activate_div, activate_ls;

    logic [$clog2(QUEUE_DEPTH_ROB)-1:0] rob_entry_from_add_rs, rob_entry_from_mul_rs, rob_entry_from_div_rs, rob_entry_from_ls_rs;
    logic [5:0] pd_from_add_rs, pd_from_mul_rs, pd_from_div_rs, pd_from_ls_rs;

    logic [5:0] ps1_add_tosend_tophyreg, ps2_add_tosend_tophyreg;
    logic [5:0] ps1_mul_tosend_tophyreg, ps2_mul_tosend_tophyreg;
    logic [5:0] ps1_div_tosend_tophyreg, ps2_div_tosend_tophyreg;
    logic [5:0] ps1_ls_tosend_tophyreg, ps2_ls_tosend_tophyreg;

    predictor_t branch_pred;
    predictor_gshare_t branch_pred_gshare;

    // RRF
    logic [4:0] rd_rrf;
    logic [5:0] pd_rrf;
    logic commit_inst_rrf;
    logic delay_flush;

    // LSQ
    logic [2:0] lsq_entry_from_rs;
    logic [31:0] output_addr_val_to_lsq;
    logic lsq_wfe_to_lsq;
    logic [31:0] ps2_val_to_lsq;

    // CDB
    // cdb_t cdb_data;
    cdb_t cdb_data_add, cdb_data_mul, cdb_data_div, cdb_data_ls;

    // Register File
    logic [31:0] ps1_executeval_add, ps2_executeval_add, ps1_executeval_mul, ps2_executeval_mul, ps1_executeval_div, ps2_executeval_div;
    logic [31:0] ps1_executeval_ls, ps2_executeval_ls;

    // Functional units
    logic [1:0] counter_mul;
    logic [2:0] counter_div;

    // RVFI
    rvfi_t rvfi_add_fu, rvfi_mul_fu, rvfi_div_fu, rvfi_ls_fu;
    rob_t rob_entry_at_head;


    logic invalid_dfp_flush, flush;
    logic [5:0]  data_flush [32];

    logic [31:0] order_br, pc_br, order_to_ROB, pc_to_ROB;

    //2 bit branch predictor - LHT
    logic read_b_prediction;
    logic prediction_resp;
    predictor_t prediction; 
    tournament_t prediction_tournament, wdata_tournament, tournament_predictor;
    logic lht_web;
    logic [LHT_LENGTH-1 : 0] lht_index;
    logic [PHT_LENGTH-1 : 0] write_lht_history;
    logic [PHT_LENGTH-1 : 0] lht_history;

    //2 bit branch predictor - PHT
    // logic read_b_prediction;
    logic pht_web;
    logic [PHT_LENGTH-1 : 0] pht_index;
    logic [1 : 0] write_pht_counter;
    logic [1 : 0] pht_history;
    logic [1:0] pht_counter;

    // Valid LHT
    logic valid_lht;
    logic write_valid_lht;

    // Valid PHT
    logic valid_pht;
    logic write_valid_pht;

    // Fetch
    logic stall_iq_pred;

    logic write_branch_pred;
    predictor_t wdata_branch_pred;
    logic wresp;

    // PCSB
    logic   [3:0]   lsq_wmask;
    logic   [3:0]   lsq_rmask;
    logic   [31:0]  lsq_wdata;
    logic   [31:0]  lsq_addr;

    lsq_t lsq_entry_head;

    logic full_pcsb, empty_pcsb, dequeue_pcsb, store_buffer_commit;

    logic   [31:0]  dfp_addr_data_pcsb;

    // logic   [31:0]  lsq_addr_store_buf;
    // logic   [3:0]   lsq_rmask_store_buf;
    logic   [31:0]  forward_addr_load, forward_rdata_load; 
    logic           forward_resp_load;

    // RAS
    parameter RAS_DEPTH = 8;
    logic push_en, pop_en;
    logic [31:0] push_addr, top_addr; 

    // assign flush_mon = flush;
    logic wresp_gshare;

    logic prediction_resp_gshare;

    predictor_gshare_t wdata_branch_pred_gshare;
    predictor_gshare_t prediction_gshare;

    logic pht_web_gshare;
    logic [GHR_LENGTH-1 : 0] pht_index_gshare;
    logic [1 : 0] wdata_pht_counter_gshare;
    logic [1:0] pht_counter_gshare;

    logic valid_pht_gshare;
    logic write_valid_pht_gshare;

    //tournament

    logic final_prediction_tournament;

    arbiter_pred_t state_2lvl;

    // Edge case load flushing
    always_ff @(posedge clk) begin
        if (rst) begin
            invalid_dfp_flush <= 1'b0;
        end else if (flush && !imem_resp) begin
            invalid_dfp_flush <= 1'b1;
        end else if (imem_resp && invalid_dfp_flush) begin
            invalid_dfp_flush <= 1'b0;
        end
    end

    always_comb begin
        if (!empty && !stall) begin
            dequeue = 1'b1;     // Might need to check for stall
        end else begin
            dequeue = 1'b0;
        end


        if (flush || stall_iq_pred) begin
            enqueue = 1'b0;
            enqueue_wdata = 'x;        
        end
        else if (imem_resp && !full && !invalid_dfp_flush) begin
            enqueue = 1'b1;
            // enqueue_wdata = {pc, instruction};
            enqueue_wdata.pc = pc;
            enqueue_wdata.pc_next = pc_next;
            enqueue_wdata.instruction = instruction;
            enqueue_wdata.branch_pred = prediction;
            enqueue_wdata.branch_pred_gshare = prediction_gshare;
            enqueue_wdata.tournament_pred = prediction_tournament;
        end
        else begin
            enqueue = 1'b0;
            enqueue_wdata = 'x;
        end

    end

    FIFO  #(
        .DATA_WIDTH(DATA_WIDTH),
        .QUEUE_DEPTH(QUEUE_DEPTH)
    ) fifoqueue (
        .clk(clk),
        .rst(rst),
        .wdata(enqueue_wdata),
        .enqueue(enqueue),
        .rdata(rdata),
        .dequeue(dequeue),
        .full(full),
        .empty(empty),
        .flush(flush)
    );
    
    fetch fetch_stage(
        .clk    (clk),
        .rst    (rst),
        .full   (full),
        .pc     (pc),
        .inst   (instruction),
        .pc_next (pc_next),

        .imem_addr  (imem_addr),
        .imem_resp  (imem_resp),
        .imem_rmask (imem_rmask),
        .pc_br(pc_br),
        .flush(flush),

        .read_b_prediction(read_b_prediction),
        .prediction_resp(prediction_resp),
        .prediction(prediction),
        // .stall_iq_pred(stall_iq_pred),

        .push_en(push_en),
        .pop_en(pop_en),
        .push_addr(push_addr),
        .top_addr(top_addr),
        .stall_iq_pred(stall_iq_pred),
        .prediction_resp_gshare(prediction_resp_gshare),
        .prediction_gshare(prediction_gshare), 
        .prediction_tournament(prediction_tournament)
    );

    RAS #(
        .RAS_DEPTH(RAS_DEPTH)
    ) ras_i (
        .clk(clk),
        .rst(rst),
        .push_en(push_en),
        .pop_en(pop_en),
        .push_addr(push_addr),
        .top_addr(top_addr)
        // .final_prediction(final_prediction_tournament)
    );

    logic [31:0] prefetch_addr;
    logic prefetch_read;
    logic prefetch_write_dummy;
    logic [255:0] prefetch_rdata;
    logic [255:0] prefetch_wdata_dummy;
    logic prefetch_resp;

    cache instr_cache (             // Read only cache because Fetch Inst and PC only
        .clk        (clk),
        .rst        (rst),

        // CPU
        .ufp_addr       (imem_addr),
        .ufp_rmask      (imem_rmask),
        .ufp_wmask      ('0),
        .ufp_rdata      (instruction),
        .ufp_wdata      ('x),
        .ufp_resp       (imem_resp),

        // arbiter -- now to prefetcher
        // .dfp_addr       (i_cache_line_addr),
        // .dfp_read       (i_cache_line_read),
        // .dfp_write      (i_cache_line_write),
        // .dfp_rdata      (i_cache_line_rdata),
        // .dfp_wdata      (i_cache_line_wdata),
        // .dfp_resp       (i_cache_line_resp)   

        .dfp_addr       (prefetch_addr),
        .dfp_read       (prefetch_read),
        .dfp_write      (prefetch_write_dummy),
        .dfp_rdata      (prefetch_rdata),
        .dfp_wdata      (prefetch_wdata_dummy),
        .dfp_resp       (prefetch_resp)  
    );

    logic [31:0] dfp_addr_data_from_pcsb;

    cache data_cache (          // Read/Write Cache because of Load and Stores
        .clk        (clk),
        .rst        (rst),

        // getting and sending information from LSQ
        .ufp_addr       ((dfp_wmask_data != '0) ? dfp_addr_data_from_pcsb : dfp_addr_data),
        .ufp_rmask      (dfp_rmask_data),
        .ufp_wmask      (dfp_wmask_data),
        .ufp_rdata      (dfp_rdata_data),
        .ufp_wdata      (dfp_wdata_data),
        .ufp_resp       (dfp_resp_data),

        // Cache line adapter -> will be sent to arbirator to interact with memory
        .dfp_addr       (d_cache_line_addr),
        .dfp_read       (d_cache_line_read),
        .dfp_write      (d_cache_line_write),
        .dfp_rdata      (d_cache_line_rdata),
        .dfp_wdata      (d_cache_line_wdata),
        .dfp_resp       (d_cache_line_resp)  

    );

    arbiter arbiter_i (
        .clk(clk),
        .rst(rst),
    
    // To and From I-Cache -- now to and from fetcher
        .instruction_dfp_addr(i_cache_line_addr),
        .instruction_dfp_read(i_cache_line_read),
        .instruction_dfp_write(i_cache_line_write),
        .instruction_dfp_wdata(i_cache_line_wdata),
        .instruction_dfp_rdata(i_cache_line_rdata),
        .instruction_dfp_resp(i_cache_line_resp),

    // To and From D-Cache
        .data_dfp_addr(d_cache_line_addr),
        .data_dfp_read(d_cache_line_read),
        .data_dfp_write(d_cache_line_write),
        .data_dfp_wdata(d_cache_line_wdata),
        .data_dfp_rdata(d_cache_line_rdata),
        .data_dfp_resp(d_cache_line_resp),

    // To and From Cache Adapter
        .cacheadapter_dfp_addr(arb_cache_line_addr),
        .cacheadapter_dfp_read(arb_cache_line_read),
        .cacheadapter_dfp_write(arb_cache_line_write),
        .cacheadapter_dfp_wdata(arb_cache_line_wdata),
        .cacheadapter_dfp_rdata(arb_cache_line_rdata),

        .cacheadapter_resp(arb_cache_line_resp)
    );

    logic [3:0] rmask_from_lsq;
    logic lsq_resp;
    logic [31:0] lsq_rdata;
    logic [3:0] dfp_wmask_to_pcsb;
    logic [31:0] dfp_wdata_to_pcsb;
    // logic [31:0] dfp_addr_data_from_pcsb;
    logic load;
    logic resp_from_pcsb;
    logic [31:0] rdata_from_pcsb;
    logic mask_loads;
    logic invalid_dfp_flush_pcsb;
    logic mask_conflict;

    LSQ #(
        .QUEUE_DEPTH_LSQ(QUEUE_DEPTH_LSQ),
        .QUEUE_DEPTH_ROB(QUEUE_DEPTH_ROB)
    )load_store_queue(
        .clk(clk),
        .rst(rst),
        // this is the signal when we want to enqueue, this will come from resp/load, which will get updated
        .enqueue(enqueue_lsq),  // have to set the signal
        
        // To Rename/Dispatch
        .full(full_lsq),                  
        .empty(empty_lsq),                  

        // From Rename/Dispatch
        .wdata_LSQ(wdata_LSQ),
        .LSQ_idx(LSQ_idx_to_ren_disp), // have to add to rs_ls

        // From adder_address -> have to instantiate
        .output_addr_val(output_addr_val_to_lsq),
        .lsq_wfe(lsq_wfe_to_lsq),
        .ps1_val_from_adder(ps1_val_to_lsq),
        .ps2_val_from_adder(ps2_val_to_lsq),

        // From adder_address
        .lsq_entry_res(lsq_entry_res),

        // From ROB -> the head to initate cache interactions for stores
        // .head_val_from_rob(rob_entry_at_head), 
        .head_idx_from_rob(head_idx_from_rob),

        // RVFI Stuff
        .rvfi_ls_fu(rvfi_ls_fu),

        //To send stuff to the data cache
        .dfp_addr (dfp_addr_data),
        .dfp_rmask(rmask_from_lsq),
        // .dfp_wmask(dfp_wmask_data),
        // .dfp_wdata(dfp_wdata_data),

        //recieve from data cache
        .dfp_resp(lsq_resp),  
        .dfp_rdata(lsq_rdata),

        //output CDB
        .cdb_output_ls(cdb_data_ls),

        // Post commit store
        // .lsq_addr_store_buf(lsq_addr_store_buf),
        // .lsq_rmask_store_buf(lsq_rmask_store_buf),
        .store_buffer_commit(store_buffer_commit),

        // .lsq_entry_head(lsq_entry_head),
        // .empty_pcsb(empty_pcsb),

        .dfp_wmask_to_pcsb(dfp_wmask_to_pcsb),
        .dfp_wdata_to_pcsb(dfp_wdata_to_pcsb),

        // .forward_addr_load(forward_addr_load),
        // .forward_resp_load(forward_resp_load),
        // .forward_rdata_load(forward_rdata_load),
        .full_pcsb(full_pcsb),

        .flush(flush)
    );

    arbiter_lsq_loads arbiter_lsq_loads_i (
        .clk(clk),
        .rst(rst),

        // LSQ
        .rmask_from_lsq(rmask_from_lsq),
        .lsq_resp(lsq_resp),
        .lsq_rdata(lsq_rdata),

        // D-Cache
        .mem_resp(dfp_resp_data),
        .rmask_to_dcache(dfp_rmask_data),
        .mem_rdata(dfp_rdata_data),

        // PCSB
        .load(load),
        .rdata_from_pcsb(rdata_from_pcsb),
        .resp_from_pcsb(resp_from_pcsb), 
        .mask_loads(mask_loads),

        .flush(flush),
        .invalid_dfp_flush(invalid_dfp_flush_pcsb),

        .mask_conflict(mask_conflict)
    );

    pcsb #(
        // .DATA_WIDTH(65),
        .BUFFER_DEPTH(BUFFER_DEPTH)
    )pcsb_i(
        .clk(clk), 
        .rst(rst),

        // From LSQ (dfp_data)
        .lsq_addr(dfp_addr_data),           // Non byte aligned addr
        .empty_lsq(empty_lsq),
        .store_buffer_commit(store_buffer_commit),
        .lsq_store_wmask(dfp_wmask_to_pcsb),
        .lsq_store_wdata(dfp_wdata_to_pcsb),
        .lsq_rmask(rmask_from_lsq),


        // To LSQ (for loads)
        .full(full_pcsb),

        // To D-Cache
        .dfp_wmask(dfp_wmask_data),
        .dfp_wdata(dfp_wdata_data),
        .dfp_addr(dfp_addr_data_from_pcsb),

        // From D-cache
        .dfp_resp(dfp_resp_data),

        // Arbiter
        .load(load),
        .forward_resp_load(resp_from_pcsb),
        .forward_rdata_load(rdata_from_pcsb),
        .mask_loads(mask_loads),
        .invalid_dfp_flush(invalid_dfp_flush_pcsb),

        .mask_conflict(mask_conflict)
    );

    cache_adapter cache_adapter_i (
        .clk        (clk),
        .rst        (rst),

        // From arbiter
        .ufp_addr   (arb_cache_line_addr),
        .ufp_read   (arb_cache_line_read),
        .ufp_write  (arb_cache_line_write),
        .ufp_wdata  (arb_cache_line_wdata),
        .ufp_rdata  (arb_cache_line_rdata),
        .ufp_resp   (arb_cache_line_resp),

        // Memory
        .dfp_raddr  (bmem_raddr),
        .dfp_ready  (bmem_ready),
        .dfp_rvalid (bmem_rvalid),
        .dfp_rdata  (bmem_rdata),
        .dfp_addr   (bmem_addr),
        .dfp_read   (bmem_read),
        .dfp_write  (bmem_write),
        .dfp_wdata  (bmem_wdata)
    );

    decode decode(
        // .inst(rdata[31:0]),
        .inst(rdata.instruction),
        // .pc(rdata[63:32]),
        .pc_next(rdata.pc_next),
        .pc(rdata.pc),
        // .instr_ready(dequeue),
        .id_ex_reg_next(id_ex_reg_next)
    );

    rename_dispatch #(
        .QUEUE_DEPTH_ROB(QUEUE_DEPTH_ROB)
    ) rename_dispatch (
        .clk(clk),
        .rst(rst),
        .stall(stall),

        // From Decode
        .id_ex_reg_next(id_ex_reg_next),
        .instr_ready(~empty),
        .branch_pred(rdata.branch_pred),
        .branch_pred_gshare(rdata.branch_pred_gshare),
        .tournament_pred(rdata.tournament_pred), // connect

        // To and From RAT
        .rd(rd),
        .pd(pd),
        .regf_we(regf_we),

        .rs1(rs1),
        .ps1(ps1),
        .ps1_valid(ps1_valid),

        .rs2(rs2),
        .ps2(ps2),
        .ps2_valid(ps2_valid),
        
        // Frm Free List
        .rd_fl(rdata_fl),
        .empty_fl(empty_fl),
        .dequeue_fl(dequeue_fl),
        
        // ToROB
        .rd_rob(rd_rob),
        .pd_rob(pd_rob),
        .ready_commit_rob(ready_commit_rob),
        .full_rob(full_rob),
        .enqueue_rob(enqueue_rob),
        .rob_entry(rob_idx),

        .opcode_b_pred(opcode_b_pred),

        .order_br(order_br),
        .order_to_ROB(order_to_ROB),
        .pc_to_ROB(pc_to_ROB),
        
        // To Reservation Station(s)
        .rs_add_full(rs_add_full), 
        .rs_mul_full(rs_mul_full), 
        .rs_div_full(rs_div_full),
        .rs_ls_full(rs_ls_full),

        .res_entry_out(res_entry),
        .res_entry_ls_out(res_entry_ls),
        .regf_we_rs_add(regf_we_rs_add),
        .regf_we_rs_mul(regf_we_rs_mul),
        .regf_we_rs_div(regf_we_rs_div),
        .regf_we_rs_ls(regf_we_rs_ls),

        //from load store queue
        .full_lsq(full_lsq),
        .enqueue_lsq(enqueue_lsq),
        .lsq_entry_out(wdata_LSQ),
        .lsq_entry(LSQ_idx_to_ren_disp),

        .flush(flush)
    );

    free_list  #(
        .DATA_WIDTH(DATA_WIDTH_FL),
        .QUEUE_DEPTH(QUEUE_DEPTH_FL)
    ) free_list_i (
        .clk(clk),
        .rst(rst),
        .wdata(enqueue_wdata_fl),
        .enqueue(enqueue_fl),
        .rdata(rdata_fl),
        .dequeue(dequeue_fl),
        .full(full_fl),
        .empty(empty_fl),
        .flush(flush)
    );

    RAT rat_i (
        .clk(clk),
        .rst(rst),

        // Coming from rename/dispatch
        .rd(rd),
        .pd(pd),
        .regf_we(regf_we),

        // Rename/dispatch
        .rs1(rs1),
        .ps1(ps1),
        .ps1_valid(ps1_valid),

        .rs2(rs2),
        .ps2(ps2),
        .ps2_valid(ps2_valid),

        // From CDB
        // .cdb_in(cdb_data)
        .cdb_in_add(cdb_data_add),
        .cdb_in_mul(cdb_data_mul),
        .cdb_in_div(cdb_data_div),
        .cdb_in_ls(cdb_data_ls),
        .flush(flush),
        // .delay_flush(delay_flush),
        .data_flush(data_flush)

        // .rd_rob_head(rd_rob_head),
        // .pd_rob_head(pd_rob_head)

    );

    rs_add #(
        .RES_ADD_ENTRIES(RES_ADD_ENTRIES),
        .QUEUE_DEPTH_ROB(QUEUE_DEPTH_ROB)
    ) rs_add_i (
        .clk(clk),
        .rst(rst),
        // For Rename/Dispatch
        .res_entry_in(res_entry),
        .rendisp_regf_we(regf_we_rs_add),

        .rs_add_full(rs_add_full),

        // For CDB
        // .cdb_in(cdb_data),
        .cdb_in_add(cdb_data_add),
        .cdb_in_mul(cdb_data_mul),
        .cdb_in_div(cdb_data_div),
        .cdb_in_ls(cdb_data_ls),        

        .ps1_add_tosend_tophyreg(ps1_add_tosend_tophyreg), 
        .ps2_add_tosend_tophyreg(ps2_add_tosend_tophyreg),
        .decode_packet_from_add_rs(decode_packet_from_add),
        .rob_entry_from_add_rs(rob_entry_from_add_rs),
        .pd_from_add_rs(pd_from_add_rs),
        .activate_add(activate_add),
        .flush(flush),

        .branch_pred(branch_pred),
        .branch_pred_gshare(branch_pred_gshare),
        .tournament_predictor(tournament_predictor)//connect
    );

    rs_mul #(
        .RES_MUL_ENTRIES(RES_MUL_ENTRIES),
        .QUEUE_DEPTH_ROB(QUEUE_DEPTH_ROB)
    ) rs_mul_i (
        .clk(clk),
        .rst(rst),        
        // For Rename/Dispatch
        .res_entry_in(res_entry),
        .rendisp_regf_we(regf_we_rs_mul),

        .rs_mul_full(rs_mul_full),

        // For CDB
        .cdb_in_add(cdb_data_add),
        .cdb_in_mul(cdb_data_mul),
        .cdb_in_div(cdb_data_div), 
        .cdb_in_ls(cdb_data_ls),       

        .ps1_mul_tosend_tophyreg(ps1_mul_tosend_tophyreg), 
        .ps2_mul_tosend_tophyreg(ps2_mul_tosend_tophyreg),
        .decode_packet_from_mul_rs(decode_packet_from_mul),
        .rob_entry_from_mul_rs(rob_entry_from_mul_rs),
        .pd_from_mul_rs(pd_from_mul_rs),

        .activate_mul(activate_mul),
        .counter(counter_mul),
        .flush(flush)
    );

    rs_div #(
        .RES_DIV_ENTRIES(RES_DIV_ENTRIES),
        .QUEUE_DEPTH_ROB(QUEUE_DEPTH_ROB)
    ) rs_div_i (
        .clk(clk),
        .rst(rst),        
        // For Rename/Dispatch
        .res_entry_in(res_entry),
        .rendisp_regf_we(regf_we_rs_div),

        .rs_div_full(rs_div_full),

        // For CDB
        .cdb_in_add(cdb_data_add),
        .cdb_in_mul(cdb_data_mul),
        .cdb_in_div(cdb_data_div),    
        .cdb_in_ls(cdb_data_ls),    

        .ps1_div_tosend_tophyreg(ps1_div_tosend_tophyreg), 
        .ps2_div_tosend_tophyreg(ps2_div_tosend_tophyreg),
        .decode_packet_from_div_rs(decode_packet_from_div),
        .rob_entry_from_div_rs(rob_entry_from_div_rs),
        .pd_from_div_rs(pd_from_div_rs),

        .activate_div(activate_div),
        .counter(counter_div),
        .flush(flush)
    );

    rs_ls #(
        .RES_LS_ENTRIES(RES_LS_ENTRIES)
    ) rs_ls_i (
        .clk(clk),
        .rst(rst),
        // For Rename/Dispatch
        .res_entry_in(res_entry_ls),
        .rendisp_regf_we(regf_we_rs_ls),

        .rs_ls_full(rs_ls_full),

        // For CDB
        // .cdb_in(cdb_data),
        .cdb_in_add(cdb_data_add),
        .cdb_in_mul(cdb_data_mul),
        .cdb_in_div(cdb_data_div),
        .cdb_in_ls(cdb_data_ls),


        .ps1_ls_tosend_tophyreg(ps1_ls_tosend_tophyreg), 
        .ps2_ls_tosend_tophyreg(ps2_ls_tosend_tophyreg),
        .decode_packet_from_ls_rs(decode_packet_from_ls),
        .activate_ls(activate_ls),
        .lsq_entry_from_ls_rs(lsq_entry_from_rs),
        .flush(flush)
    );

    ROB #(
        .DATA_WIDTH_ROB(DATA_WIDTH_ROB),
        .QUEUE_DEPTH_ROB(QUEUE_DEPTH_ROB)
    ) rob_i (
        .clk(clk),
        .rst(rst),

        .enqueue(enqueue_rob),

        // To Rename/Dispatch
        .full(full_rob),                  
        .empty(empty_rob),                  

        // From Rename/Dispatch
        .rob_commit(ready_commit_rob),
        .rd_rob(rd_rob),
        .pd_rob(pd_rob),
        .order(order_to_ROB),
        .pc(pc_to_ROB),

        .branch_pred(rdata.branch_pred),
        .branch_pred_gshare(rdata.branch_pred_gshare),
        .tournament_pred(rdata.tournament_pred),

        //To Reservation Station
        .rob_idx(rob_idx),


        // .cdb_in(cdb_data),
        .cdb_in_add(cdb_data_add),
        .cdb_in_mul(cdb_data_mul),
        .cdb_in_div(cdb_data_div),
        .cdb_in_ls(cdb_data_ls),
               

        .rd(rd_rrf),
        .pd(pd_rrf),
        .commit_inst(commit_inst_rrf),

        .rvfi_add_fu(rvfi_add_fu),
        .rvfi_mul_fu(rvfi_mul_fu),
        .rvfi_div_fu(rvfi_div_fu),
        .rvfi_ls_fu(rvfi_ls_fu),

        .head_idx(head_idx_from_rob),


        .rob_entry_at_head(rob_entry_at_head),
        .flush_out(flush),
        .order_br(order_br),
        .pc_br(pc_br),

        .opcode_b_pred(opcode_b_pred),

        .write_branch_pred(write_branch_pred),
        .wdata_branch_pred(wdata_branch_pred),
        .wdata_tournament(wdata_tournament),
        .wresp(wresp),
        // .wresp_gshare(wresp_gshare),

        .wdata_branch_pred_gshare(wdata_branch_pred_gshare)

        // .rd_rob_head(rd_rob_head),
        // .pd_rob_head(pd_rob_head)

    );

    physical_regfile physical_regfile_i(
        .clk(clk),
        .rst(rst),

        .ps1_add(ps1_add_tosend_tophyreg),
        .ps2_add(ps2_add_tosend_tophyreg),
        .ps1_mul(ps1_mul_tosend_tophyreg),
        .ps2_mul(ps2_mul_tosend_tophyreg),
        .ps1_div(ps1_div_tosend_tophyreg),
        .ps2_div(ps2_div_tosend_tophyreg),
        .ps1_ls(ps1_ls_tosend_tophyreg),
        .ps2_ls(ps2_ls_tosend_tophyreg),
        
        // .cdb_in(cdb_data),
        .cdb_in_add(cdb_data_add),
        .cdb_in_mul(cdb_data_mul),
        .cdb_in_div(cdb_data_div),
        .cdb_in_ls(cdb_data_ls),


        .ps1_value_add(ps1_executeval_add),
        .ps2_value_add(ps2_executeval_add),

        .ps1_value_mul(ps1_executeval_mul),
        .ps2_value_mul(ps2_executeval_mul),

        .ps1_value_div(ps1_executeval_div),
        .ps2_value_div(ps2_executeval_div),

        .ps1_value_ls(ps1_executeval_ls),
        .ps2_value_ls(ps2_executeval_ls)           
    );

    RRF rrf_i (
        .clk(clk),
        .rst(rst),

        .rd(rd_rrf),
        .pd(pd_rrf),
        .commit_inst(commit_inst_rrf),

        .old_pd_idx(enqueue_wdata_fl),
        .enqueue_fl(enqueue_fl),
        .data_flush(data_flush)

        // .flush(flush),
        // .delay_flush(delay_flush)

    );

    functional_unit #(
        .QUEUE_DEPTH_ROB(QUEUE_DEPTH_ROB)
    )adder (
        .clk(clk),
        .rst(rst),
        .ps1_executeval(ps1_executeval_add),
        .ps2_executeval(ps2_executeval_add),
        .decode_packet(decode_packet_from_add),
        .activate_add(activate_add),
        .rob_entry_from_rs(rob_entry_from_add_rs),
        .pd_from_rs(pd_from_add_rs),
        .cdb_output_add(cdb_data_add),

        .rvfi_add_fu(rvfi_add_fu),
        .flush(flush),

        .branch_pred(branch_pred),
        .branch_pred_gshare(branch_pred_gshare),
        .tournament_predictor(tournament_predictor)
    );

    DW_mult_pipe_inst #(
        .QUEUE_DEPTH_ROB(QUEUE_DEPTH_ROB)
    ) multiplier(
        .inst_clk(clk), 
        .inst_rst_n(!rst), 
        .inst_en('1), 
        // .inst_tc('0), 
        .inst_a(ps1_executeval_mul),
        .inst_b(ps2_executeval_mul), 
        // .product_inst(),

        .activate_mul(activate_mul),
        .counter(counter_mul),
        .cdb_output_mul(cdb_data_mul),

        // From RS
        .decode_packet(decode_packet_from_mul),
        .rob_entry_from_rs(rob_entry_from_mul_rs),
        .pd_from_rs(pd_from_mul_rs),

        .rvfi_mul_fu(rvfi_mul_fu),
        .flush(flush)
    );

    DW_div_pipe_inst #(
        .QUEUE_DEPTH_ROB(QUEUE_DEPTH_ROB)
    )divider (
        .inst_clk (clk), 
        .inst_rst_n (!rst), 
        .inst_en('1), 
        .inst_a (ps1_executeval_div), 
        .inst_b (ps2_executeval_div), 
        // .divide_by_0_inst(),

        .activate_div(activate_div),
        .counter(counter_div),
        .cdb_output_div(cdb_data_div),

        // From RS
        .decode_packet(decode_packet_from_div),
        .rob_entry_from_rs(rob_entry_from_div_rs),
        .pd_from_rs(pd_from_div_rs),

        .rvfi_div_fu(rvfi_div_fu),
        .flush(flush)
    );

    adder_address AGU (
        .clk(clk),
        .rst(rst),

        .ps1_executeval(ps1_executeval_ls),
        .ps2_executeval(ps2_executeval_ls),

        .decode_packet(decode_packet_from_ls),
        .activate_ls(activate_ls),
        // to lsq
        .output_addr_val(output_addr_val_to_lsq),
        .lsq_wfe(lsq_wfe_to_lsq),
        .ps2_val_to_lsq(ps2_val_to_lsq),
        .ps1_val_to_lsq(ps1_val_to_lsq),

        .lsq_entry_from_rs(lsq_entry_from_rs),
        .lsq_entry_res(lsq_entry_res)
    );

    arbiter_b_predictor_2_lvl #(
        .LHT_LENGTH(LHT_LENGTH),    
        .PHT_LENGTH(PHT_LENGTH)     
    ) branch_predictor (
        .clk(clk), 
        .rst(rst),

        // Read
        .read(read_b_prediction),
        .pc(pc),
        .rresp(prediction_resp),
        .prediction(prediction),

        // Write
        .write(write_branch_pred), // from commit
        .wdata(wdata_branch_pred), // changed struct from commit
        .wresp(wresp),

        // LHT
        .lht_index(lht_index),
        .lht_history(lht_history),
        .write_lht_history(write_lht_history),
        .lht_web(lht_web),

        // PHT
        .pht_index(pht_index),
        .pht_counter(pht_counter),
        .write_pht_counter(write_pht_counter),
        .pht_web(pht_web),

        // Valid LHT
        .valid_lht(valid_lht),
        .write_valid_lht(write_valid_lht),

        // Valid PHT
        .valid_pht(valid_pht),
        .write_valid_pht(write_valid_pht),

        .flush(flush),
        .state(state_2lvl)
    );

    arbiter_b_predictor_gshare #(
        .GHR_LENGTH(GHR_LENGTH)   
    ) branch_predictor_gshare (
        .clk(clk), 
        .rst(rst),

        // Read
        .read(read_b_prediction),
        .pc(pc),
        .rresp_gshare(prediction_resp_gshare),
        .prediction_gshare(prediction_gshare),
        // .rresp_2_lvl(prediction_resp),

        // Write
        .write(write_branch_pred), // from commit
        .wdata_gshare(wdata_branch_pred_gshare), // changed struct from commit
        .wresp_gshare(wresp_gshare),

        // PHT
        .pht_index_gshare(pht_index_gshare),
        .pht_counter_gshare(pht_counter_gshare),
        .wdata_pht_counter_gshare(wdata_pht_counter_gshare),
        .pht_web_gshare(pht_web_gshare),

        // Valid PHT
        .valid_pht_gshare(valid_pht_gshare),
        .write_valid_pht_gshare(write_valid_pht_gshare),

        .flush(flush),
        .state_2lvl(state_2lvl)
    );


    tournament_pred #(
        .GHR_LENGTH(GHR_LENGTH),
        .LHT_LENGTH(LHT_LENGTH),    
        .PHT_LENGTH(PHT_LENGTH),
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .CHOOSER_PHT_SIZE(CHOOSER_PHT_SIZE)
    ) tournament_pred_i(
        // .clk(clk), 
        // .rst(rst),

        // .read(read_b_prediction),
        .pc(pc),
        // .write(write_branch_pred),
        // .flush(flush),
        // .read(read_b_prediction),

        .rresp_gshare(prediction_resp_gshare),
        .prediction_gshare(prediction_gshare),
        // .wresp_gshare(wresp_gshare),
        .wdata_gshare(wdata_branch_pred_gshare),

        .prediction(prediction),
        // .wresp_2lvl(wresp),
        .rresp_2lvl(prediction_resp),
        .wdata(wdata_branch_pred),

        // .final_prediction(final_prediction_tournament),
        .prediction_tournament(prediction_tournament),
        .wdata_tournament(wdata_tournament)
    );

    lht_array lht_array_i (
        .clk0       (clk),
        .csb0       (1'b0),
        .web0       (lht_web),
        .addr0      (lht_index),
        .din0       (write_lht_history),
        .dout0      (lht_history)
    );
    valid_lht_array #(
        .S_INDEX(LHT_LENGTH),
        .WIDTH(1)
    ) valid_lht_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (1'b0),
        .web0       (write_valid_lht),
        .addr0      (lht_index),
        .din0       ('1),
        .dout0      (valid_lht)
    );

    pht_array pht_array_i (
        .clk0       (clk),
        .csb0       (1'b0),
        .web0       (pht_web),
        .addr0      (pht_index),
        .din0       (write_pht_counter),
        .dout0      (pht_counter)
    );
    valid_pht_array #(
        .S_INDEX(PHT_LENGTH),
        .WIDTH(1)
    ) valid_pht_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (1'b0),
        .web0       (write_valid_pht),
        .addr0      (pht_index),
        .din0       ('1),
        .dout0      (valid_pht)
    );

    pht_array_gshare pht_array_gshare_i (
        .clk0       (clk),
        .csb0       (1'b0),
        .web0       (pht_web_gshare),
        .addr0      (pht_index_gshare),
        .din0       (wdata_pht_counter_gshare),
        .dout0      (pht_counter_gshare)
    );
    valid_pht_array_gshare #(
        .S_INDEX(GHR_LENGTH),
        .WIDTH(1)
    ) valid_pht_array_gshare (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (1'b0),
        .web0       (write_valid_pht_gshare),
        .addr0      (pht_index_gshare),
        .din0       ('1),
        .dout0      (valid_pht_gshare)
    );

    // logic prefetch_sram_web;    
    // logic [$clog2(NUM_LINES)-1:0] prefetch_sram_index; 
    // logic [255:0] wdata_prefetch_sram;
    // logic [255:0] rdata_prefetch_sram;

    instr_prefetcher #(
        .NUM_LINES(NUM_LINES)
    ) inst_prefetcher_i  (
        .clk(clk),
        .rst(rst),

        // From I-Cache
        .read(prefetch_read),
        .addr(prefetch_addr),

        // To I-Cache
        .resp(prefetch_resp),
        .rdata(prefetch_rdata),

        // To Memory (Arbiter)
        .mem_addr(i_cache_line_addr),
        .mem_read(i_cache_line_read),
        .mem_write(i_cache_line_write), // should always be 0
        .mem_wdata(i_cache_line_wdata), // dont need
        .mem_rdata(i_cache_line_rdata),
        .mem_resp(i_cache_line_resp)

        // // Prefetch SRAM
        // .prefetch_sram_web(prefetch_sram_web),
        // .prefetch_sram_index(prefetch_sram_index),
        // .wdata_prefetch_sram(wdata_prefetch_sram),
        // .rdata_prefetch_sram(rdata_prefetch_sram)
    );

    // prefetch_sram prefetch_sram (
    //     .clk0       (clk),
    //     .csb0       (1'b0),
    //     .web0       (prefetch_sram_web),
    //     .addr0      (prefetch_sram_index),
    //     .din0       (wdata_prefetch_sram),
    //     .dout0      (rdata_prefetch_sram)
    // );

    logic           monitor_valid;
    logic   [63:0]  monitor_order;
    logic   [31:0]  monitor_inst;
    logic   [4:0]   monitor_rs1_addr;
    logic   [4:0]   monitor_rs2_addr;
    logic   [31:0]  monitor_rs1_rdata;
    logic   [31:0]  monitor_rs2_rdata;
    logic   [4:0]   monitor_rd_addr;
    logic   [31:0]  monitor_rd_wdata;
    logic   [4:0]   monitor_frd_addr;
    logic   [31:0]  monitor_frd_wdata;
    logic   [31:0]  monitor_pc_rdata;
    logic   [31:0]  monitor_pc_wdata;
    logic   [31:0]  monitor_mem_addr;
    logic   [3:0]   monitor_mem_rmask;
    logic   [3:0]   monitor_mem_wmask;
    logic   [31:0]  monitor_mem_rdata;
    logic   [31:0]  monitor_mem_wdata;

    assign monitor_valid     = rob_entry_at_head.rob_commit && commit_inst_rrf;
    assign monitor_order     = rob_entry_at_head.rvfi_packet.order;
    assign monitor_inst      = rob_entry_at_head.rvfi_packet.inst;
    assign monitor_rs1_addr  = rob_entry_at_head.rvfi_packet.rs1_s;
    assign monitor_rs2_addr  = rob_entry_at_head.rvfi_packet.rs2_s;
    assign monitor_rs1_rdata = rob_entry_at_head.rvfi_packet.rs1_rdata;
    assign monitor_rs2_rdata = rob_entry_at_head.rvfi_packet.rs2_rdata;
    assign monitor_rd_addr   = rob_entry_at_head.rvfi_packet.rd_s;
    assign monitor_rd_wdata  = rob_entry_at_head.rvfi_packet.rd_wdata;
    assign monitor_frd_addr  = '0;
    assign monitor_frd_wdata = '0;
    assign monitor_pc_rdata  = rob_entry_at_head.rvfi_packet.pc;
    assign monitor_pc_wdata  = rob_entry_at_head.rvfi_packet.pc_next;
    assign monitor_mem_addr  = rob_entry_at_head.rvfi_packet.mem_addr;
    assign monitor_mem_rmask = rob_entry_at_head.rvfi_packet.mem_rmask;
    assign monitor_mem_wmask = rob_entry_at_head.rvfi_packet.mem_wmask;
    assign monitor_mem_rdata = rob_entry_at_head.rvfi_packet.mem_rdata;
    assign monitor_mem_wdata = rob_entry_at_head.rvfi_packet.mem_wdata;

endmodule : cpu