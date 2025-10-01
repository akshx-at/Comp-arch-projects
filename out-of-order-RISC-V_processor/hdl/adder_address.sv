module adder_address
import rv32i_types::*;
(
    input logic clk,
    input logic rst,

    input logic [31:0] ps1_executeval,
    input logic [31:0] ps2_executeval,
    
    input id_ex_stage_reg_t decode_packet,
    input logic activate_ls,

    output logic [31:0] output_addr_val,
    output logic lsq_wfe,
    output logic [31:0] ps2_val_to_lsq,
    output logic [31:0] ps1_val_to_lsq,

    input logic [2:0] lsq_entry_from_rs,
    output logic [2:0] lsq_entry_res
);

logic unsigned [31:0] address_val;


always_ff @(posedge clk) begin
    if(rst) begin   
        lsq_wfe <= 1'b0;
        output_addr_val <= 'x;
        ps2_val_to_lsq <= 'x;
        ps1_val_to_lsq <= 'x;
        lsq_entry_res <= 'x;
    end
    else if(activate_ls) begin
        lsq_wfe <= 1'b1;
        output_addr_val <= address_val;
        ps2_val_to_lsq <= ps2_executeval;
        ps1_val_to_lsq <= ps1_executeval;
        lsq_entry_res <= lsq_entry_from_rs;

    end else begin 
        lsq_wfe <= 1'b0;
        output_addr_val <= 'x;
        ps2_val_to_lsq <= 'x;
        ps1_val_to_lsq <= 'x;
        lsq_entry_res <= 'x;
    end
end

always_comb begin
    address_val = unsigned'(ps1_executeval) + unsigned'(decode_packet.imm_gen);
end

endmodule