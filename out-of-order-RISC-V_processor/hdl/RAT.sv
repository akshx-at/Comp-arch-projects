module RAT 
import rv32i_types::*;
(
    // From rename dispatch
    input logic clk,
    input logic rst,

    input logic [4:0] rd,
    input logic [5:0] pd,
    input logic regf_we,

    input logic [4:0] rs1,
    output logic [5:0] ps1,
    output logic ps1_valid,

    input logic [4:0] rs2,
    output logic [5:0] ps2,
    output logic ps2_valid,

    // From CDB
    input cdb_t cdb_in_add, cdb_in_mul, cdb_in_div, cdb_in_ls,

    input logic flush,

    input logic [5:0]  data_flush [32]
    // input logic [4:0] rd_rob_head,
    // input logic [5:0] pd_rob_head,

    // input logic delay_flush

);

    logic   [6:0]  data [32];

    // logic   [4:0] change;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int unsigned i = 0; i < 32; i++) begin
                data[i][6] <= 1'b1;
                data[i][5:0] <= 6'(i);
                // data[i][5:0] <= flush ? data_flush[i] : 6'(i);
            end
        end else if (flush) begin
            for (int unsigned i = 0; i < 32; i++) begin
                data[i][6] <= 1'b1;
                data[i][5:0] <= data_flush[i];
                // data[i][5:0] <= i[5:0];
                // if (rd_rob_head != 5'(i)) begin
                //     data[i][5:0] <= data_flush[i];
                // end
                // data[i][5:0] <= (5'(i) != rd_rob_head) ? data_flush[i] : data[i][5:0];
            end 

            // if (rd_rob_head != '0) data[rd_rob_head][5:0] <= pd_rob_head;           
        end else begin 
            
            if (cdb_in_add.regf_we && (cdb_in_add.arch_reg != 5'd0) && (cdb_in_add.phys_reg == data[cdb_in_add.arch_reg][5:0])) begin
                data[cdb_in_add.arch_reg][6] <= 1'b1;
            end

            if (cdb_in_mul.regf_we && (cdb_in_mul.arch_reg != 5'd0) && (cdb_in_mul.phys_reg == data[cdb_in_mul.arch_reg][5:0])) begin
                data[cdb_in_mul.arch_reg][6] <= 1'b1;
            end 

            if (cdb_in_div.regf_we && (cdb_in_div.arch_reg != 5'd0) && (cdb_in_div.phys_reg == data[cdb_in_div.arch_reg][5:0])) begin
                data[cdb_in_div.arch_reg][6] <= 1'b1;
            end 

            if (cdb_in_ls.regf_we && (cdb_in_ls.arch_reg != 5'd0) && (cdb_in_ls.phys_reg == data[cdb_in_ls.arch_reg][5:0])) begin
                data[cdb_in_ls.arch_reg][6] <= 1'b1;
            end 

            if (regf_we && (rd != 5'd0)) begin
                data[rd] <= {1'b0, pd};
            end           
        end
    end


    always_comb begin
        if (rst) begin
            ps1 = '0;
            ps1_valid = 1'b0;
        end 
        else if (rs1 != 5'd0) begin
            ps1 = data[rs1][5:0];
            if (cdb_in_add.regf_we && (rs1 == cdb_in_add.arch_reg) && (cdb_in_add.phys_reg == data[cdb_in_add.arch_reg][5:0])) begin
                ps1_valid = 1'b1;
            end
            else if (cdb_in_mul.regf_we && (rs1 == cdb_in_mul.arch_reg) && (cdb_in_mul.phys_reg == data[cdb_in_mul.arch_reg][5:0])) begin
                ps1_valid = 1'b1;
            end
            else if (cdb_in_div.regf_we && (rs1 == cdb_in_div.arch_reg) && (cdb_in_div.phys_reg == data[cdb_in_div.arch_reg][5:0])) begin
                ps1_valid = 1'b1;
            end
            else if (cdb_in_ls.regf_we && (rs1 == cdb_in_ls.arch_reg) && (cdb_in_ls.phys_reg == data[cdb_in_ls.arch_reg][5:0])) begin
                ps1_valid = 1'b1;
            end
            else begin
                ps1_valid = data[rs1][6];
            end
        end
        else begin
            ps1 = '0;
            ps1_valid = 1'b1;
        end
    end

    always_comb begin
        if (rst) begin
            ps2 = '0;
            ps2_valid = 1'b0;
        end 
        else if (rs2 != 5'd0) begin
            ps2 = data[rs2][5:0];
            if (cdb_in_add.regf_we && (rs2 == cdb_in_add.arch_reg) && (cdb_in_add.phys_reg == data[cdb_in_add.arch_reg][5:0])) begin
                ps2_valid = 1'b1;
            end
            else if (cdb_in_mul.regf_we && (rs2 == cdb_in_mul.arch_reg) && (cdb_in_mul.phys_reg == data[cdb_in_mul.arch_reg][5:0])) begin
                ps2_valid = 1'b1;
            end
            else if (cdb_in_div.regf_we && (rs2 == cdb_in_div.arch_reg) && (cdb_in_div.phys_reg == data[cdb_in_div.arch_reg][5:0])) begin
                ps2_valid = 1'b1;
            end  
            else if (cdb_in_ls.regf_we && (rs2 == cdb_in_ls.arch_reg) && (cdb_in_ls.phys_reg == data[cdb_in_ls.arch_reg][5:0])) begin
                ps2_valid = 1'b1;
            end           
            else begin
                ps2_valid = data[rs2][6];
            end
        end
        else begin
            ps2 = '0;
            ps2_valid = 1'b1;
        end
    end

endmodule : RAT
