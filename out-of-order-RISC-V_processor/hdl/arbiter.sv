module arbiter
import rv32i_types::*;
(
    input logic clk,
    input logic rst,


    // To and From I-Cache

    input  logic    [31:0] instruction_dfp_addr,
    input  logic           instruction_dfp_read,
    input  logic           instruction_dfp_write,
    input  logic   [255:0] instruction_dfp_wdata,
    output  logic   [255:0] instruction_dfp_rdata,
    output  logic           instruction_dfp_resp,

    // To and From D-Cache
    input   logic   [31:0]  data_dfp_addr,
    input   logic           data_dfp_read,
    input   logic           data_dfp_write,
    output  logic   [255:0] data_dfp_rdata,
    input   logic   [255:0] data_dfp_wdata,
    output  logic           data_dfp_resp,


    // To and From Cache Adapter

    output  logic    [31:0] cacheadapter_dfp_addr,
    output  logic           cacheadapter_dfp_read,
    output  logic           cacheadapter_dfp_write,
    output  logic   [255:0] cacheadapter_dfp_wdata,
    input   logic   [255:0] cacheadapter_dfp_rdata,


    input logic cacheadapter_resp
);


    typedef enum logic [1:0] {
        IDLE,
        DCACHE_ACCESS,
        ICACHE_ACCESS
    } arbiter_t;

    arbiter_t arbiter_state, arbiter_state_next;

    // State Transition Logic
    always_ff @(posedge clk) begin
        if (rst) begin
            arbiter_state <= IDLE;
        end
        else begin
            arbiter_state <= arbiter_state_next;
        end
    end

    // Next State Logic
    always_comb begin
        arbiter_state_next = arbiter_state;
        
        // Default Outputs
        cacheadapter_dfp_addr = 32'b0;
        cacheadapter_dfp_read = 1'b0;
        cacheadapter_dfp_write = 1'b0;
        cacheadapter_dfp_wdata = 256'b0;
        instruction_dfp_rdata = 'x;
        instruction_dfp_resp = '0;
        data_dfp_rdata       = 'x;
        data_dfp_resp        = '0;

        case (arbiter_state)
            IDLE: begin
                if (data_dfp_read || data_dfp_write) begin
                    arbiter_state_next = DCACHE_ACCESS;
                end
                else if (instruction_dfp_read) begin
                    arbiter_state_next = ICACHE_ACCESS;
                end
            end

            DCACHE_ACCESS: begin
                // Route D-Cache signals to cache adapter
                cacheadapter_dfp_addr = data_dfp_addr;
                cacheadapter_dfp_read = data_dfp_read;
                cacheadapter_dfp_write = data_dfp_write;
                cacheadapter_dfp_wdata = data_dfp_wdata;
                data_dfp_rdata = cacheadapter_dfp_rdata;
                data_dfp_resp  = cacheadapter_resp;

                // Go back to IDLE after servicing D-Cache
                if (cacheadapter_resp) begin
                    arbiter_state_next = IDLE;
                end
            end

            ICACHE_ACCESS: begin
                // Route I-Cache signals to cache adapter
                cacheadapter_dfp_addr = instruction_dfp_addr;
                cacheadapter_dfp_read = instruction_dfp_read;
                cacheadapter_dfp_write = instruction_dfp_write;
                cacheadapter_dfp_wdata = instruction_dfp_wdata;
                instruction_dfp_rdata  = cacheadapter_dfp_rdata;
                instruction_dfp_resp  = cacheadapter_resp;

                // Go back to IDLE after servicing I-Cache
                if (cacheadapter_resp) begin
                    arbiter_state_next = IDLE;
                end
            end
        endcase
    end

endmodule : arbiter
    // so our instructio cache is read only
    // data cache is read and write, (we still use the same cache modle for oth of them)
    // so what we are controlling are not the cache storage bit raher the fact that how information is being intreacted with main memory,
    // these two individual caches will not interfere with each other, but once we need to make access to the main memory,
    // we will need to resolve that, we will probably give priority to the I-intruction cache,
    // then sent that, get the information from the memory, save that in the main I-cache, 
    // next send in the access for load and stores from that cache

