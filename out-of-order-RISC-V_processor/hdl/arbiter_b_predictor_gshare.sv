module arbiter_b_predictor_gshare 
import rv32i_types::*;
#(
    parameter GHR_LENGTH = 6  
)
(
    input clk,
    input rst,

    // Read
    input logic read,
    input logic [31:0] pc,
    output logic rresp_gshare,
    output predictor_gshare_t prediction_gshare,
    // input logic rresp_2_lvl,

    // Write
    input logic write,
    input predictor_gshare_t wdata_gshare,
    output logic wresp_gshare,

    // GHR
    // output logic [GHR_LENGTH-1:0] wdata_ghr_history,
    // output logic ghr_write,

    // PHT
    output logic [GHR_LENGTH-1:0] pht_index_gshare,
    input logic [1:0] pht_counter_gshare,
    output logic [1:0] wdata_pht_counter_gshare,
    output logic pht_web_gshare,

    input logic valid_pht_gshare,
    output logic write_valid_pht_gshare,

    input flush,
    input arbiter_pred_t state_2lvl        
);

    typedef enum logic [1:0] {
        IDLE,
        READ,
        WRITE
    } arbiter_pred_gshare_t;    

    arbiter_pred_gshare_t state;
    logic read_done_flag;

    logic [GHR_LENGTH-1:0] ghr;
    logic [GHR_LENGTH-1:0] wdata_ghr_history;
    logic ghr_write;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            read_done_flag <= 1'b0;
        end
        else begin
            case (state)
                IDLE : begin 
                    state <= write ? WRITE : (read && !flush ? READ : IDLE);
                    read_done_flag <= 1'b0;
                end
                READ : begin 
                    if (!flush) begin
                        // state <= rresp_2_lvl ? (write ? WRITE : IDLE) : READ;
                        state <= (state_2lvl == 2'b10) ? IDLE : READ;
                        read_done_flag <= (state_2lvl == 2'b10) ? 1'b1 : 1'b0;
                    end else begin
                        state <= IDLE;
                        read_done_flag <= 1'b0;
                    end
                end
                WRITE : state <= IDLE; 
            endcase
        end
    end

    always_comb begin
        rresp_gshare = 1'b0;
        prediction_gshare = 'x;

        wresp_gshare = 1'b0;
        write_valid_pht_gshare = 1'b1;

        // read_ghr = 1'b0;
        wdata_ghr_history = 'x;
        ghr_write = 1'b1; // Active Low

        pht_index_gshare = 'x;
        wdata_pht_counter_gshare = 'x;
        
        pht_web_gshare = 1'b1; // Active Low

        case (state)
            IDLE : begin
                if (read_done_flag) begin
                    prediction_gshare.pht_index = ghr ^ pc[GHR_LENGTH + 1:2];
                    prediction_gshare.ghr = ghr;
                    prediction_gshare.b_counter_gshare = pht_counter_gshare;
                    prediction_gshare.pc = pc;
                    rresp_gshare = 1'b1;
                    if (valid_pht_gshare) begin
                        prediction_gshare.b_counter_gshare = pht_counter_gshare;
                        // write_lht_history = {lht_history[PHT_LENGTH-2:0], pht_counter[1]};
                        if (state_2lvl == 2'b10) begin
                            ghr_write = 1'b0;
                            wdata_ghr_history = {ghr[GHR_LENGTH-2:0], pht_counter_gshare[1]};
                        end                        
                    end else begin
                        prediction_gshare.b_counter_gshare = 2'b00;     
                        if (state_2lvl == 2'b10) begin
                            ghr_write = 1'b0;
                            wdata_ghr_history = {ghr[GHR_LENGTH-2:0], 1'b0};       
                        end  
                    end
                end               
            end
            READ : begin
                pht_index_gshare = ghr ^ pc[GHR_LENGTH + 1:2];

                // if (state_2lvl == 2'b10 && !flush) begin
                //     prediction_gshare.ghr = ghr;
                //     prediction_gshare.pht_index = pht_index_gshare;
                //     prediction_gshare.b_counter_gshare = pht_counter_gshare;
                //     prediction_gshare.pc = pc;
                //     rresp_gshare = 1'b1;

                //     if (valid_pht_gshare) begin
                //         prediction_gshare.b_counter_gshare = pht_counter_gshare;
                //         // write_lht_history = {lht_history[PHT_LENGTH-2:0], pht_counter[1]};
                //         if (state_2lvl == 2'b10) begin
                //             ghr_write = 1'b0;
                //             wdata_ghr_history = {ghr[GHR_LENGTH-2:0], pht_counter_gshare[1]};
                //         end                        
                //     end else begin
                //         prediction_gshare.b_counter_gshare = 2'b00;     
                //         if (state_2lvl == 2'b10) begin
                //             ghr_write = 1'b0;
                //             wdata_ghr_history = {ghr[GHR_LENGTH-2:0], 1'b0};       
                //         end 
                //     // if (rresp_2_lvl) begin
                //     //     ghr_write = 1'b0;
                //     //     wdata_ghr_history = {ghr[GHR_LENGTH-2:0], pht_counter_gshare[1]};
                //     // end
                //     end
                // end
            end
            WRITE : begin
                wresp_gshare = 1'b1;

                if (flush) begin
                    ghr_write = 1'b0;
                    wdata_ghr_history = {wdata_gshare.ghr[GHR_LENGTH-2:0], wdata_gshare.b_counter_gshare[1]};
                end

                pht_web_gshare = 1'b0;
                pht_index_gshare = wdata_gshare.pht_index;
                wdata_pht_counter_gshare = wdata_gshare.b_counter_gshare;
                write_valid_pht_gshare = 1'b0;
            end
        endcase
    end


    always_ff @(posedge clk) begin
        if (rst) begin
            ghr <= '1;
        end else begin
            if (!ghr_write) begin
                ghr <= wdata_ghr_history;
            end
        end
    end


endmodule