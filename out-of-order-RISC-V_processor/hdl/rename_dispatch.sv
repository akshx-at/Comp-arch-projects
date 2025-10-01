module rename_dispatch
import rv32i_types::*;
#(
    parameter QUEUE_DEPTH_ROB = 16
)
(
    input logic clk,
    input logic rst,

    // To Instr FIFO
    output logic stall,

    // From Decode
    input id_ex_stage_reg_t id_ex_reg_next,
    input logic instr_ready,
    input predictor_t branch_pred,
    input predictor_gshare_t branch_pred_gshare,
    input tournament_t tournament_pred,
    
    // To and From RAT
    output  logic [4:0] rd,
    output  logic [5:0] pd,
    output  logic       regf_we,

    output  logic [4:0] rs1,
    input   logic [5:0] ps1,
    input   logic       ps1_valid,

    output  logic [4:0] rs2,
    input   logic [5:0] ps2,
    input   logic       ps2_valid,

    // From Free List
    input   logic [5:0] rd_fl,
    input   logic       empty_fl,
    output  logic       dequeue_fl,

    // From LSQ
    input logic full_lsq,
    output logic enqueue_lsq,
    input logic [2:0] lsq_entry,

    // To ROB
    output logic  [4:0] rd_rob,
    output logic  [5:0] pd_rob,
    output logic        ready_commit_rob,
    input logic        full_rob,
    output logic enqueue_rob,
    input  logic  [$clog2(QUEUE_DEPTH_ROB)-1:0] rob_entry,

    input logic [31:0] order_br,

    output logic [31:0] order_to_ROB,
    output logic [31:0] pc_to_ROB,

    output logic [6:0] opcode_b_pred,

    // To Reservation Station(s)
    input logic rs_add_full, rs_mul_full, rs_div_full, rs_ls_full,
    output reservation_station_t res_entry_out,
    output reservation_station_ls_t res_entry_ls_out,
    output logic regf_we_rs_add,
    output logic regf_we_rs_mul,
    output logic regf_we_rs_div,
    output logic regf_we_rs_ls,

    // To LSQ
    output lsq_t lsq_entry_out,

    input logic flush

);
    localparam RES_LS_ENTRIES = 5;

    logic [31:0] order;

    always_ff @(posedge clk) begin
        if(rst) begin
            order <= '0;
        end
        else if (flush) begin
            order <= order_br + 32'd1;
        end
        else if  (!full_rob && instr_ready && !stall) begin
            order <= order + 32'd1;
        end
    end

    always_comb begin
        // For RAT
        rs1 = id_ex_reg_next.rs1_s;
        rs2 = id_ex_reg_next.rs2_s;

        // For Free List
        if (!empty_fl && instr_ready && !stall && (id_ex_reg_next.rd_s != '0)) begin
            pd = rd_fl;
            dequeue_fl = 1'b1;    
            rd = id_ex_reg_next.rd_s;     
            regf_we = 1'b1;
        end else begin
            pd = '0;
            dequeue_fl = 1'b0;    
            rd = '0;   
            regf_we = 1'b0;  
        end
    
        res_entry_out = 'x;
        res_entry_ls_out = 'x;
        // For Reservation Station(s)
        if (!full_rob && instr_ready && !(id_ex_reg_next.opcode == op_b_store || id_ex_reg_next.opcode == op_b_load)) begin
            res_entry_out.ps1_res = ps1;
            res_entry_out.ps2_res = ps2;
            res_entry_out.ps1_v_res = ps1_valid;
            res_entry_out.ps2_v_res = ps2_valid;
            res_entry_out.rob_entry_res = rob_entry;
            res_entry_out.decode_packet = id_ex_reg_next;
            res_entry_out.decode_packet.order = order;
            res_entry_out.pd_res = pd;
            res_entry_out.rd_res = rd;
            res_entry_out.branch_pred = branch_pred;
            res_entry_out.branch_pred_gshare = branch_pred_gshare;
            res_entry_out.tournament_predictor = tournament_pred;
        end else if (!full_rob && instr_ready && (id_ex_reg_next.opcode == op_b_store || id_ex_reg_next.opcode == op_b_load)) begin
            res_entry_ls_out.ps1_res = ps1;
            res_entry_ls_out.ps2_res = ps2;
            res_entry_ls_out.ps1_v_res = ps1_valid;
            res_entry_ls_out.ps2_v_res = ps2_valid;
            // res_entry_ls_out.rob_entry_res = rob_entry;
            res_entry_ls_out.decode_packet = id_ex_reg_next;
            res_entry_ls_out.decode_packet.order = order;
            res_entry_ls_out.pd_res = pd;
            res_entry_ls_out.lsq_entry_res = lsq_entry;
            // res_entry_ls_out.rd_res = rd;          
        end
    end

    always_comb begin
        regf_we_rs_add = 1'b0;
        regf_we_rs_mul = 1'b0;
        regf_we_rs_div = 1'b0;
        regf_we_rs_ls = 1'b0;
        stall = 1'b0;
        if (full_rob) begin
            stall = 1'b1;
        end
        else begin
            if (instr_ready) begin
                if (id_ex_reg_next.opcode == op_b_reg) begin
                    if (id_ex_reg_next.funct7[0]) begin
                        // MUL OR DIV
                        if (id_ex_reg_next.funct3[2]) begin
                            // DIV
                            regf_we_rs_div = rs_div_full ? 1'b0 : 1'b1;
                            stall = rs_div_full ? 1'b1 : 1'b0;
                        end
                        else if (!id_ex_reg_next.funct3[2]) begin
                            // MUL
                            regf_we_rs_mul = rs_mul_full ? 1'b0 : 1'b1;
                            stall = rs_mul_full ? 1'b1 : 1'b0;
                        end
                    end
                    else begin
                        // ADD
                        regf_we_rs_add = rs_add_full ? 1'b0 : 1'b1;
                        stall = rs_add_full ? 1'b1 : 1'b0;
                    end
                end
                else if(id_ex_reg_next.opcode == op_b_imm) begin
                    regf_we_rs_add = rs_add_full ? 1'b0 : 1'b1;
                    stall = rs_add_full ? 1'b1 : 1'b0;
                end
                else if (id_ex_reg_next.opcode == op_b_lui) begin
                    regf_we_rs_add = rs_add_full ? 1'b0 : 1'b1;
                    stall = rs_add_full ? 1'b1 : 1'b0;                    
                end
                else if (id_ex_reg_next.opcode == op_b_store || id_ex_reg_next.opcode == op_b_load) begin
                    regf_we_rs_ls = (rs_ls_full || full_lsq) ? 1'b0 : 1'b1;
                    stall = (rs_ls_full || full_lsq) ? 1'b1 : 1'b0;
                end
                else if (id_ex_reg_next.opcode == op_b_auipc) begin
                    regf_we_rs_add = rs_add_full ? 1'b0 : 1'b1;
                    stall = rs_add_full ? 1'b1 : 1'b0;
                end
                else if (id_ex_reg_next.opcode == op_b_br || id_ex_reg_next.opcode == op_b_jal || id_ex_reg_next.opcode == op_b_jalr) begin
                    regf_we_rs_add = rs_add_full ? 1'b0 : 1'b1;
                    stall = rs_add_full ? 1'b1 : 1'b0;
                end
            end
        end
    end

    // ROB
    always_comb begin
        if (!stall && instr_ready) begin
            ready_commit_rob = 1'b0;
            pd_rob = rd_fl;
            enqueue_rob = 1'b1;
            rd_rob = id_ex_reg_next.rd_s;
            order_to_ROB = order;
            pc_to_ROB = id_ex_reg_next.pc;
            opcode_b_pred = id_ex_reg_next.opcode;
        end else begin
            ready_commit_rob = 'x;
            pd_rob = 'x;
            rd_rob = 'x;
            enqueue_rob = 1'b0;
            order_to_ROB = 'x;
            pc_to_ROB = 'x;
            opcode_b_pred = 'x;
        end
    end

    // LSQ
    always_comb begin
        if (!stall && instr_ready && (id_ex_reg_next.opcode == op_b_store || id_ex_reg_next.opcode == op_b_load)) begin
            enqueue_lsq = 1'b1;
            
            lsq_entry_out.lsq_commit = 1'b0;
            lsq_entry_out.pd_lsq = pd;
            lsq_entry_out.rd_lsq = id_ex_reg_next.rd_s;
            lsq_entry_out.address_lsq = '0;
            lsq_entry_out.ps2_val_to_lsq = '0;
            lsq_entry_out.ps1_val_to_lsq = '0;
            lsq_entry_out.rob_entry_res = rob_entry;

            lsq_entry_out.rvfi_packet = 'x;
            lsq_entry_out.rvfi_packet.inst = id_ex_reg_next.inst;
            lsq_entry_out.rvfi_packet.pc = id_ex_reg_next.pc;
            lsq_entry_out.rvfi_packet.order = order;
            lsq_entry_out.rvfi_packet.rs1_s = id_ex_reg_next.rs1_s;
            lsq_entry_out.rvfi_packet.rs2_s = id_ex_reg_next.rs2_s;
            lsq_entry_out.rvfi_packet.rd_s = id_ex_reg_next.rd_s;
        end else begin
            enqueue_lsq = 1'b0;
            lsq_entry_out = 'x;
        end
    end


endmodule : rename_dispatch
