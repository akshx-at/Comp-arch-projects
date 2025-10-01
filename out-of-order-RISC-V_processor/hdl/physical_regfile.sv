module physical_regfile
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    
    input   logic   [5:0]   ps1_add, ps2_add,
    input   logic   [5:0]   ps1_mul, ps2_mul,
    input   logic   [5:0]   ps1_div, ps2_div,

    input   logic   [5:0]   ps1_ls, ps2_ls,
    input cdb_t cdb_in_add, cdb_in_mul, cdb_in_div, cdb_in_ls,
    output  logic   [31:0]  ps1_value_add, ps2_value_add, ps1_value_mul, ps2_value_mul, ps1_value_div, ps2_value_div,
    output logic [31:0] ps1_value_ls, ps2_value_ls
);

    logic   [31:0]  data [64];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 64; i++) begin
                data[i] <= '0;
            end
        end else begin 
            // Add CDB
            if (cdb_in_add.regf_we && (cdb_in_add.phys_reg != '0)) begin
                data[cdb_in_add.phys_reg] <= cdb_in_add.result;
            end

            // Mul CDB
            if (cdb_in_mul.regf_we && (cdb_in_mul.phys_reg != '0)) begin
                data[cdb_in_mul.phys_reg] <= cdb_in_mul.result;
            end

            if (cdb_in_div.regf_we && (cdb_in_div.phys_reg != '0)) begin
                data[cdb_in_div.phys_reg] <= cdb_in_div.result;
            end

            if (cdb_in_ls.regf_we && (cdb_in_ls.phys_reg != '0)) begin // over here we need to make sure we are only doing this fro loads and not stores
                data[cdb_in_ls.phys_reg] <= cdb_in_ls.result;
            end
        end
    end

    always_comb begin
        if (rst) begin
            ps1_value_add = 'x;
            ps2_value_add = 'x;

            ps1_value_mul = 'x;
            ps2_value_mul = 'x;    

            ps1_value_div = 'x;
            ps2_value_div = 'x;  

            ps1_value_ls = 'x;
            ps2_value_ls = 'x;
        end else begin
            // No need for forwarding logic since it takes 1 cycle for valid to get set in Res Station
            // if (cdb_in.phys_reg == ps1_add) ps1_value = (ps1_add != '0) ? cdb_in.result : '0;
            // else ps1_value = (ps1_add != '0) ? data[ps1_add] : '0;
            ps1_value_add = (ps1_add != '0) ? data[ps1_add] : '0;
            ps1_value_mul = (ps1_mul != '0) ? data[ps1_mul] : '0;
            ps1_value_div = (ps1_div != '0) ? data[ps1_div] : '0;
            ps1_value_ls = (ps1_ls != '0) ? data[ps1_ls] : '0;

            // if (cdb_in.phys_reg == ps2_add) ps2_value = (ps2_add != '0) ? cdb_in.result : '0;
            // else ps2_value = (ps2_add != '0) ? data[ps2_add] : '0; 
            ps2_value_add = (ps2_add != '0) ? data[ps2_add] : '0;
            ps2_value_mul = (ps2_mul != '0) ? data[ps2_mul] : '0;
            ps2_value_div = (ps2_div != '0) ? data[ps2_div] : '0;
            ps2_value_ls = (ps2_ls != '0) ? data[ps2_ls] : '0;
        end
    end

endmodule : physical_regfile
