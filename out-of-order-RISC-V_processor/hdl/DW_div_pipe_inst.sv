module DW_div_pipe_inst
import rv32i_types::*;
#(
    parameter QUEUE_DEPTH_ROB = 16
)
(
    inst_clk,
    inst_rst_n, 
    inst_en, 
    inst_a, 
    inst_b,
    // divide_by_0_inst,

    activate_div,
    counter,
    cdb_output_div,    

    decode_packet,
    rob_entry_from_rs,
    pd_from_rs,

    // RVFI
    rvfi_div_fu,

    flush
);

  localparam inst_a_width = 33;
  localparam inst_b_width = 33;
  localparam inst_tc_mode = 1;
  localparam inst_rem_mode = 1;
  localparam inst_num_stages = 7;
  localparam inst_stall_mode = 1;
  localparam inst_rst_mode = 1;
  localparam inst_op_iso_mode = 0;

  input inst_clk;
  input inst_rst_n;
  input inst_en;
  input [inst_a_width-2 : 0] inst_a;
  input [inst_b_width-2 : 0] inst_b;
//   output [inst_a_width-1 : 0] quotient_inst;
//   output [inst_b_width-1 : 0] remainder_inst;
//   output divide_by_0_inst;

// decode_packet.funct3[0] ? 1'b0 : 1'b1;

    input logic activate_div;
    output logic [$clog2(inst_num_stages)-1:0] counter;
    output cdb_t cdb_output_div;


    input id_ex_stage_reg_t decode_packet;
    input logic [$clog2(QUEUE_DEPTH_ROB)-1:0] rob_entry_from_rs;
    input logic [5:0] pd_from_rs;

    //RVFI
    output rvfi_t rvfi_div_fu;

    input flush;

    logic [$clog2(inst_num_stages)-1:0] counter_next;
    logic divide_by_0_val;
    // logic [inst_a_width+inst_b_width-1 : 0] product_inst;
    logic [inst_a_width-1 : 0] quotient_inst;
    logic [inst_b_width-1 : 0] remainder_inst;
    // logic funct3_val;
    // assign funct3_val =  decode_packet.funct3[0] ? 1'b0 : 1'b1;

    logic [inst_a_width - 1 : 0] input_a;
    logic [inst_b_width - 1 : 0] input_b;

    logic rem;

    logic invalid_dfp_flush;

    always_comb begin
        unique case (counter)
            3'b000: counter_next = activate_div ? 3'b001 : '0;
            // 2'b11: counter_next = '0;
            3'b110: counter_next = '0;
            default: counter_next = counter + 3'd1;
        endcase
    end

    always_ff @(posedge inst_clk) begin
        if  (!inst_rst_n) begin
            counter <= '0;
        end
        else begin
            counter <= counter_next;
        end
    end

    always_comb begin
        unique case (decode_packet.funct3[0])
            1'b0 : begin
                input_a = {inst_a[31], inst_a};
                input_b = {inst_b[31], inst_b};
            end
            1'b1 :  begin
                input_a = unsigned'({1'b0, inst_a});
                input_b = unsigned'({1'b0, inst_b});
            end
            default : begin
                input_a = {inst_a[31], inst_a};
                input_b = {inst_b[31], inst_b};
            end
        endcase
    end

    // Edge case mult flushing
    always_ff @(posedge inst_clk) begin
        if (!inst_rst_n) begin
            invalid_dfp_flush <= 1'b0;
        end else if (flush && (counter == 3'b00) && !activate_div) begin
            invalid_dfp_flush <= 1'b0;
        end else if (flush && !(counter == 3'b110)) begin
            invalid_dfp_flush <= 1'b1;
        end else if ((counter == 3'b110) && invalid_dfp_flush) begin
            invalid_dfp_flush <= 1'b0;
        end
    end       

    always_ff @(posedge inst_clk) begin
        if(!inst_rst_n) begin
            cdb_output_div <= '0;     
            rem <= 1'b0;      

            rvfi_div_fu <= '0;
        end
        else if (counter == 3'd0 && activate_div) begin
            cdb_output_div.rob_entry_res <= rob_entry_from_rs;
            cdb_output_div.phys_reg <= pd_from_rs;
            cdb_output_div.arch_reg <= decode_packet.rd_s;
            rem <= decode_packet.funct3[1];
            cdb_output_div.regf_we <= 1'b0;
            cdb_output_div.address_br <= 'x;

            // RVFI
            rvfi_div_fu.inst <= decode_packet.inst;
            rvfi_div_fu.pc <= decode_packet.pc;
            rvfi_div_fu.pc_next <= decode_packet.pc + 'd4;
            rvfi_div_fu.rs1_s <= decode_packet.rs1_s;
            rvfi_div_fu.rs2_s <= decode_packet.rs2_s;
            rvfi_div_fu.rd_s <= decode_packet.rd_s;

            rvfi_div_fu.rs1_rdata <= inst_a;
            rvfi_div_fu.rs2_rdata <= inst_b;
            
            rvfi_div_fu.order <= decode_packet.order;

            rvfi_div_fu.mem_addr <= 'x;
            rvfi_div_fu.mem_rmask <= '0;
            rvfi_div_fu.mem_wmask <= '0;
            rvfi_div_fu.mem_rdata <= 'x;
            rvfi_div_fu.mem_wdata <= '0;                   
        end
        else if ((counter == 3'b110) && !invalid_dfp_flush) begin
            cdb_output_div.regf_we <= 1'b1;

            if (divide_by_0_val) begin
                cdb_output_div.result <= rem ? rvfi_div_fu.rs1_rdata : '1;

                // RVFI
                rvfi_div_fu.rd_wdata <= rem ? rvfi_div_fu.rs1_rdata : '1;
            end
            else begin
                cdb_output_div.result <= rem ? remainder_inst[31:0] : quotient_inst[31:0];        

                // RVFI
                rvfi_div_fu.rd_wdata <= rem ? remainder_inst[31:0] : quotient_inst[31:0];  
            end      
        end
        else begin
            cdb_output_div.regf_we <= 1'b0;
        end
    end  

  // Instance of DW_div_pipe
  DW_div_pipe #(inst_a_width,   inst_b_width,   inst_tc_mode,  inst_rem_mode,
                inst_num_stages,   inst_stall_mode,   inst_rst_mode,   inst_op_iso_mode) 
    U1 (.clk(inst_clk),   .rst_n(inst_rst_n),   .en(inst_en),
        .a(input_a),   .b(input_b),   .quotient(quotient_inst),
        .remainder(remainder_inst),   .divide_by_0(divide_by_0_val) );
endmodule
