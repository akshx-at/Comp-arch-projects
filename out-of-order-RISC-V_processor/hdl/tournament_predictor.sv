// module tournament_pred
// import rv32i_types::*;
// #(
//     parameter GHR_LENGTH = 6,
//     parameter LHT_LENGTH = 6,    
//     parameter PHT_LENGTH = 4,
//     parameter COUNTER_WIDTH = 2,
//     parameter CHOOSER_PHT_SIZE = 64
// )
// (
//     input clk,
//     input rst,

//     // common signals
//     input logic read,
//     input logic [31:0] pc,
//     input logic write,
//     input logic flush,

//     // gshare values
//     input logic rresp_gshare,
//     input predictor_gshare_t prediction_gshare,
//     input logic wresp_gshare,
//     input predictor_gshare_t wdata_gshare,
    
//     //2-lvl values
//     input predictor_t prediction,
//     input logic wresp_2lvl,
//     input logic rresp_2lvl,
//     input predictor_t wdata,

//     // outputs from CPHT
//     output logic final_prediction
// );

// logic branch_taken;
// logic [$clog2(CHOOSER_PHT_SIZE):0] chooser_index ; 
// logic gshare_correct;
// logic two_lvl_correct;

// //**** initialzing the register*****

// // Declare the CPHT as a register array
// reg [COUNTER_WIDTH-1:0] chooser_pht [CHOOSER_PHT_SIZE-1:0];

// // Initialize the CPHT on reset
// integer i;
// always_ff @(posedge clk) begin
//     if (rst) begin
//         // Initialize all counters to slightly favor 2-Level predictor (2'b10)
//         for (i=0; i<CHOOSER_PHT_SIZE; i++ ) begin
//             chooser_pht <= 2'b10;
//         end
//     // end else begin 
//     //     if(!cpht_write) begin
//     //         chooser_counter = chooser_pht[chooser_index]; 
//     //     end
//     end
// end
// // ****************done************


// // so a branch signal comes in, goes into both the predictors, they make their predictions
// // that comes in here , we look at the pc, parse the required index, look into the register, get the values
// // if value[1] == 1, give the 2 lvl values, else give the gshare value,

// // Compute CPHT Index
// // assign chooser_index = pc[$clog2(CHOOSER_PHT_SIZE)+1:2];
// // Determine Final Prediction
// assign chooser_counter = chooser_pht[chooser_index]; 
// always_comb begin
//     final_prediction = 'x;
//     chooser_index = 'x;
//     if(rresp_gshare && rresp_2lvl) begin
//         chooser_index = pc[$clog2(CHOOSER_PHT_SIZE)+1:2];
//         final_prediction = chooser_counter[1] ? prediction.b_counter[1] : prediction_gshare.b_counter_gshare[1];
//         prediction.final_prediction = final_prediction;
//     end
// end

// assign branch_taken = ~(wresp_gshare && flush); // if this is 1 that means we have taken the branch 

// // this tells us which prediction is correct

// // get the signal from rob if the it was correct prediction or incorrect prediction
// // feed that over here, compare that with values that had come from both the predictors

// assign gshare_correct = (wdata.final_prediction == wdata_gshare.b_counter_gshare[1]) ? 1'b1 : 1'b0 ;
// assign two_lvl_correct = (wdata.final_prediction == wdata.b_counter[1]) ? 1'b1 : 1'b0 ;

// // if both of them predict correct/incorrect, dont update the counter
// // otherwsie depending on who did it correct shift the counter for that index towards that side

// always_ff @(posedge clk) begin
//     if (write) begin
//         if (gshare_correct && !two_lvl_correct) begin
//             // Decrement the chooser counter to favor Gshare
//             if (chooser_pht[wdata_gshare.pc[$clog2(CHOOSER_PHT_SIZE)+1:2]] != 2'b00) begin
//                 chooser_pht[wdata_gshare.pc[$clog2(CHOOSER_PHT_SIZE)+1:2]] <= chooser_pht[chooser_index] - 1;
//             end
//         end else if (!gshare_correct && two_lvl_correct) begin
//             // Increment the chooser counter to favor 2-Level
//             if (chooser_pht[wdata_gshare.pc[$clog2(CHOOSER_PHT_SIZE)+1:2]] != 2'b11) begin
//                 chooser_pht[wdata_gshare.pc[$clog2(CHOOSER_PHT_SIZE)+1:2]] <= chooser_pht[chooser_index] + 1;
//             end
//         end
//     end
// end

// endmodule
// // if both of them predicte correct/incorrect, dont update the counter
// // otherwsie depending on who did it correct shift the counter for that index towards that side


// // what all do we need to store
//     // pc(save it to wdat_gshare), 2lvl_predicted value, gshare_predicted value, final_prediction(storing this with 2_lvl_struct)


module tournament_pred
import rv32i_types::*;
#(
    parameter GHR_LENGTH = 6,
    parameter LHT_LENGTH = 6,    
    parameter PHT_LENGTH = 4,
    parameter COUNTER_WIDTH = 2,
    parameter CHOOSER_PHT_SIZE = 1
)
(
    // input logic clk,
    // input logic rst,

    // Common signals
    // input logic read,
    input logic [31:0] pc,
    // input logic write,
    // input logic flush,

    // Gshare values
    input logic rresp_gshare,
    input predictor_gshare_t prediction_gshare,
    // input logic wresp_gshare,
    input predictor_gshare_t wdata_gshare,
    
    // 2-Level values
    input predictor_t prediction,
    // input logic wresp_2lvl,
    input logic rresp_2lvl,
    input predictor_t wdata,

    // Final Prediction
    output tournament_t prediction_tournament,
    input tournament_t wdata_tournament
);

    // Internal signals
    logic [$clog2(CHOOSER_PHT_SIZE)-1:0] chooser_index, chooser_index_1;
    logic [COUNTER_WIDTH-1:0] chooser_counter;
    logic gshare_correct, two_lvl_correct;
    logic final_prediction;

    // CPHT Declaration
    // reg [COUNTER_WIDTH-1:0] chooser_pht [CHOOSER_PHT_SIZE-1:0];
    reg [COUNTER_WIDTH-1:0] chooser_pht;
    // Determine Correct Predictions

    assign gshare_correct = (wdata_tournament.final_prediction == wdata_gshare.b_counter_gshare[1]);
    assign two_lvl_correct = (wdata_tournament.final_prediction == wdata.b_counter[1]);

    integer i;
    // always_ff @(posedge clk) begin
    //     if (rst) begin
    //         chooser_pht <= 2'b11;
    //         // for (i = 0; i < CHOOSER_PHT_SIZE; i++) begin
    //         //     chooser_pht[i] <= 2'b10; // Slightly favor 2-Level predictor
    //         // end
    //     end 
    //     // else begin
    //     //     if (write) begin
    //     //         chooser_index_1 = wdata_tournament.pc[$clog2(CHOOSER_PHT_SIZE)+1:2];
    //     //         if (gshare_correct && !two_lvl_correct) begin
    //     //             // Favor Gshare
    //     //             if (chooser_pht[chooser_index_1] != 2'b00) begin
    //     //                 chooser_pht[chooser_index_1] <= chooser_pht[chooser_index_1] - 1'b1;
    //     //             end
    //     //         end else if (!gshare_correct && two_lvl_correct) begin
    //     //             // Favor 2-Level
    //     //             if (chooser_pht[chooser_index_1] != 2'b11) begin
    //     //                 chooser_pht[chooser_index_1] <= chooser_pht[chooser_index_1] + 1'b1;
    //     //             end
    //     //         end
    //     //     end
    //     // end
    //     // else begin
    //     //     if (write) begin
    //     //         chooser_index_1 = wdata_tournament.pc[$clog2(CHOOSER_PHT_SIZE)+1:2];
    //     //         if (gshare_correct && !two_lvl_correct) begin
    //     //             // Favor Gshare
    //     //             if (chooser_pht != 2'b00) begin
    //     //                 chooser_pht <= chooser_pht - 1'b1;
    //     //             end
    //     //         end else if (!gshare_correct && two_lvl_correct) begin
    //     //             // Favor 2-Level
    //     //             if (chooser_pht != 2'b11) begin
    //     //                 chooser_pht <= chooser_pht + 1'b1;
    //     //             end
    //     //         end
    //     //     end
    //     // end
    // end
    // // Generate Final Prediction
    

    always_comb begin
        if (rresp_gshare && rresp_2lvl) begin
            chooser_index = pc[$clog2(CHOOSER_PHT_SIZE)+1:2];
            // chooser_counter = chooser_pht[chooser_index];    
            chooser_counter = 2'b11;
            final_prediction = chooser_counter[1] ? prediction.b_counter[1] : prediction_gshare.b_counter_gshare[1];

            prediction_tournament.final_prediction = final_prediction;
            prediction_tournament.pc = pc;
            prediction_tournament.branch_used = chooser_counter[1]; // 1 is 2lvl and 0 is gshare
        end else begin
            prediction_tournament.final_prediction = 1'b1;
            prediction_tournament.pc = pc;
            prediction_tournament.branch_used = 1'b1; // 1 is 2lvl and 0 is gshare
            end
    end

endmodule
