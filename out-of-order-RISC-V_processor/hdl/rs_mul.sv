module rs_mul
import rv32i_types::*;
#(
    parameter RES_MUL_ENTRIES = 5,      // Width of data bus
    parameter QUEUE_DEPTH_ROB = 16
)
(
    input logic clk,
    input logic rst,    
    // For Rename/Dispatch
    input reservation_station_t res_entry_in,
    input logic rendisp_regf_we,

    output logic rs_mul_full,

    // For CDB
    input cdb_t cdb_in_add, cdb_in_mul, cdb_in_div, cdb_in_ls,

    //output to send to physical reg file
    output logic [5:0] ps1_mul_tosend_tophyreg, ps2_mul_tosend_tophyreg,
    // output logic [31:0] imm_rs2_val
    output id_ex_stage_reg_t decode_packet_from_mul_rs,
    output logic [$clog2(QUEUE_DEPTH_ROB)-1:0] rob_entry_from_mul_rs,
    output logic [5:0] pd_from_mul_rs,
    output logic activate_mul,

    input logic [1:0] counter,

    input logic flush
);

    localparam  RES_ENTRIES_BITS = $clog2(RES_MUL_ENTRIES);
    reservation_station_t res_array [RES_MUL_ENTRIES];
    logic busy [RES_MUL_ENTRIES];

    reservation_station_t res_entry_next;
    logic busy_next;
    logic [RES_ENTRIES_BITS-1:0] index_next;

    logic [RES_ENTRIES_BITS-1:0] remove_idx;

    always_comb begin
        rs_mul_full = 1'b1;
        for (int i = 0; i < RES_MUL_ENTRIES; i++) begin
            if (busy[i] == '0) rs_mul_full = 1'b0;
        end
    end

    always_comb begin
        res_entry_next = 'x;
        busy_next = 'x;
        index_next = 'x;        
        for (int unsigned i = 0; i < RES_MUL_ENTRIES; i++) begin
            if (busy[i] == 0) begin
                res_entry_next = res_entry_in;
                busy_next = 1'b1;
                // index_next = i[RES_ENTRIES_BITS-1:0];
                index_next = 3'(i);
                break;
            end
        end
    end

    always_comb begin 
        ps2_mul_tosend_tophyreg = '0;
        ps1_mul_tosend_tophyreg = '0;
        decode_packet_from_mul_rs = '0;
        activate_mul = '0;
        remove_idx = '0;
        rob_entry_from_mul_rs = '0;
        pd_from_mul_rs = '0;
        for (int unsigned i = 0; i < RES_MUL_ENTRIES; i++) begin
            if ((counter == '0) && busy[i] && res_array[i].ps1_v_res && res_array[i].ps2_v_res && !flush) begin
                ps2_mul_tosend_tophyreg = res_array[i].ps2_res;
                ps1_mul_tosend_tophyreg = res_array[i].ps1_res;
                decode_packet_from_mul_rs = res_array[i].decode_packet;
                rob_entry_from_mul_rs = res_array[i].rob_entry_res;
                pd_from_mul_rs = res_array[i].pd_res;
                activate_mul = 1'b1;
                // remove_idx = i[RES_ENTRIES_BITS-1:0];
                remove_idx = 3'(i);
                break;
                // so if that specific station has value and the opeartion that we are executing for does not immediate value, then we get the data value from regfile
                end
        end
    end


    always_ff @(posedge clk) begin
        if (rst || flush) begin
            for (int i = 0; i < RES_MUL_ENTRIES; i++) begin
                res_array[i] <= 'x;
                busy[i] <= 1'b0;
            end
        end
        // we are waking the reservation stations up here, to solve dependencies
        else begin
            if (cdb_in_add.phys_reg != '0 && cdb_in_add.regf_we) begin
                for (int i = 0; i < RES_MUL_ENTRIES; i++) begin
                    if ((cdb_in_add.phys_reg == res_array[i].ps1_res) && busy[i]) begin
                        res_array[i].ps1_v_res <= 1'b1;
                    end

                    if ((cdb_in_add.phys_reg == res_array[i].ps2_res) && busy[i]) begin
                        res_array[i].ps2_v_res <= 1'b1;
                    end
                end
            end

            if (cdb_in_mul.phys_reg != '0 && cdb_in_mul.regf_we) begin
                for (int i = 0; i < RES_MUL_ENTRIES; i++) begin
                    if ((cdb_in_mul.phys_reg == res_array[i].ps1_res) && busy[i]) begin
                        res_array[i].ps1_v_res <= 1'b1;
                    end

                    if ((cdb_in_mul.phys_reg == res_array[i].ps2_res) && busy[i]) begin
                        res_array[i].ps2_v_res <= 1'b1;
                    end
                end
            end

            if (cdb_in_div.phys_reg != '0 && cdb_in_div.regf_we) begin
                for (int i = 0; i < RES_MUL_ENTRIES; i++) begin
                    if ((cdb_in_div.phys_reg == res_array[i].ps1_res) && busy[i]) begin
                        res_array[i].ps1_v_res <= 1'b1;
                    end

                    if ((cdb_in_div.phys_reg == res_array[i].ps2_res) && busy[i]) begin
                        res_array[i].ps2_v_res <= 1'b1;
                    end
                end
            end           

            if (cdb_in_ls.phys_reg != '0 && cdb_in_ls.regf_we) begin
                for (int i = 0; i < RES_MUL_ENTRIES; i++) begin
                    if ((cdb_in_ls.phys_reg == res_array[i].ps1_res) && busy[i]) begin
                        res_array[i].ps1_v_res <= 1'b1;
                    end

                    if ((cdb_in_ls.phys_reg == res_array[i].ps2_res) && busy[i]) begin
                        res_array[i].ps2_v_res <= 1'b1;
                    end
                end
            end  
            
            // Write from Rename/Dispatch
            if (rendisp_regf_we) begin
                res_array[index_next] <= res_entry_next;
                busy[index_next] <= busy_next;
            end

            if (activate_mul) busy[remove_idx] <= 1'b0;
        end
    end




endmodule : rs_mul
