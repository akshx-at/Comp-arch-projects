module decode
import rv32i_types::*;
(
    // input   logic             clk,
    // input   logic             rst,  
    // input logic               regf_we,
    input  logic    [31:0]      inst, pc, pc_next,
    // input logic instr_ready,
    // output logic    [4:0]       rs1_s, rs2_s,
    // output logic                dequeue,
    output id_ex_stage_reg_t id_ex_reg_next
);

    logic   [4:0]   rd_s_temp;
    logic   [6:0]   opcode;
    logic   [2:0]   funct3;
    logic   [6:0]   funct7;
    logic   [2:0]   aluop;
    logic   [2:0]   cmpop;


    logic   [31:0]  pc_next_branch;
    logic   [31:0]  i_imm;
    logic   [31:0]  s_imm;
    logic   [31:0]  b_imm;
    logic   [31:0]  u_imm;
    logic   [31:0]  j_imm;
    logic   [31:0]  imm_gen;

    logic   [4:0]   rs1_s, rs2_s;
    
    always_comb begin
        rs1_s = inst[19:15];
        rs2_s = inst[24:20];
        rd_s_temp = inst[11:7];
        opcode = inst[6:0];
        i_imm  = {{21{inst[31]}}, inst[30:20]};
        s_imm  = {{21{inst[31]}}, inst[30:25], inst[11:7]};
        b_imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        u_imm  = {inst[31:12], 12'h000};
        j_imm  = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
        funct3 = inst[14:12];
        funct7 = inst[31:25];
    end     

    always_comb begin
        imm_gen = '0;
        aluop = '0;
        id_ex_reg_next.alu_m2_sel = rs2_out;
        id_ex_reg_next.alu_m1_sel = rs1_out;
        id_ex_reg_next.rs1_s = '0;
        id_ex_reg_next.rs2_s = '0;
        id_ex_reg_next.rd_s = rd_s_temp;
        unique case(opcode)
            op_b_lui    :   begin
                imm_gen = u_imm;
                id_ex_reg_next.alu_m2_sel = imm_out;
                id_ex_reg_next.rs2_s = '0;
            end 
            
            op_b_br :   begin
                id_ex_reg_next.alu_m1_sel = rs1_out;
                id_ex_reg_next.alu_m2_sel = rs2_out;
                id_ex_reg_next.rs1_s = rs1_s;
                id_ex_reg_next.rs2_s = rs2_s;
                // id_ex_reg_next.rd_s = '0;
                id_ex_reg_next.rd_s = '0;
                imm_gen = b_imm;
                // id_ex_reg_next.rs1_s = '0;
            end
            
            op_b_imm:   begin 
                if (funct3 == 3'b101) begin
                    if (funct7[5])
                        aluop = alu_op_sra;
                    else
                        aluop = alu_op_srl;
                end else
                    aluop = funct3;
                
                imm_gen = i_imm;
                id_ex_reg_next.alu_m2_sel = imm_out;
                id_ex_reg_next.alu_m1_sel = rs1_out;
                id_ex_reg_next.rs1_s = rs1_s;
                id_ex_reg_next.rs2_s = '0;

            end
            
            op_b_reg:   begin
                if (funct3 == 3'b000 && funct7 == 7'b0100000)
                    aluop = alu_op_sub;
                else if (funct3 == 3'b101) begin
                    if (funct7[5]) begin
                        aluop = alu_op_sra;
                    end else if (funct7[0]) begin
                        aluop = funct3;
                    end else begin
                        aluop = alu_op_srl;
                    end
                end
                else begin
                    aluop = funct3;
                end
                id_ex_reg_next.alu_m2_sel = rs2_out;
                id_ex_reg_next.alu_m1_sel = rs1_out;
                id_ex_reg_next.rs1_s = rs1_s;
                id_ex_reg_next.rs2_s = rs2_s;
            end
            
            op_b_auipc : begin
                aluop = alu_op_add;
                imm_gen = u_imm;
                id_ex_reg_next.alu_m2_sel = imm_out;
                id_ex_reg_next.rs2_s = '0;
                id_ex_reg_next.alu_m1_sel = pc_out;
                id_ex_reg_next.rs1_s = '0;
            end
            
            op_b_load : begin
                id_ex_reg_next.alu_m2_sel = imm_out;
                id_ex_reg_next.rs2_s = '0;
                id_ex_reg_next.alu_m1_sel = rs1_out;
                id_ex_reg_next.rs1_s = rs1_s;
                imm_gen = i_imm;
            end
            
            op_b_store : begin
                id_ex_reg_next.alu_m2_sel = imm_out;
                id_ex_reg_next.alu_m1_sel = rs1_out;
                id_ex_reg_next.rs1_s = rs1_s;
                id_ex_reg_next.rs2_s = rs2_s;
                imm_gen = s_imm;
                id_ex_reg_next.rd_s = '0;
            end

            op_b_jal: begin
                id_ex_reg_next.alu_m2_sel = imm_out;
                id_ex_reg_next.alu_m1_sel = pc_out;
                id_ex_reg_next.rs1_s = '0;
                id_ex_reg_next.rs2_s = '0;
                imm_gen = j_imm;
                aluop = alu_op_add;
            end

            op_b_jalr: begin
                id_ex_reg_next.alu_m2_sel = imm_out;
                id_ex_reg_next.alu_m1_sel = rs1_out;
                id_ex_reg_next.rs1_s = rs1_s;
                id_ex_reg_next.rs2_s = '0;
                imm_gen = i_imm;
                // For jalr since we don't have access to RS1_V we will do static not taken
                aluop = alu_op_add;
            end
            
            default : begin
                imm_gen = '0;
                aluop = funct3;
                id_ex_reg_next.rs2_s = rs2_s;
                id_ex_reg_next.alu_m2_sel = rs2_out;
                id_ex_reg_next.alu_m1_sel = rs1_out;
                id_ex_reg_next.rs1_s = rs1_s;
            end
        endcase
    end


    always_comb begin
        cmpop = funct3;
        unique case(funct3)
            arith_f3_slt : cmpop = branch_f3_blt;
            arith_f3_sltu : cmpop = branch_f3_bltu;
            default : cmpop = funct3;
        endcase
    end

    always_comb begin
        id_ex_reg_next.inst = inst;
        id_ex_reg_next.pc = pc;
        id_ex_reg_next.pc_next = pc_next;
        id_ex_reg_next.aluop = aluop;
        id_ex_reg_next.cmpop = cmpop;
        id_ex_reg_next.funct3 = funct3;
        id_ex_reg_next.funct7 = funct7;
        id_ex_reg_next.imm_gen = imm_gen;
        id_ex_reg_next.opcode = opcode;

        // RVIF
        id_ex_reg_next.rs1_rdata = '0;
        id_ex_reg_next.rs2_rdata = '0;
        id_ex_reg_next.rd_wdata = '0;
        id_ex_reg_next.order = '0;
    end

endmodule : decode
