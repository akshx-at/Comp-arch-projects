module instr_prefetcher 
import rv32i_types::*;
#(
    parameter NUM_LINES = 1
)
(
    input logic clk,
    input logic rst,

    // From I-Cache
    input logic read,
    input logic [31:0] addr,

    // To I-Cache
    output logic resp,
    output logic [255:0] rdata,

    // To Memory (Arbiter)
    output logic [31:0] mem_addr,
    output logic mem_read,
    output logic mem_write, // should always be 0
    output logic [255:0] mem_wdata, // dont need
    input logic [255:0] mem_rdata,
    input logic mem_resp

    // // Prefetch SRAM
    // output logic prefetch_sram_web,
    // output logic [$clog2(NUM_LINES)-1:0] prefetch_sram_index,
    // output logic [255:0] wdata_prefetch_sram,
    // input logic [255:0] rdata_prefetch_sram
);


    typedef enum logic [1:0] {
        IDLE,
        READ,
        MISS,
        PRE_FETCH
    } prefetcher_state_t;

    prefetcher_state_t state;

    logic valid [NUM_LINES];
    logic [255:0] prefetch_lines_data [NUM_LINES];
    logic [26:0] prefetch_lines_addr [NUM_LINES];
    
    logic [26:0] addr_store;

    logic [$clog2(NUM_LINES):0] index;

    localparam WIDTH = ($clog2(NUM_LINES) > 0) ? $clog2(NUM_LINES) : 1;

// make sure to check what to do if you get read request
// during prefetching, i.e READ_MISS state

// for multiple prefetches - whnvr u hv a miss, u start ur pre-fetch chain
// at miss set counter to 0 and keep pre-fetching until counter reaches depth
// or until another read req comes (cache miss)

    // always_ff @(posedge clk) begin
    //     if (rst) begin
    //         for(int i = 0; i < NUM_LINES; i++) begin
    //             valid[i] <= 1'b0;
    //         end
    //     end else begin
            
    //     end
    // end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            addr_store <= 'x;
            index <= '0;
            for(int i = 0; i < NUM_LINES; i++) begin
                valid[i] <= 1'b0;
                prefetch_lines_addr[i] <= '0;
                prefetch_lines_data[i] <= 'x;
            end            
        end else begin
            case (state)
                IDLE : begin
                    if (read) begin 
                        addr_store <= addr[31:5];
                        state <= MISS;
                        for (int unsigned i = 0; i < NUM_LINES; i++) begin
                            if (valid[i] && prefetch_lines_addr[i] == addr[31:5]) begin
                                state <= READ;
                                // index <= i[$clog2(NUM_LINES):0];
                                index <= WIDTH'(i);
                                // state <= PRE_FETCH;
                                break;
                            end
                        end
                        // state <= MISS;
                    end
                    else state <= IDLE;
                end
                READ : state <= PRE_FETCH;
                MISS : state <= mem_resp ? PRE_FETCH : MISS;
                PRE_FETCH : begin 
                    if (mem_resp) begin
                        valid[0] <= 1'b1;
                        prefetch_lines_addr[0] <= addr_store + 27'd1;
                        prefetch_lines_data[0] <= mem_rdata;
                        
                        state <= IDLE;
                    end else begin
                        state <= PRE_FETCH;
                    end
                end
            endcase
        end
    end


    always_comb begin
        resp = '0;
        rdata = 'x;

        mem_addr = 'x;
        mem_read = '0;
        mem_write = '0;
        mem_wdata = 'x;

        // prefetch_sram_web = 1'b1; // active low
        // prefetch_sram_index = 'x;
        // wdata_prefetch_sram = 'x;

        case (state)
            IDLE : begin
                resp = '0;
                // if (read) begin 
                //     for (int i = 0; i < NUM_LINES; i++) begin
                //         if (valid[i] && prefetch_lines_addr[i] == addr[31:5]) begin
                //             // prefetch_sram_index = i;
                //             rdata = prefetch_lines_data[i];
                //             resp = 1'b1;
                //             break;
                //         end
                //     end
                // end                
            end
            READ : begin
                rdata = prefetch_lines_data[index];
                resp = 1'b1;
            end
            MISS : begin
                mem_addr = addr;
                mem_read = 1'b1;

                if (mem_resp) begin
                    rdata = mem_rdata;
                    resp = 1'b1;
                end
            end
            PRE_FETCH : begin
                mem_addr = {addr_store, 5'd0} + 32'd32;
                mem_read = 1'b1;

                // if (mem_resp) begin
                //     // If fetching more than 1 line,
                //     // will need to figure out which indx to write to

                //     // Write to FF
                //     // prefetch_sram_web = 1'b0;
                //     // prefetch_sram_index = 0;
                //     // wdata_prefetch_sram = mem_rdata;
                // end
            end
        endcase
    end

endmodule