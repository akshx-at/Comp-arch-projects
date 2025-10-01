module stage2 
import rv32i_types::*;
(
    // input   logic           clk,
    input logic valids [4],
    input logic [23:0] tags [4],
    input logic [255:0] datas [4],
    input pipeline_reg_t pipeline_reg,
    output logic stall,
    output logic [31:0] data_read,

    output logic [3:0] dselect,

    input logic write_stall
);

    // logic stall;

    // logic [3:0] dselect;
    logic hit;
    logic [255:0] data;

    always_comb begin
        if (!pipeline_reg.commit_reg || write_stall) begin
            stall = 1'b0;
            hit = 1'b0;
            data = 'x;
            data_read = 'x;
            dselect = 'x;
        end
        else begin
            for (int i = 0; i < 4; i++) begin
                dselect[i] = valids[i] && (pipeline_reg.tag_reg == tags[i][22:0]);
            end

            // dselect[0] = valids[0] && (pipeline_reg.tag_reg == tags[0][22:0]);
            // dselect[1] = valids[1] && (pipeline_reg.tag_reg == tags[1][22:0]);
            // dselect[2] = valids[2] && (pipeline_reg.tag_reg == tags[2][22:0]);
            // dselect[3] = valids[3] && (pipeline_reg.tag_reg == tags[3][22:0]);

            hit = dselect[0] | dselect [1] | dselect[2] | dselect[3];

            unique case(dselect)
                4'b0001: data = datas[0];
                4'b0010: data = datas[1];
                4'b0100: data = datas[2];
                4'b1000: data = datas[3];
                default: data = 'x;
            endcase

            data_read = data[(pipeline_reg.offset_reg * 8) +: 32];

            if (hit) begin
                stall = 1'b0;
            end
            else begin
                stall = 1'b1;
            end
        end
    end

endmodule
