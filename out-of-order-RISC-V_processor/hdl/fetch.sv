module fetch 
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    input logic full,
    input logic [31:0] inst,
    // input logic [31:0] instruction,

    // output logic dequeue,
    // output logic enqueue,
    // output logic [(DATA_WIDTH) - 1 : 0] enqueue_wdata,
    output logic [31:0] pc,
    output logic [31:0] pc_next,
    // output logic [31:0] pc_next,
    output logic [31:0] imem_addr,
    input logic imem_resp,
    output logic [3:0] imem_rmask,

    input logic [31:0] pc_br,
    input logic flush,


    output logic read_b_prediction,
    input logic  prediction_resp,
    input predictor_t prediction,
    output logic stall_iq_pred,

    // RAS
    output  logic           push_en,
    output  logic           pop_en,
    output  logic   [31:0]  push_addr,
    input   logic   [31:0]  top_addr,
    // output logic stall_iq_pred,
    // output logic stall_iq_pred,

    input logic prediction_resp_gshare,
    input predictor_gshare_t prediction_gshare,
    input tournament_t prediction_tournament
    // input logic final_prediction
); 

    // logic [31:0] pc_next;
    logic [6:0]  opcode;
    logic [31:0] b_imm, j_imm;

    logic invalid_dfp_flush;
    logic checker1;
    assign checker1 = prediction.b_counter[1];

    assign b_imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign j_imm  = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
    assign opcode = inst[6:0];

    predictor_gshare_t prediction_gshare_temp;
    assign prediction_gshare_temp = prediction_gshare;

    logic [18:0] branch_counter;
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
 
    // assign pc_next = pc + 'd4;
    always_comb begin  
        stall_iq_pred = 1'b0;
        read_b_prediction = 1'b0;
        push_en = 1'b0;
        pop_en = 1'b0;
        push_addr = '0;

        if(flush) begin
            // pc_next = pc_br + 'd4;
            pc_next = pc_br;
        end
        else if (imem_resp && ~full && !invalid_dfp_flush) begin
            if (opcode == op_b_br) begin
                // if (prediction_resp) begin

                // branch_counter = branch_counter + 1'd1;
                
                if (prediction_resp && prediction_resp_gshare) begin
                    stall_iq_pred = 1'b0;
                    // pc_next = prediction.b_counter[1] ? pc + b_imm : pc + 'd4;
                    pc_next = prediction_tournament.final_prediction ? pc + b_imm : pc + 'd4;
                end else begin
                    read_b_prediction = 1'b1;
                    pc_next = pc;
                    stall_iq_pred = 1'b1;
                end
                // pc_next = pc + b_imm;
            end else if (opcode == op_b_jal) begin
                pc_next = pc + j_imm;
                if (inst[11:7] == 5'd1 || inst[11:7] == 5'd5) begin
                    push_en = 1'b1;
                    push_addr = pc + 'd4;
                end
            end else if (opcode == op_b_jalr) begin
                pc_next = pc + 'd4;
                if (inst[11:7] == 5'd1 || inst[11:7] == 5'd5) begin
                    if (inst[19:15] == 5'd1 || inst[19:15] == 5'd5) begin
                        if (inst[19:15] == inst[11:7]) begin
                            push_en = 1'b1;
                            push_addr = pc + 'd4;
                        end else begin
                            push_en = 1'b1;
                            pop_en = 1'b1;
                            pc_next = top_addr;
                            push_addr = pc + 'd4;
                        end
                    end else begin
                        push_en = 1'b1;
                        push_addr = pc + 'd4;
                    end
                end else begin
                    if (inst[19:15] == 5'd1 || inst[19:15] == 5'd5) begin
                        pop_en = 1'b1;
                        pc_next = top_addr;
                    end
                end
                if (inst[11:7] == 5'd1 || inst[11:7] == 5'd5) begin
                    push_en = 1'b1;
                    push_addr = pc + 'd4;
                end
            end else begin
                pc_next = pc + 'd4;
            end
        end
        else begin
            pc_next = pc;
        end
    end

    // PC update
    always_ff @(posedge clk) begin
        if (rst) begin        
            pc    <= 32'h1eceb000;
        end else if (flush) begin
            // pc <= pc_br + 'd4;
            pc <= pc_br;
        end else begin
            pc    <= pc_next;  
        end
    end

    always_comb begin
        imem_addr = pc_next;
        imem_rmask = '1;
        // dequeue = '0;
        // if (imem_resp) begin
        //     enqueue = 1'b1;
        //     enqueue_wdata = {pc, instruction};
        // end
        // else begin
        //     enqueue = 1'b0;
        //     enqueue_wdata = 'x;
        // end
    end

endmodule : fetch
