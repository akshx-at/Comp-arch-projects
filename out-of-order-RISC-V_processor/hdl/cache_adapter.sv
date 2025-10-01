module cache_adapter
import rv32i_types::*;
(

    input logic clk,
    input logic rst,

    // From I-cache -> cache adapter
    input logic [31:0] ufp_addr,
    input logic ufp_read,
    input logic ufp_write,
    input logic [255:0] ufp_wdata,

    // From cache adapter -> I-cache
    output logic [255:0] ufp_rdata,
    output logic ufp_resp,

    // From burst mem
    input logic [31:0] dfp_raddr,
    input logic dfp_ready,
    input logic dfp_rvalid,
    input logic [63:0] dfp_rdata,

    // To burst mem
    output logic [31:0] dfp_addr,
    output logic dfp_read,
    output logic dfp_write,
    output logic [63:0] dfp_wdata

);
    cache_adapter_t cache_state, cache_state_next;

    logic [2:0] burst_counter, burst_counter_next;

    logic [255:0] data_accumulator;

    // ---------- To deal with unused warning for now -------------//
    // logic [255:0] temp_ufp_wdata;
    logic [31:0] temp_dfp_raddr;
    // assign temp_ufp_wdata = ufp_wdata;
    assign temp_dfp_raddr = dfp_raddr;
    // -----------------------------------------------------------//

    always_ff @(posedge clk) begin
        if (rst) begin
            cache_state <= idle_cache;
            burst_counter <= '0;
            data_accumulator <= '0;
        end
        else begin
            cache_state <= cache_state_next;
            burst_counter <= burst_counter_next;

            if (cache_state == idle_cache) begin
                data_accumulator <= '0;
            end

            if (dfp_rvalid && ufp_read) begin
                data_accumulator[ ({29'(0),burst_counter}-1) * 64 +: 64] <= dfp_rdata;
            end
        end
    end


    always_comb begin
        cache_state_next = cache_state;
        unique case(cache_state)
            idle_cache: begin
                if(ufp_read || ufp_write) begin
                    cache_state_next = bursting;
                end
            end
            bursting: begin
                if ((burst_counter == 3'd3 && ufp_write) || (burst_counter == 3'd4 && ufp_read)) begin
                    cache_state_next = done;
                end
            end
            done: begin
                cache_state_next = idle_cache;
            end
            default: cache_state_next = idle_cache;
        endcase
    end


    always_comb begin
        unique case (cache_state)
            idle_cache: begin
                // To cache
                ufp_rdata = 'x;
                ufp_resp = 1'b0;


                // To burst mem
                dfp_addr = 'x;
                dfp_read = 1'b0;
                dfp_write = 1'b0;
                dfp_wdata = 'x;

                burst_counter_next = '0;
            end
            bursting: begin
                ufp_rdata = 'x;
                ufp_resp = '0;

                dfp_read = '0;
                dfp_write = '0;
                if (dfp_ready) begin
                    if (burst_counter == '0) begin
                        
                        if (ufp_read) begin
                            dfp_read = 1'b1;
                            dfp_wdata = 'x;
                        end
                        else begin
                            dfp_write = 1'b1;
                            dfp_wdata = ufp_wdata[({29'(0),burst_counter}) * 64 +: 64];
                        end
                        dfp_addr = ufp_addr;
                        burst_counter_next = 3'd1;

                        // For now only doing reads...need t cahnge when doing writes
                        // dfp_write = 1'b0;
                        // dfp_wdata = 'x;
                    end
                    else begin
                        dfp_read = 1'b0;
                        // dfp_addr = 'x;

                        if (ufp_read) begin
                            dfp_addr = 'x;
                            dfp_write = 1'b0;
                            dfp_wdata = 'x;
                        end else begin
                            dfp_addr = ufp_addr;
                            dfp_write = 1'b1;
                            dfp_wdata = ufp_wdata[({29'(0),burst_counter}) * 64 +: 64];
                        end
                        // For now only doing reads...need t cahnge when doing writes
                        // dfp_write = 1'b0;
                        // dfp_wdata = 'x;

                        burst_counter_next = dfp_rvalid || ufp_write ? burst_counter + 3'd1 : burst_counter;
                    end
                end
                else begin
                    dfp_read = 1'b1;
                    dfp_addr = ufp_addr;  

                    burst_counter_next = '0;      
                    
                    // For now only doing reads...need t cahnge when doing writes
                    dfp_write = 1'b0;
                    dfp_wdata = 'x;                                
                end
            end
            done: begin
                ufp_rdata = ufp_write ? 'x : data_accumulator;
                ufp_resp = 1'b1;            

                dfp_addr = 'x;
                dfp_read = '0;
                dfp_write = '0;
                dfp_wdata = 'x;

                burst_counter_next = '0;
            end
            default: begin
                ufp_rdata = 'x;
                ufp_resp = '0;

                dfp_addr = 'x;
                dfp_read = '0;
                dfp_write = '0;
                dfp_wdata = 'x;

                burst_counter_next = '0;                
            end
        endcase
    end

endmodule : cache_adapter
