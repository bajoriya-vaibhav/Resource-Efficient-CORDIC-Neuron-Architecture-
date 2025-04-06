module tanh #(
    parameter Q = 24,
    parameter N = 32
) (
    input [N-1:0] x,
    output [N-1:0] y
);
    // Constants in Q24 format
    localparam [N-1:0] TWO       = 32'b00000010000000000000000000000000; // 2.0
    localparam [N-1:0] NEG_ONE   = 32'b10000001000000000000000000000000; // -1.0 (sign-magnitude)
    
    // Signals for intermediate results
    wire [N-1:0] doubled_x;
    wire [N-1:0] sigmoid_result;
    wire [2*N-1:0] mult_result;
    wire [N-1:0] mult_trunc;
    wire [N-1:0] final_result;
    wire ovr_mult1, ovr_mult2, ovr_add;
    
    // Double the input x using left shift
    assign doubled_x = {x[N-1], x[N-3:0], 1'b0};
    
    // Calculate sigmoid(2x)
    sigmoid #(.Q(Q), .N(N)) sigmoid_inst (
        .x(doubled_x),
        .y(sigmoid_result)
    );
    
    // Multiply sigmoid result by 2
    qmult #(.Q(Q), .N(N)) mult_sigmoid_by_2 (
        .i_multiplicand(sigmoid_result),
        .i_multiplier(TWO),
        .o_result(mult_result),
        .ovr(ovr_mult2)
    );
    
    // Extract the proper bits from 2*sigmoid(2x)
    assign mult_trunc = {mult_result[2*N-1], mult_result[Q+N-2:Q]};
    
    // Subtract 1: 2*sigmoid(2x) - 1
    qadd #(.Q(Q), .N(N)) subtract_one (
        .a(mult_trunc),
        .b(NEG_ONE), // -1 in sign-magnitude
        .c(final_result),
        .ovr(ovr_add)
    );
    
    // Output assignment
    assign y = final_result;
    
endmodule