module RAS
#(
    parameter RAS_DEPTH = 8
)
(
    input   logic   clk,
    input   logic   rst,

    input   logic   push_en,
    input   logic   pop_en,

    input   logic   [31:0]  push_addr,
    output  logic   [31:0]  top_addr
);

    logic   [31:0]  stack   [RAS_DEPTH];
    logic   [$clog2(RAS_DEPTH): 0] stack_ptr;

    logic   empty, full;

    assign empty = (stack_ptr == '0) ? 1'b1 : 1'b0;
    assign full = (stack_ptr == 4'd8) ? 1'b1 : 1'b0;

    assign top_addr = (pop_en) ? ((empty) ? stack[stack_ptr] : stack[stack_ptr -1]) : 'x;

    always_ff @(posedge clk) begin
        if (rst) begin
            stack_ptr <= '0;
        end 
        else begin
            if (push_en && !full) begin
                stack[stack_ptr] <= push_addr;
                stack_ptr <= 4'((stack_ptr + 1));
            end
            else if (pop_en && push_en && !empty) begin
                stack[stack_ptr] <= push_addr;
            end             
            else if (pop_en && !empty) begin
                stack_ptr <= 4'((stack_ptr - 1));
            end
        end
    end 

endmodule : RAS