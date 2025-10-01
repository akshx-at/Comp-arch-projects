module RRF (

    input logic clk,
    input logic rst,

    // From ROB
    // input logic regf_we,
    input logic [4:0]   rd,
    input logic [5:0]   pd,
    input logic commit_inst,

    // To Free List
    output logic [5:0]  old_pd_idx,
    output logic        enqueue_fl,

    output logic [5:0]  data_flush [32]

    // input logic flush,
    // output logic delay_flush
);

    logic   [5:0]  data [32];
    
    // logic delay_flush;

    // assign data_flush = data;
    always_comb begin
        data_flush = data;
        if (commit_inst && rd != '0) begin
            data_flush[rd] = pd;
        end
    end

    // always_ff @(posedge clk) begin
    //     if (rst) begin
    //         delay_flush <= 1'b0;
    //     end else if (flush) begin
    //         delay_flush <= 1'b1;
    //     end
    //     else begin
    //         delay_flush <= 1'b0;
    //     end
    // end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int unsigned i = 0; i < 32; i++) begin
                // data[i][5:0] <= i[5:0];
                data[i][5:0] <= 6'(i);
            end     
        end else if (commit_inst && rd != '0) begin
            data[rd] <= pd;
        end
    end

    always_comb begin
        if (rst) begin
            enqueue_fl = 1'b0;
            old_pd_idx = 'x;
        end
        else if (commit_inst && rd != '0) begin
            enqueue_fl = 1'b1;
            old_pd_idx = data[rd];
        end
        else begin
            enqueue_fl = 1'b0;
            old_pd_idx = 'x;
        end
    end


endmodule : RRF
