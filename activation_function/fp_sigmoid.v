// https://www.mdpi.com/2079-9292/11/9/1365

module sigmoid #(
    parameter Q = 24,
    parameter N = 32
) (
    input [N-1:0] x,
    output [N-1:0] y
);
    // Thresholds
    localparam [N-1:0] T_1       = 32'b00000001000000000000000000000000; // 1.0
    localparam [N-1:0] T_2       = 32'b00000010000000000000000000000000; // 2.0
    localparam [N-1:0] T_3       = 32'b00000011000000000000000000000000; // 3.0
    localparam [N-1:0] T_4_5     = 32'b00000100100000000000000000000000; // 4.5
    localparam [N-1:0] T_8       = 32'b00001000000000000000000000000000; // 8.0

    // Coefficients for the piecewise linear approximation
    localparam signed [N-1:0] SLOPE1    = 32'b00000000000000001010010100100111; // 0.00252
    localparam signed [N-1:0] INTERCEPT1= 32'b00000000000001001100110011001101; // 0.01875
    localparam signed [N-1:0] SLOPE2    = 32'b00000000000001100000111100111101; // 0.02367
    localparam signed [N-1:0] INTERCEPT2= 32'b00000000000111010010110100100011; // 0.11397
    localparam signed [N-1:0] SLOPE3    = 32'b00000000000100011101101100100011; // 0.06975
    localparam signed [N-1:0] INTERCEPT3= 32'b00000000010000001000111110000110; // 0.25219
    localparam signed [N-1:0] SLOPE4    = 32'b00000000001001011111111000110011; // 0.14841
    localparam signed [N-1:0] INTERCEPT4= 32'b00000000011010001101010110100110; // 0.40951
    localparam signed [N-1:0] SLOPE5    = 32'b00000000001111010010100010001101; // 0.2389
    localparam signed [N-1:0] INTERCEPT5= 32'b00000000100000000000000000000000; // 0.5
    localparam signed [N-1:0] SLOPE6    = 32'b00000000001001011111111000110011; // 0.14841
    localparam signed [N-1:0] INTERCEPT6= 32'b00000000100101110010101001011010; // 0.59049
    localparam signed [N-1:0] SLOPE7    = 32'b00000000000100011101101100100011; // 0.06975
    localparam signed [N-1:0] INTERCEPT7= 32'b00000000101111110111000001111010; // 0.74781
    localparam signed [N-1:0] SLOPE8    = 32'b00000000000001100000111100111101; // 0.02367
    localparam signed [N-1:0] INTERCEPT8= 32'b00000000111000101101001011011101; // 0.88603
    localparam signed [N-1:0] SLOPE9    = 32'b00000000000000001010010100100111; // 0.00252
    localparam signed [N-1:0] INTERCEPT9= 32'b00000000111110110011001100110011; // 0.98125

    reg [N-1:0] slope;
    reg [N-1:0] intercept;
    wire [2*N-1:0] product;
    wire [N-1:0] product_trunc;
    wire [N-1:0] sum;
    wire ovr_mult, ovr_add;
    
    // magnitude and the sign bit of x
    wire [N-2:0] x_mag = x[N-2:0];
    wire x_sign = x[N-1];
    
    // coefficient selection logic
    always @(*) begin
        if (x_sign == 1'b1) begin  // Negative x
            if (x_mag >= T_8[N-2:0]) begin  // |x| >= 8.0
                slope = 32'b00000000000000000000000000000000;  // 0
                intercept = 32'b00000000000000000000000000000000;  // 0
            end else if (x_mag >= T_4_5[N-2:0] && x_mag < T_8[N-2:0]) begin  // 4.5 <= |x| < 8.0
                slope = SLOPE1;
                intercept = INTERCEPT1;
            end else if (x_mag >= T_3[N-2:0] && x_mag < T_4_5[N-2:0]) begin  // 3.0 <= |x| < 4.5
                slope = SLOPE2;
                intercept = INTERCEPT2;
            end else if (x_mag >= T_2[N-2:0] && x_mag < T_3[N-2:0]) begin  // 2.0 <= |x| < 3.0
                slope = SLOPE3;
                intercept = INTERCEPT3;
            end else if (x_mag >= T_1[N-2:0] && x_mag < T_2[N-2:0]) begin  // 1.0 <= |x| < 2.0
                slope = SLOPE4;
                intercept = INTERCEPT4;
            end else begin  // 0 < |x| < 1.0
                slope = SLOPE5;
                intercept = INTERCEPT5;
            end
        end else begin  // Positive x
            if (x_mag >= T_8[N-2:0]) begin  // x >= 8.0
                slope = 32'b00000000000000000000000000000000;  // 0
                intercept = 32'b00000001000000000000000000000000;  // 1.0
            end else if (x_mag >= T_4_5[N-2:0] && x_mag < T_8[N-2:0]) begin  // 4.5 <= x < 8.0
                slope = SLOPE9;
                intercept = INTERCEPT9;
            end else if (x_mag >= T_3[N-2:0] && x_mag < T_4_5[N-2:0]) begin  // 3.0 <= x < 4.5
                slope = SLOPE8;
                intercept = INTERCEPT8;
            end else if (x_mag >= T_2[N-2:0] && x_mag < T_3[N-2:0]) begin  // 2.0 <= x < 3.0
                slope = SLOPE7;
                intercept = INTERCEPT7;
            end else if (x_mag >= T_1[N-2:0] && x_mag < T_2[N-2:0]) begin  // 1.0 <= x < 2.0
                slope = SLOPE6;
                intercept = INTERCEPT6;
            end else begin  // 0 <= x < 1.0
                slope = SLOPE5;
                intercept = INTERCEPT5;
            end
        end
    end

    // Fixed-point multiplication
    qmult #(.Q(Q), .N(N)) mult (
        .i_multiplicand(x),
        .i_multiplier(slope),
        .o_result(product),
        .ovr(ovr_mult)
    );

    // Extract the proper bits from the product
    // For Q24, we need bits [55:24] of the 64-bit product
    assign product_trunc = {product[2*N-1], product[Q+N-2:Q]};

    // Fixed-point addition
    qadd #(.Q(Q), .N(N)) add (
        .a(product_trunc),
        .b(intercept),
        .c(sum),
        .ovr(ovr_add)
    );

    // Final output selection with proper sign handling
    assign y = (x_sign == 1'b1 && x_mag >= T_8[N-2:0]) ? 32'b00000000000000000000000000000000 :  // 0.0 for x <= -8.0
               (x_sign == 1'b0 && x_mag >= T_8[N-2:0]) ? 32'b00000001000000000000000000000000 :  // 1.0 for x >= 8.0
               sum;
endmodule