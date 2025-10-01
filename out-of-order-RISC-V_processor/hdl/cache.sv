module cache 
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);

    logic [3:0] web;
    logic web_lru2;
    logic csb;

    logic [3:0] dselect;

    logic [3:0] addr;
    logic [3:0] addr_next;
    logic [3:0] lru_addr;
    logic [3:0] lru_addr2;

    logic [3:0] rmask;
    logic [31:0] wmask;
    logic [3:0] rmask_next;
    logic [3:0] wmask_next;

    logic din_valid;
    
    logic valid_return_from_cache [4];
    logic [255:0] data_return_from_cache [4];
    logic [23:0] tag_return_from_cache [4];
    logic [2:0] lru_return_from_cache;
    logic [2:0] lru_return_from_cache2;

    logic [255:0] data_din;
    logic [23:0] tag_din;
    logic valid_din;
    logic [2:0] lru_in;

    logic stall;

    pipeline_reg_t pipeline_reg, pipeline_reg_next;

    logic [31:0] data_read;

    logic clean_bit;
    logic valid_bit;
    // logic dirty_data_stored;
    fsm_bhai_t cache_state, cache_state_next;
    
    logic [1:0] evict_index;

    logic write_stall, write_stall_next;


    assign addr_next = ufp_addr[8:5];
    assign rmask_next = ufp_rmask;
    assign wmask_next = ufp_wmask;

    always_comb begin : pipeline_reg_next_state
        if (rst) begin
            pipeline_reg_next.addr_reg = 'x;
            pipeline_reg_next.rmask_reg = '0;
            pipeline_reg_next.wmask_reg = '0;
            pipeline_reg_next.wdata_reg = 'x;
            pipeline_reg_next.tag_reg = 'x;
            pipeline_reg_next.offset_reg = 'x;
            pipeline_reg_next.commit_reg = 1'b0;
        end
        else begin
            pipeline_reg_next.addr_reg = ufp_addr[8:5];
            pipeline_reg_next.rmask_reg = ufp_rmask;
            pipeline_reg_next.wmask_reg = ufp_wmask;
            pipeline_reg_next.wdata_reg = ufp_wdata;
            pipeline_reg_next.tag_reg = ufp_addr[31:9];
            pipeline_reg_next.offset_reg = ufp_addr[4:0];
            // pipeline_reg_next.commit_reg = (|ufp_rmask || |ufp_wmask);
            if ((ufp_rmask == '0) && (ufp_wmask == '0)) begin
                pipeline_reg_next.commit_reg = 1'b0;
            end
            else begin 
                pipeline_reg_next.commit_reg = 1'b1;
            end
        end
    end : pipeline_reg_next_state

    always_ff @(posedge clk) begin : pipeline_reg_transition
        if (rst) begin
            pipeline_reg.addr_reg <= 'x;
            pipeline_reg.rmask_reg <= '0;
            pipeline_reg.wmask_reg <= '0;
            pipeline_reg.wdata_reg <= 'x;
            pipeline_reg.tag_reg <= 'x;
            pipeline_reg.offset_reg <= 'x;
            pipeline_reg.commit_reg <= 1'b0;
        end
        else if (stall || write_stall) begin
            pipeline_reg <= pipeline_reg;
        end
        else begin
            pipeline_reg <= pipeline_reg_next;
        end
    end : pipeline_reg_transition

    logic tmp;


    always_ff @(posedge clk) begin :fsm_for_dfp_read
        if (rst) begin
            tmp <= 1'b1;
        end
        else if (stall) begin
            if(dfp_resp) begin
                tmp <= 1'b0;
            end
            else begin
                tmp <= 1'b1;
            end
        end
    end : fsm_for_dfp_read

    always_comb begin : fsm_for_dirty_clean
        clean_bit = 'x;
        // evict_index = 'x;
        cache_state_next = cache_state;
        unique case(cache_state)
            idle: begin
                if (stall) begin
                    casez(lru_return_from_cache)
                        3'b00?: begin 
                            clean_bit = tag_return_from_cache[3][23];
                            valid_bit = valid_return_from_cache[3];
                            // evict_index = 2'd3;
                        end
                        3'b01?: begin 
                            clean_bit = tag_return_from_cache[2][23];
                            valid_bit = valid_return_from_cache[2];
                            // evict_index = 2'd2;
                        end
                        3'b1?0: begin 
                            clean_bit = tag_return_from_cache[1][23];
                            valid_bit = valid_return_from_cache[1];
                            // evict_index = 2'd1;
                        end
                        3'b1?1: begin 
                            clean_bit = tag_return_from_cache[0][23];
                            valid_bit = valid_return_from_cache[0];
                            // evict_index = 2'd0;
                        end
                        default: begin 
                            clean_bit = tag_return_from_cache[3][23];
                            valid_bit = valid_return_from_cache[3];
                            // evict_index = 2'd3;
                        end
                    endcase

                    if (!valid_bit || clean_bit) begin
                        cache_state_next = clean_miss;
                    end
                    else begin
                        cache_state_next = dirty_miss;
                    end
                end
            end
            clean_miss: begin
                if (!stall) begin
                    cache_state_next = idle;
                end
            end
            dirty_miss: begin
                if(!tmp) begin
                    cache_state_next = clean_miss;
                end
                // if (dfp_resp) begin
                //     cache_state_next = clean_miss;
                // end
            end
            default: cache_state_next = idle;
        endcase
    end : fsm_for_dirty_clean

    always_ff @(posedge clk) begin
        if (rst) begin
            cache_state <= idle;
        end
        else begin
            cache_state <= cache_state_next;
        end
    end


    always_comb begin : dfp_values
        // clean_bit = 'x;
        evict_index = 'x;


        unique case (cache_state_next)
            idle: begin
                dfp_addr = 'x;
                dfp_read = 1'b0;
                dfp_write = 1'b0;
                dfp_wdata = 'x;
            end
            clean_miss: begin
                dfp_addr = {pipeline_reg.tag_reg, pipeline_reg.addr_reg, 5'b0};

                if (tmp) begin
                    dfp_read = 1'b1;
                end
                else begin
                    if(cache_state == dirty_miss) begin
                        dfp_read = 1'b1;
                    end
                    else begin
                        dfp_read = 1'b0;
                    end
                end

                // mght need to change this in case of dirty shit
                dfp_write = 1'b0;
                dfp_wdata = 'x; 
            end
            dirty_miss: begin

                casez(lru_return_from_cache)
                    3'b00?: evict_index = 2'd3;
                    3'b01?: evict_index = 2'd2;
                    3'b1?0: evict_index = 2'd1;
                    3'b1?1: evict_index = 2'd0;
                    default: evict_index = 2'd3;
                endcase

                dfp_addr = {tag_return_from_cache[evict_index][22:0], pipeline_reg.addr_reg, 5'b0};
                dfp_read = 1'b0;
                // dfp_write = 1'b1;
                if (tmp) begin
                    dfp_write = 1'b1;
                end
                else begin
                    dfp_write = 1'b0;
                end
                dfp_wdata = data_return_from_cache[evict_index];
            end
            default: begin
                dfp_addr = 'x;
                dfp_read = 1'b0;
                dfp_write = 1'b0;
                dfp_wdata = 'x;
            end
        endcase
    end : dfp_values


    always_comb begin : Writes_into_arrays
        csb = 1'b0;
        write_stall_next = 1'b0;
        if (dfp_resp && (cache_state == clean_miss)) begin
            // web_lru = 1'b1;
            web_lru2 = 1'b1;
            lru_in = 'x;
            
            casez(lru_return_from_cache)
                3'b00?: web = 4'b0111;
                3'b01?: web = 4'b1011;
                3'b1?0: web = 4'b1101;
                3'b1?1: web = 4'b1110;
                default: web = 4'b1111;
            endcase
            // web = 4'b0111;

            wmask = '1;
            addr = pipeline_reg.addr_reg;
            
            lru_addr = pipeline_reg.addr_reg;
            lru_addr2 = pipeline_reg.addr_reg;

            data_din = dfp_rdata;
            tag_din = {1'b1, pipeline_reg.tag_reg};
            valid_din = 1'b1;
        end
        else if (stall) begin
            // this is the interim period between your miss and the response from memory
            web_lru2 = 1'b1; // deactivate web for LRU
            lru_in = 'x;
            web = 4'b1111; // deactivare web for valid, tag, data

            wmask = '0;
            addr = pipeline_reg.addr_reg;

            lru_addr = pipeline_reg.addr_reg;
            lru_addr2 = pipeline_reg.addr_reg;

            data_din = 'x;
            tag_din = 'x;
            valid_din = 'x;
        end
        // else if (write) begin
        // end
        else begin
            
            if (pipeline_reg.commit_reg) begin
                // Hit
                if (!write_stall) begin
                    web_lru2 = 1'b0;
                    lru_addr2 = pipeline_reg.addr_reg;
                    unique case(dselect)
                        4'b0001: lru_in = {1'b0,lru_return_from_cache[1],1'b0};
                        4'b0010: lru_in = {1'b0,lru_return_from_cache[1],1'b1};
                        4'b0100: lru_in = {1'b1,1'b0,lru_return_from_cache[0]};
                        4'b1000: lru_in = {1'b1,1'b1,lru_return_from_cache[0]};
                        default: lru_in = 3'b0;
                    endcase
                end
                else begin
                    web_lru2 = 1'b1;
                    lru_addr2 = pipeline_reg.addr_reg;
                    lru_in = 'x;
                end

                if (pipeline_reg.wmask_reg != 4'b0000) begin
                    // write
                 
                    // web = ~dselect;
                    // wmask = '0;
                    // wmask[pipeline_reg.offset_reg +: 4] = pipeline_reg.wmask_reg;
                    addr = pipeline_reg.addr_reg;
                    lru_addr = pipeline_reg.addr_reg;
                    // data_din = '0;
                    // data_din[(pipeline_reg.offset_reg * 8) +: 32] = pipeline_reg.wdata_reg;
                    // tag_din = {1'b0, pipeline_reg.tag_reg};
                    // valid_din = 1'b1;
                    // write_stall_next = 1'b1;

                    if (write_stall) begin
                        web = 4'b1111;
                        wmask = '0;
                        data_din = 'x;
                        tag_din = 'x;
                        valid_din = 'x;
                        write_stall_next = 1'b0;
                    end
                    else begin
                        web = ~dselect;
                        wmask = '0;
                        wmask[pipeline_reg.offset_reg +: 4] = pipeline_reg.wmask_reg;      
                        data_din = '0;
                        data_din[(pipeline_reg.offset_reg * 8) +: 32] = pipeline_reg.wdata_reg; 
                        tag_din = {1'b0, pipeline_reg.tag_reg};     
                        valid_din = 1'b1;    
                        write_stall_next = 1'b1;                                
                    end

                end
                else begin
                    // read
                    web = 4'b1111;
                    wmask = '0;
                    // addr = addr_next;
                    // lru_addr = addr_next;
                    data_din = 'x;    
                    tag_din = 'x;
                    valid_din = 'x;


                    if (write_stall) begin
                        // not a hit, point to new stored values
                        addr = pipeline_reg.addr_reg;
                        lru_addr = pipeline_reg.addr_reg;
                    end
                    else begin
                        // actual hit, point to new input
                        addr = addr_next;
                        lru_addr = addr_next;                        
                    end                    
                end

            end
            else begin
                // NOP
                web_lru2 = 1'b1;
                lru_addr2 = pipeline_reg.addr_reg;
                lru_in = 'x;

                web = 4'b1111;
                wmask = '0;
                addr = addr_next;
                lru_addr = addr_next;
                data_din = 'x;    
                tag_din = 'x;
                valid_din = 'x;
            end
            
        end
    end : Writes_into_arrays

    always_ff @(posedge clk) begin
        if (rst) begin
            write_stall <= 1'b0;
        end
        else begin
            write_stall <= write_stall_next;
        end
    end

    always_comb begin
        if (stall) begin
            ufp_resp = '0;
            ufp_rdata = 'x;
        end
        else if (!pipeline_reg.commit_reg) begin
            ufp_resp = '0;
            ufp_rdata = 'x;
        end
        else begin
            if (write_stall) begin
                ufp_resp = 1'b0;
            end
            else begin
                ufp_resp = 1'b1;
            end

            if (pipeline_reg.wmask_reg == 4'b000) begin
                if(write_stall) begin
                    ufp_rdata = 'x;
                end
                else begin
                    ufp_rdata = data_read;
                end
            end
            else begin
                ufp_rdata = 'x;
            end
            // ufp_rdata = data_read;
        end
    end





    generate for (genvar i = 0; i < 4; i++) begin : arrays
        mp_cache_data_array data_array (
            .clk0       (clk),
            .csb0       (csb),
            .web0       (web[i:i]),
            .wmask0     (wmask),
            .addr0      (addr),
            .din0       (data_din),
            .dout0      (data_return_from_cache[i])
        );
        mp_cache_tag_array tag_array (
            .clk0       (clk),
            .csb0       (csb),
            .web0       (web[i]),
            .addr0      (addr),
            .din0       (tag_din),
            .dout0      (tag_return_from_cache[i])
        );
        valid_array valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (csb),
            .web0       (web[i]),
            .addr0      (addr),
            .din0       (valid_din),
            .dout0      (valid_return_from_cache[i])
        );
    end endgenerate

    lru_array lru_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (csb),
        .web0       (1'b1),
        .addr0      (lru_addr),
        .din0       ('x),
        .dout0      (lru_return_from_cache),
        .csb1       (csb),
        .web1       (web_lru2),
        .addr1      (lru_addr2),
        .din1       (lru_in),
        .dout1      (lru_return_from_cache2)
    );


    stage2 stage2_i (
        // .clk(clk),
        .valids(valid_return_from_cache),
        .tags(tag_return_from_cache),
        .datas(data_return_from_cache),
        .pipeline_reg(pipeline_reg),

        .stall(stall),
        .data_read(data_read),
        .dselect(dselect),
        .write_stall(write_stall)
    );

endmodule
