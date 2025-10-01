module functional_unit
import rv32i_types::*;
#(
    // parameter RES_ADD_ENTRIES = 5      // Width of data bus
    parameter QUEUE_DEPTH_ROB = 16
)


// we get cycle 1 of the operations and then we do the operation in the next cycle/depending on how many cycle it takes to perform the information

// *** where do we get the data from: 
                                    // if register values, we get it from PRf, otherwise we get it from the rs (this is for addition and all other operations)
                                    // we get the ROb idx value for that operation as well

// ** where do we send the data: 
                                // Send the data, register value(physical and architectural index value) to the CDB, ROB entry index  looks like this: ROB0, x2, p33, result
                                // output the value we have calculated, store that onto the physical register value
                                // Update all the rs, that were depending on this result as valid
                                // update the RAT and RRF such that it stores the value that has ben calculated
                                // update ROB_Commt once we get the value, so that it sets to one,


// as it take variable cycle times so we need to make sure that we have a flag for that 
(
    input logic clk,
    input logic rst,
    // input logic [5:0] ps1_add_tosend_tophyreg,
    // input logic [5:0] ps2_add_tosend_tophyreg,
    input logic [31:0] ps1_executeval,
    input logic [31:0] ps2_executeval,
    // input logic reg_imm_flag,

    input id_ex_stage_reg_t decode_packet,
    input logic activate_add,
    input logic [$clog2(QUEUE_DEPTH_ROB)-1:0] rob_entry_from_rs,
    input logic [5:0] pd_from_rs,

    // To CDB
    output cdb_t cdb_output_add,

    // RVFI
    output rvfi_t rvfi_add_fu,

    input logic flush,

    input predictor_t branch_pred,
    input predictor_gshare_t branch_pred_gshare,
    input tournament_t tournament_predictor

    // input   logic   [31:0] top_addr

    // input   logic   [31:0] top_addr

    // To load store queue
    // output logic 

);
    logic   [31:0]  a, b;
    logic   [2:0]   aluop;
    logic   [2:0]   cmpop;
    logic   [31:0]  aluout;
    logic   [2:0]   funct3;
    logic   [6:0]   funct7;
    logic   [6:0]   opcode;
    logic   [31:0]  pc_next;
    // logic           regf_we;
    logic           br_en;
    // logic           flushing;
    
    // logic   [3:0]   dmem_rmask_temp;
    // logic   [3:0]   dmem_rmask;
    // logic   [3:0]   dmem_wmask;
    // logic   [31:0]  dmem_addr;
    // logic   [31:0]  dmem_wdata;

    logic signed   [31:0] as;
    logic signed   [31:0] bs;
    logic unsigned [31:0] au;
    logic unsigned [31:0] bu;

    logic [31:0] rd_v;


    always_comb begin
        aluop = decode_packet.aluop;
        cmpop = decode_packet.cmpop;
        funct3 = decode_packet.funct3;
        funct7 = decode_packet.funct7;
        opcode = decode_packet.opcode;
        // regf_we = 1'b1;
        // order_br = decode_packet.order;
        a = decode_packet.alu_m1_sel == pc_out ? decode_packet.pc : ps1_executeval;
        b = decode_packet.alu_m2_sel == imm_out ? decode_packet.imm_gen : ps2_executeval;
    end

    assign as =   signed'(a);
    assign bs =   signed'(b);
    assign au = unsigned'(a);
    assign bu = unsigned'(b);

    always_comb begin
        unique case (aluop)
            alu_op_add: aluout = au +   bu;
            alu_op_sll: aluout = au <<  bu[4:0];
            alu_op_sra: aluout = unsigned'(as >>> bu[4:0]);
            alu_op_sub: aluout = au -   bu;
            alu_op_xor: aluout = au ^   bu;
            alu_op_srl: aluout = au >>  bu[4:0];
            alu_op_or : aluout = au |   bu;
            alu_op_and: aluout = au &   bu;
            default   : aluout = '0;
        endcase
    end

    always_comb begin
        unique case (cmpop)
            branch_f3_beq : br_en = (au == bu);
            branch_f3_bne : br_en = (au != bu);
            branch_f3_blt : br_en = (as <  bs);
            branch_f3_bge : br_en = (as >=  bs);
            branch_f3_bltu: br_en = unsigned'(au <  bu);
            branch_f3_bgeu: br_en = unsigned'(au >=  bu);
            default       : br_en = '0;
        endcase
    end


    // always_comb begin
    //     unique case (for_A)
    //         2'b00   : ex_mem_reg_next.rs1_v = rs1_v;
    //         2'b01   : ex_mem_reg_next.rs1_v = rs1_v_wb;
    //         2'b10   : ex_mem_reg_next.rs1_v = rs1_v_mem;
    //         default : ex_mem_reg_next.rs1_v = rs1_v;            
    //     endcase
    //     unique case (for_B)
    //         2'b00   : ex_mem_reg_next.rs2_v = rs2_v;
    //         2'b01   : ex_mem_reg_next.rs2_v = rs2_v_wb;
    //         2'b10   : ex_mem_reg_next.rs2_v = rs2_v_mem;
    //         default : ex_mem_reg_next.rs2_v = rs2_v;            
    //     endcase
    // end

    // always_comb begin
    //     unique case(decode_packet.alu_m1_sel)
    //         rs1_out : a = ex_mem_reg_next.rs1_v;
    //         pc_out  : a = decode_packet.pc;
    //         default : a = '0;
    //     endcase
    //     unique case(decode_packet.alu_m2_sel)
    //         rs2_out : b = ex_mem_reg_next.rs2_v;
    //         imm_out : b = decode_packet.imm_gen;
    //         default : b = '0;
    //     endcase
    // end        

    always_comb begin
        rd_v = aluout;
        pc_next = decode_packet.pc + 'd4;
        // flushing = 1'b0;

        unique case(opcode)
            op_b_auipc: begin
                rd_v = aluout;

            end
            op_b_lui: begin
                rd_v = decode_packet.imm_gen;
            end 
            op_b_imm: begin
                unique case (funct3)
                    arith_f3_slt: rd_v = {31'd0, br_en};
                    arith_f3_sltu: rd_v = {31'd0, br_en};
                    default : begin
                        rd_v = aluout;
                    end
                endcase
            end
            op_b_reg: begin
                unique case (funct3)
                    arith_f3_slt: rd_v = {31'd0, br_en};
                    arith_f3_sltu: rd_v = {31'd0, br_en};
                    default : begin
                        rd_v = aluout;
                    end
                endcase
            end
            op_b_jal: begin
                rd_v = decode_packet.pc + 'd4;
                pc_next = aluout;
                // flushing = 1'b1;
            end
            op_b_jalr: begin
                rd_v = decode_packet.pc + 'd4;
                // if ((decode_packet.rs1_s == 5'd1 || decode_packet.rs1_s == 5'd5) && (decode_packet.rd_s != 5'd5 && decode_packet.rd_s != 5'd1)) begin
                //     pc_next = top_addr & 32'hfffffffe;
                // end else begin
                //     pc_next = aluout & 32'hfffffffe;
                // end
                pc_next = aluout & 32'hfffffffe;
                // flushing = 1'b1;
            end
            op_b_br: begin
                pc_next = br_en ? unsigned'(decode_packet.pc) + unsigned'(decode_packet.imm_gen) : decode_packet.pc + 'd4;
                // flushing = br_en ? 1'b1 : 1'b0;
                // flushing = br_en;
                rd_v = {31'd0, br_en};
            end
            default: begin
                rd_v = aluout;
            end 
        endcase 
    end

    // assign dmem_rmask = dmem_rmask_temp;

    // always_comb begin
    //     ex_mem_reg_next.inst = decode_packet.inst;
    //     ex_mem_reg_next.pc = decode_packet.pc;
    //     ex_mem_reg_next.pc_next = pc_next;

    //     ex_mem_reg_next.order = decode_packet.order;
    //     ex_mem_reg_next.aluout = aluout;
    //     ex_mem_reg_next.regf_we = regf_we;
    //     ex_mem_reg_next.rd_s = rd_s;
    //     ex_mem_reg_next.rd_v = rd_v;
    //     ex_mem_reg_next.rs1_s = decode_packet.rs1_s;
    //     ex_mem_reg_next.rs2_s = decode_packet.rs2_s;
    //     // ex_mem_reg_next.rs1_v = rs1_v;
    //     // ex_mem_reg_next.rs2_v = rs2_v;
    //     ex_mem_reg_next.valid = decode_packet.valid;
    //     ex_mem_reg_next.opcode = decode_packet.opcode;
    //     ex_mem_reg_next.imm_gen = decode_packet.imm_gen;

    //     ex_mem_reg_next.dmem_rmask = dmem_rmask;
    //     ex_mem_reg_next.dmem_wmask = dmem_wmask;
    //     ex_mem_reg_next.dmem_addr = aluout;
    //     ex_mem_reg_next.dmem_wdata = dmem_wdata;

    //     // ex_mem_reg_next.flushing = flushing;

    //     ex_mem_reg_next.funct3 = funct3;
    //     ex_mem_reg_next.funct7 = funct7;
        
    // enddecode_packetn pc_branch = pc_next;
    always_ff @(posedge clk) begin
        if(rst || flush) begin
            cdb_output_add <= '0;
            rvfi_add_fu <= '0;
        end
        else if (activate_add) begin
            cdb_output_add.rob_entry_res <= rob_entry_from_rs;
            cdb_output_add.phys_reg <= pd_from_rs;
            cdb_output_add.arch_reg <= decode_packet.rd_s;
            cdb_output_add.result <= rd_v;
            cdb_output_add.regf_we <= 1'b1;

            // cdb_output_add.flush_rob <= (decode_packet.opcode == op_b_br) ? !br_en : (decode_packet.opcode == op_b_jalr) ? 1'b1 : 1'b0;
            if (decode_packet.opcode == op_b_br) begin
                if(tournament_predictor.branch_used) begin 
                    cdb_output_add.flush_rob <= (br_en == branch_pred.b_counter[1]) ? 1'b0 : 1'b1;
                end else begin 
                    cdb_output_add.flush_rob <= (br_en == branch_pred_gshare.b_counter_gshare[1]) ? 1'b0 : 1'b1 ; 
                end
                // cdb_output_add.flush_rob <= (br_en == branch_pred.b_counter[1]) ? 1'b0 : 1'b1;
                // cdb_output_add.flush_rob <= (br_en == branch_pred_gshare.b_counter_gshare[1]) ? 1'b0 : 1'b1;
                // cdb_output_add.flush_rob <= (br_en == tournament_predictor.final_prediction) ? 1'b0 : 1'b1;
            end else if (decode_packet.opcode == op_b_jalr) begin
                // if ((decode_packet.rs1_s == 5'd1 || decode_packet.rs1_s == 5'd5) && (decode_packet.rd_s != 5'd1 || decode_packet.rd_s != 5'd5)) begin
                if ((decode_packet.rs1_s == 5'd1 || decode_packet.rs1_s == 5'd5) && (decode_packet.rd_s != 5'd1 && decode_packet.rd_s != 5'd5)) begin
                    cdb_output_add.flush_rob <= 1'b0;
                    if (decode_packet.pc_next == pc_next) cdb_output_add.flush_rob <= 1'b0;
                    else cdb_output_add.flush_rob <= 1'b1;
                end else begin
                    cdb_output_add.flush_rob <= 1'b1;
                end
            end else begin
                cdb_output_add.flush_rob <= 1'b0;
            end
            
            cdb_output_add.address_br <= pc_next;
            // RVFI
            rvfi_add_fu.inst <= decode_packet.inst;
            rvfi_add_fu.pc <= decode_packet.pc;
            rvfi_add_fu.pc_next <= pc_next;
            rvfi_add_fu.rs1_s <= decode_packet.rs1_s;
            rvfi_add_fu.rs2_s <= decode_packet.rs2_s;
            rvfi_add_fu.rd_s <= decode_packet.rd_s;

            rvfi_add_fu.rs1_rdata <= ps1_executeval;
            rvfi_add_fu.rs2_rdata <= ps2_executeval;
            rvfi_add_fu.rd_wdata <= rd_v;
            rvfi_add_fu.order <= decode_packet.order;

            rvfi_add_fu.mem_addr <= 'x;
            rvfi_add_fu.mem_rmask <= '0;
            rvfi_add_fu.mem_wmask <= '0;
            rvfi_add_fu.mem_rdata <= 'x;
            rvfi_add_fu.mem_wdata <= '0;
        end
        else begin
            cdb_output_add.regf_we <= 1'b0;
        end
    end

endmodule : functional_unit
