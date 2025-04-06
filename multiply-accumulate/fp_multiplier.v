module qmult #(
    parameter Q = 24,
    parameter N = 32
) (
    input [N-1:0] i_multiplicand,
    input [N-1:0] i_multiplier,
    output [2*N-1:0] o_result,
    output reg ovr
);

    reg [2*N-2:0] magnitude_product;
    reg sign_bit;
    // Threshold for overflow: (2^(N-1) - 1) << Q
    localparam THRESHOLD = ( (1 << (N-1)) - 1 ) << Q;

    always @(*) begin
        magnitude_product = i_multiplicand[N-2:0] * i_multiplier[N-2:0];
        sign_bit = i_multiplicand[N-1] ^ i_multiplier[N-1];
        // Overflow occurs if the product exceeds the maximum N-1 bit magnitude
        ovr = (magnitude_product > THRESHOLD);
    end

    assign o_result = {sign_bit, magnitude_product};

endmodule

// `timescale 1ns / 1ps

// module test_fp_multiplier;

//     reg [7:0] i_multiplicand;
//     reg [7:0] i_multiplier;
//     wire [15:0] o_result;
//     wire ovr;

//     qmult #(5, 8) uut (
//         .i_multiplicand(i_multiplicand),
//         .i_multiplier(i_multiplier),
//         .o_result(o_result),
//         .ovr(ovr)
//     );

//     initial begin
//         $display("Testing fixed-point multiplier:");
//         $display("Multiplicand\tMultiplier\tResult\t\tOverflow");

//         // Test cases
//         i_multiplicand = 8'b00001100;
//         i_multiplier = 8'b00000101;  
//         #10;
//         $display("%b\t%b\t%b\t%b", i_multiplicand, i_multiplier, o_result, ovr);

//         i_multiplicand = 8'b11110100; 
//         i_multiplier = 8'b00000101;  
//         #10;
//         $display("%b\t%b\t%b\t%b", i_multiplicand, i_multiplier, o_result, ovr);

//         i_multiplicand = 8'b00001100;
//         i_multiplier = 8'b11111011;
//         #10;
//         $display("%b\t%b\t%b\t%b", i_multiplicand, i_multiplier, o_result, ovr);

//         i_multiplicand = 8'b11110100;
//         i_multiplier = 8'b11111011;
//         #10;
//         $display("%b\t%b\t%b\t%b", i_multiplicand, i_multiplier, o_result, ovr);

//         i_multiplicand = 8'b01111111;
//         i_multiplier = 8'b01111111;
//         #10;
//         $display("%b\t%b\t%b\t%b", i_multiplicand, i_multiplier, o_result, ovr);

//         i_multiplicand = 8'b10000000;
//         i_multiplier = 8'b10000000;
//         #10;
//         $display("%b\t%b\t%b\t%b", i_multiplicand, i_multiplier, o_result, ovr);

//         $finish;
//     end

// endmodule

// module Test_mult;

//     reg [1:0] i_multiplicand;
//     reg [1:0] i_multiplier;

//     wire [3:0] o_result;
//     wire ovr;

//     qmult #(0, 2) uut (
//         .i_multiplicand(i_multiplicand),
//         .i_multiplier(i_multiplier),
//         .o_result(o_result),
//         .ovr(ovr)
//     );

//     wire a_sign, b_sign, c_sign;
//     wire [0:0] a_mag, b_mag, c_mag;

//     assign a_sign = i_multiplicand[1];
//     assign b_sign = i_multiplier[1];
//     assign c_sign = o_result[1];
//     assign a_mag = i_multiplicand[0];
//     assign b_mag = i_multiplier[0];
//     assign c_mag = o_result[0];

//     integer i, j;

//     initial begin
//         $display("Testing all 2-bit signed multiplications:");
//         $display("a\tb\tresult\toverflow\ta_sign\ta_mag\tb_sign\tb_mag\tc_sign\tc_mag");
        
//         for (i = 0; i < 4; i = i + 1) begin 
//             i_multiplicand = i;
//             for (j = 0; j < 4; j = j + 1) begin
//                 i_multiplier = j;
//                 #10;
//                 $display("%b\t%b\t%b\t%b\t\t%b\t%b\t\t%b\t%b\t\t%b\t%b",
//                     i_multiplicand, i_multiplier, o_result, ovr,
//                     a_sign, a_mag, b_sign, b_mag, c_sign, c_mag);
//             end
//         end
//         $finish;
//     end

// endmodule