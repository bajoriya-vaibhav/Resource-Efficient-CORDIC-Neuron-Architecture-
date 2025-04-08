module tanh #(
    parameter Q = 24,
    parameter N = 32
) (
    input [N-1:0] x,
    output [N-1:0] y
);
    localparam [N-1:0] TWO       = 32'b00000010000000000000000000000000; // +2.0
    localparam [N-1:0] ONE       = 32'b00000001000000000000000000000000; // +1.0
    localparam [N-1:0] NEG_ONE   = 32'b10000001000000000000000000000000; // -1.0
    
    wire [2*N-1:0] doubled_x;
    wire [N-1:0] sigmoid_result;
    wire [2*N-1:0] scaled_sigmoid;
    wire [N-1:0] final_result;
    
    qmult #(.Q(Q), .N(N)) double_mult (
        .i_multiplicand(x),
        .i_multiplier(TWO),
        .o_result(doubled_x), 
        .ovr()
    );

    sigmoid #(.Q(Q), .N(N)) sigmoid_inst (
        .x(doubled_x[N-1:0]), 
        .y(sigmoid_result)
    );
    
    qmult #(.Q(Q), .N(N)) scale_mult (
        .i_multiplicand(sigmoid_result),
        .i_multiplier(TWO),
        .o_result(scaled_sigmoid),
        .ovr()
    );
    
    qadd #(.Q(Q), .N(N)) subtr (
        .a(scaled_sigmoid[N-1:0]),
        .b(ONE),  
        .c(final_result),
        .ovr()
    );
    
    assign y = final_result[N-1] ? 
        {1'b1, final_result[N-2:0]} :  // Maintain sign-magnitude
        final_result;
    
endmodule