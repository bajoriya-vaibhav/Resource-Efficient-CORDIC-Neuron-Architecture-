module qmac #(
    parameter Q = 5,       
    parameter N = 8        
) (
    input clk,              
    input reset,            
    input [N-1:0] a,        
    input [N-1:0] b,        
    output [2*N-1:0] result,
    output overflow
);

    reg [2*N-1:0] accumulator;

    wire [2*N-1:0] product;
    wire mult_overflow;

    wire [2*N-1:0] sum;
    wire add_overflow;

    qmult #(.Q(Q), .N(N)) multiplier (
        .i_multiplicand(a),
        .i_multiplier(b),
        .o_result(product),
        .ovr(mult_overflow)
    );

    qadd #(.Q(2*Q), .N(2*N)) adder (
        .a(accumulator),
        .b(product),
        .c(sum),
        .ovr(add_overflow)
    );

    always @(posedge clk or posedge reset) begin
        if (reset)
            accumulator <= 0;
        else
            accumulator <= sum;
    end

    assign result = accumulator;
    assign overflow = add_overflow;

endmodule

// module Test_qmac;

//     reg clk;
//     reg reset;
//     reg [7:0] a;
//     reg [7:0] b;
//     wire [15:0] result;
//     wire overflow;

//     // Instantiate the MAC module
//     qmac #(.Q(5), .N(8)) uut (
//         .clk(clk),
//         .reset(reset),
//         .a(a),
//         .b(b),
//         .result(result),
//         .overflow(overflow)
//     );

//     reg expected_ovf;
//     integer expected_accum;
//     integer product;

//     // Clock generation
//     initial begin
//         clk = 0;
//         forever #5 clk = ~clk;
//     end

//     // Test sequence
//     initial begin
//         // Initialize
//         a = 0;
//         b = 0;
//         expected_accum = 0;
//         expected_ovf = 0;

//         // Reset sequence
//         reset = 1;
//         @(negedge clk);
//         reset = 0;
//         @(negedge clk);

//         // Test 1: Reset check
//         $display("Reset Test:");
//         print_results(1);

//         // Test 2: 1.0 * 1.0 = 1.0 (Q10)
//         a = 8'b00100000; // 1.0 in Q5 (32)
//         b = 8'b00100000;
//         @(negedge clk);
//         product = $signed(a) * $signed(b);
//         expected_accum += product;
//         expected_ovf = (expected_accum > 32767) || (expected_accum < -32768);
//         print_results(2);

//         // Test 3: 1.0 * -1.0 = -1.0 (Q10)
//         a = 8'b00100000;
//         b = 8'b10100000; // -1.0 in Q5 (-32)
//         @(negedge clk);
//         product = $signed(a) * $signed(b);
//         expected_accum += product;
//         expected_ovf = (expected_accum > 32767) || (expected_accum < -32768);
//         print_results(3);

//         // Test 4: 3.96875 * 3.96875 = 15.75 (Q10)
//         a = 8'b01111111; // 3.96875 in Q5 (127)
//         b = 8'b01111111;
//         @(negedge clk);
//         product = $signed(a) * $signed(b);
//         expected_accum += product;
//         expected_ovf = (expected_accum > 32767) || (expected_accum < -32768);
//         print_results(4);

//         // Test 5: Accumulate same product again (15.75 + 15.75 = 31.5)
//         a = 8'b01111111;
//         b = 8'b01111111;
//         @(negedge clk);
//         product = $signed(a) * $signed(b);
//         expected_accum += product;
//         expected_ovf = (expected_accum > 32767) || (expected_accum < -32768);
//         print_results(5);

//         // Test 6: Third accumulation (47.25, overflow)
//         a = 8'b01111111;
//         b = 8'b01111111;
//         @(negedge clk);
//         product = $signed(a) * $signed(b);
//         expected_accum += product;
//         expected_ovf = (expected_accum > 32767) || (expected_accum < -32768);
//         print_results(6);

//         // // Test 7: Reset and check -4.0 * -4.0 = 16.0 (Q10)
//         // reset = 1;
//         // @(negedge clk);
//         // reset = 0;
//         // expected_accum = 0;
//         // expected_ovf = 0;
//         // a = 8'b10000000; // -4.0 in Q5 (-128)
//         // b = 8'b10000000;
//         // @(negedge clk);
//         // product = $signed(a) * $signed(b);
//         // expected_accum += product;
//         // expected_ovf = (expected_accum > 32767) || (expected_accum < -32768);
//         // print_results(7);

//         // // Test 8: 2.5 * 2.5 = 6.25 (Q10)
//         // a = 8'b00101000; // 2.5 in Q5 (80)
//         // b = 8'b00101000;
//         // @(negedge clk);
//         // product = $signed(a) * $signed(b);
//         // expected_accum += product;
//         // expected_ovf = (expected_accum > 32767) || (expected_accum < -32768);
//         // print_results(8);

//         $display("\nAll tests completed!");
//         $finish;
//     end

//     task print_results;
//         input integer test_num;
//         begin
//             $display("Test %0d:", test_num);
//             $display("a = %b , b = %b", 
//                      a, b);
//             $display("Result = %b , Overflow = %b",
//                      result, overflow);
//             $display("Expected Overflow: %b", expected_ovf);
//             $display("-----------------------------------");
//         end
//     endtask

// endmodule
