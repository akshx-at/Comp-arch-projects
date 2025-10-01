module arbiter_b_predictor_2_lvl 
import rv32i_types::*;
#(
    parameter LHT_LENGTH = 6,    
    parameter PHT_LENGTH = 4     
)
(
    input logic clk, 
    input logic rst,

    // Read
    input logic read,
    input logic [31:0] pc,
    output logic rresp,
    output predictor_t prediction,

    // Write
    input logic write,
    input predictor_t wdata,
    output logic wresp,

    // LHT
    output logic [LHT_LENGTH-1:0] lht_index,
    input logic [PHT_LENGTH-1:0] lht_history,
    output logic [PHT_LENGTH-1:0] write_lht_history,
    output logic lht_web,

    // PHT
    output logic [PHT_LENGTH-1:0] pht_index,
    input logic [1:0] pht_counter,
    output logic [1:0] write_pht_counter,
    output logic pht_web,

    // Valid LHT
    input logic valid_lht,
    output logic write_valid_lht,

    // Valid PHT
    input logic valid_pht,
    output logic write_valid_pht,

    output arbiter_pred_t state,

    input flush
);


    // typedef enum logic [1:0] {
    //     IDLE = 2'b00,
    //     READ_LHT = 2'b01,
    //     READ_PHT = 2'b10,
    //     WRITE = 2'b11
    // } arbiter_pred_t;

    // arbiter_pred_t state;

    logic read_done_flag;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            read_done_flag <= 1'b0;
            // valid_lht_reg <= 1'b0;
        end else begin
            read_done_flag <= 1'b0;
            unique case (state)
                IDLE: state <= write ? WRITE : (read ? READ_LHT : IDLE);
                WRITE: state <= IDLE;
                READ_LHT : state <= flush ? IDLE : READ_PHT;
                READ_PHT : begin 
                    // state <= write ? WRITE : (read ? READ_LHT : IDLE);
                    if (flush) begin
                        state <= IDLE;
                    end else begin
                        // state <= (write) ? WRITE : IDLE;
                        state <= IDLE;
                        read_done_flag <= valid_lht ? 1'b1 : 1'b0;
                        // valid_lht_reg <= valid_lht ? 1'b1 : 1'b0;
                    end
                end
            endcase
        end
    end

    always_comb begin
        rresp = 1'b0;
        prediction = 'x;
        wresp = 1'b0;

        lht_index = 'x;
        write_lht_history = 'x;
        lht_web = 1'b1; // active low

        pht_index = 'x;
        write_pht_counter = 'x;
        pht_web = 1'b1; // active low

        write_valid_lht = 1'b1;
        write_valid_pht = 1'b1;

        if (read_done_flag) begin
            rresp = 1'b1;
            prediction.lht_index = pc[LHT_LENGTH + 1: 2];
            prediction.pht_index = lht_history;    

            lht_web = 1'b0;
            // write_valid_lht = 1'b0;
            lht_index = pc[LHT_LENGTH + 1: 2];                    
            if (valid_pht) begin
                prediction.b_counter = pht_counter;
                write_lht_history = {lht_history[PHT_LENGTH-2:0], pht_counter[1]};
            end else begin
                prediction.b_counter = 2'b11;     
                write_lht_history = {lht_history[PHT_LENGTH-2:0], 1'b1};    
                // write_lht_history = {lht_history[PHT_LENGTH-2:0], 1'b0};          
            end
        end

        case (state)
            WRITE : begin
                wresp = 1'b1;

                if (flush) begin
                    lht_web = 1'b0;
                    lht_index = wdata.lht_index;
                    write_lht_history = {wdata.pht_index[PHT_LENGTH-2:0], wdata.b_counter[1]};
                    write_valid_lht = 1'b0;
                end

                pht_web = 1'b0;
                pht_index = wdata.pht_index;
                write_pht_counter = wdata.b_counter;
                write_valid_pht = 1'b0;
            end

            READ_LHT : begin
                lht_index = pc[LHT_LENGTH + 1: 2];
            end

            READ_PHT : begin
                lht_index = pc[LHT_LENGTH + 1: 2];
                if (!valid_lht) begin
                    rresp = 1'b1;
                    prediction.lht_index = pc[LHT_LENGTH + 1: 2];
                    prediction.pht_index = {PHT_LENGTH{1'b1}};
                    // prediction.pht_index = '0;
                    prediction.b_counter = 2'b11;

                    lht_web = 1'b0;
                    write_valid_lht = 1'b0;
                    lht_index = pc[LHT_LENGTH + 1: 2];
                    write_lht_history = {PHT_LENGTH{1'b1}};
                    // write_lht_history = '0;
                end else begin
                    pht_index = lht_history;
                end

            end
        endcase

    
    end



endmodule