module arbiter_lsq_loads (
    input logic clk,
    input logic rst,

    // LSQ
    input logic [3:0] rmask_from_lsq,
    output logic lsq_resp,
    output logic [31:0] lsq_rdata,

    // D-Cache
    input logic mem_resp,
    output logic [3:0] rmask_to_dcache,
    input logic [31:0] mem_rdata,

    // PCSB
    output logic load,
    input logic [31:0] rdata_from_pcsb,
    input logic resp_from_pcsb, 
    input logic mask_loads,

    input logic flush,
    output logic invalid_dfp_flush,

    input mask_conflict

);

    typedef enum logic [1:0] {
        IDLE,
        READ_PCSB,
        READ_MEM
    } arbiter_lsq_loads_t;

    arbiter_lsq_loads_t state;

    // logic invalid_dfp_flush;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE : state <= (rmask_from_lsq == '0 || flush) ? IDLE : READ_PCSB;
                READ_PCSB: state <= (resp_from_pcsb || flush) ? IDLE : (mask_conflict ? READ_PCSB : READ_MEM);
                READ_MEM : state <= mask_loads ? (flush ? IDLE : READ_MEM) : ( (mem_resp && !invalid_dfp_flush) || flush ? IDLE : READ_MEM); 
            endcase
        end
    end

    // Edge case load flushing
    always_ff @(posedge clk) begin
        if (rst) begin
            invalid_dfp_flush <= 1'b0;
        end else if (flush && !mem_resp && (state == READ_MEM) && !mask_loads) begin
            invalid_dfp_flush <= 1'b1;
        end else if (mem_resp && invalid_dfp_flush) begin
            invalid_dfp_flush <= 1'b0;
        end
    end



    always_comb begin
        lsq_resp = '0;
        lsq_rdata = 'x;
        rmask_to_dcache = '0;
        load = 1'b0;

        case (state)
            IDLE : begin
                load = (rmask_from_lsq == '0) ? 1'b0 : 1'b1;
            end
            READ_PCSB : begin
                if (resp_from_pcsb && !flush) begin
                    lsq_resp = 1'b1;
                    lsq_rdata = rdata_from_pcsb;
                end else if (mask_conflict && !flush) begin
                    load = 1'b1;
                end
            end
            READ_MEM : begin
                if (!mask_loads) begin
                    if(!mem_resp) begin
                        rmask_to_dcache = rmask_from_lsq;
                    end else if (!invalid_dfp_flush) begin
                        lsq_resp = 1'b1;
                        lsq_rdata = mem_rdata;
                    end
                end
            end
        endcase
    end


endmodule