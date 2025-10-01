module DW_mult_pipe_inst
import rv32i_types::*;
#(
//     parameter inst_a_width = 32,  
//     parameter inst_b_width = 32,
//     parameter inst_num_stages = 3,
//     parameter inst_stall_mode = 1,  
//     parameter inst_rst_mode = 1,
//     parameter inst_op_iso_mode = 0

    // parameter RES_MUL_ENTRIES = 5      // Width of data bus
    parameter QUEUE_DEPTH_ROB = 16
)
(
    inst_clk, inst_rst_n, 
    inst_en, 
    // inst_tc, 
    inst_a, inst_b,
    activate_mul,
    counter,
    cdb_output_mul,
    
    // From RS
    decode_packet,
    rob_entry_from_rs,
    pd_from_rs,

    // RVFI
    rvfi_mul_fu,

    flush

    // input [inst_a_width-1 : 0] inst_a,  
    // input [inst_b_width-1 : 0] inst_b,  
    // input inst_tc,
    // input inst_clk,  
    // input inst_en, 
    // input inst_rst_n,  
    // output [inst_a_width+inst_b_width-1 : 0] product_inst,
    // input activate_mul,
    // output [1:0] counter
);  
    localparam inst_a_width = 33;  
    localparam inst_b_width = 33;
    localparam inst_num_stages = 3;  
    localparam inst_stall_mode = 1;  
    localparam inst_rst_mode = 1;  
    localparam inst_op_iso_mode = 0;  
    input logic [inst_a_width-2 : 0] inst_a;  
    input logic [inst_b_width-2 : 0] inst_b;  
    // input logic inst_tc;  
    input logic inst_clk;  
    input logic inst_en;  
    input logic inst_rst_n;  
    // output logic [inst_a_width+inst_b_width-1 : 0] product_inst;
    input logic activate_mul;
    output logic [1:0] counter;
    output cdb_t cdb_output_mul;


    input id_ex_stage_reg_t decode_packet;
    input logic [$clog2(QUEUE_DEPTH_ROB)-1:0] rob_entry_from_rs;
    input logic [5:0] pd_from_rs;

    // RVFI
    output rvfi_t rvfi_mul_fu;

    input logic flush;

    logic [1:0] counter_next;
    logic [inst_a_width+inst_b_width-1 : 0] product_inst; 

    logic [inst_a_width - 1 : 0]  input_a;
    logic [inst_b_width - 1 : 0]  input_b;
    logic input_tc;

    logic upper_bits;

    logic invalid_dfp_flush;

    always_comb begin
        unique case (decode_packet.funct3[1:0]) 
            2'b00: begin
                input_a = {inst_a[31], inst_a};
                input_b = {inst_b[31], inst_b};
                input_tc = 1'b1;
            end
            2'b01 : begin
                input_a = {inst_a[31], inst_a};
                input_b = {inst_b[31], inst_b};
                input_tc = 1'b1;
            end
            2'b10 : begin
                input_a = {inst_a[31], inst_a};
                input_b = unsigned'({1'b0, inst_b});
                input_tc = 1'b1;
            end
            2'b11 : begin
                input_a = unsigned'({1'b0, inst_a});
                input_b = unsigned'({1'b0, inst_b});
                input_tc = 1'b0;
            end
            default : begin
                input_a = {inst_a[31], inst_a};
                input_b = {inst_b[31], inst_b};
                input_tc = 1'b1;                
            end
        endcase
    end

    always_ff @(posedge inst_clk) begin
        if (!inst_rst_n) begin
            upper_bits <= 1'b1;
        end
        else if (activate_mul) begin
            upper_bits <= decode_packet.funct3 == '0 ? 1'b0 : 1'b1;
        end
    end

    always_comb begin
        unique case (counter)
            2'b00: counter_next = activate_mul ? 2'b01 : '0;
            2'b10: counter_next = '0;
            default: counter_next = counter + 2'd1;
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


    // Edge case mult flushing
    always_ff @(posedge inst_clk) begin
        if (!inst_rst_n) begin
            invalid_dfp_flush <= 1'b0;
        end else if (flush && (counter == 2'b00) && !activate_mul) begin
            invalid_dfp_flush <= 1'b0;
        end else if (flush && !(counter == 2'b10)) begin
            invalid_dfp_flush <= 1'b1;
        end else if ((counter == 2'b10) && invalid_dfp_flush) begin
            invalid_dfp_flush <= 1'b0;
        end
    end    


    always_ff @(posedge inst_clk) begin
        if(!inst_rst_n || flush) begin
            cdb_output_mul <= '0;       
            rvfi_mul_fu <= '0;
        end
        else if (counter == 2'b00 && activate_mul) begin
            cdb_output_mul.rob_entry_res <= rob_entry_from_rs;
            cdb_output_mul.phys_reg <= pd_from_rs;
            cdb_output_mul.arch_reg <= decode_packet.rd_s;
            cdb_output_mul.regf_we <= 1'b0;
            cdb_output_mul.address_br <= 'x;

            // RVFI
            rvfi_mul_fu.inst <= decode_packet.inst;
            rvfi_mul_fu.pc <= decode_packet.pc;
            rvfi_mul_fu.pc_next <= decode_packet.pc + 'd4;
            rvfi_mul_fu.rs1_s <= decode_packet.rs1_s;
            rvfi_mul_fu.rs2_s <= decode_packet.rs2_s;
            rvfi_mul_fu.rd_s <= decode_packet.rd_s;

            rvfi_mul_fu.rs1_rdata <= inst_a;
            rvfi_mul_fu.rs2_rdata <= inst_b;
            rvfi_mul_fu.order <= decode_packet.order;   

            rvfi_mul_fu.mem_addr <= 'x;
            rvfi_mul_fu.mem_rmask <= '0;
            rvfi_mul_fu.mem_wmask <= '0;
            rvfi_mul_fu.mem_rdata <= 'x;
            rvfi_mul_fu.mem_wdata <= '0;                     
        end
        else if (counter == 2'b10 && !invalid_dfp_flush) begin
            cdb_output_mul.regf_we <= 1'b1;
            cdb_output_mul.result <= upper_bits ? product_inst[inst_a_width + inst_b_width-3 : 32] : product_inst[inst_a_width - 2: 0];    

            // RVFI
            rvfi_mul_fu.rd_wdata <= upper_bits ? product_inst[inst_a_width + inst_b_width-3 : 32] : product_inst[inst_a_width - 2: 0];
        end
        else begin
            cdb_output_mul.regf_we <= 1'b0;
        end
    end


    // Instance of DW_mult_pipe  
    DW_mult_pipe #(inst_a_width, inst_b_width, inst_num_stages,                 
    inst_stall_mode, inst_rst_mode, inst_op_iso_mode
    )     
    U1 (.clk(inst_clk),   .rst_n(inst_rst_n),   .en(inst_en),        .tc(input_tc),   .a(input_a),   .b(input_b),         .product(product_inst) );
endmodule
