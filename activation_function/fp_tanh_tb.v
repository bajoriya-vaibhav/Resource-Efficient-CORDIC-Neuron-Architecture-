// https://chummersone.github.io/qformat.html

`timescale 1ns/1ps

module tb_tanh();
    reg signed [31:0] x_in;
    wire signed [31:0] y_out;
    reg [31:0] expected;

    tanh #(.Q(24), .N(32)) dut (
        .x(x_in),
        .y(y_out)
    );

    initial begin
        // Test case 1: x = -10 (tanh(-10) ≈ -1)
        x_in = 32'b10001010000000000000000000000000; // -10.0
        #10;
        expected = 32'b10000001000000000000000000000000; // -1.0
        $display("Test 1: x=-10.0 => y=%b (Expected: %b) %s", 
                y_out, expected, (y_out === expected) ? "PASS" : "FAIL");

        // Test case 2: x = -3 (tanh(-3) ≈ -0.9951)
        x_in = 32'b10000011000000000000000000000000; // -3.0
        #10;
        expected = 32'b10000000111111101011111011100000; // ~-0.9951
        $display("Test 2: x=-3.0  => y=%b (Expected: ~%b) %s", 
                y_out, expected, (y_out >= 32'b10000000111111011110001010110001 && y_out <= 32'b10000000111111101111110101110010) ? "PASS" : "FAIL");

        // Test case 3: x = 0 (tanh(0) = 0)
        x_in = 32'b00000000000000000000000000000000; // 0.0
        #10;
        expected = 32'h00000000; // 0.0
        $display("Test 3: x=0.0   => y=%b (Expected: %b) %s", 
                y_out, expected, (y_out === expected) ? "PASS" : "FAIL");

        // Test case 4: x = 1 (tanh(1) ≈ 0.7616)
        x_in = 32'h01000000; // 1.0
        #10;
        expected = 32'h00C3126F; // ~0.7716
        $display("Test 4: x=1.0   => y=%b (Expected: ~%b) %s", 
                y_out, expected, (y_out >= 32'b00000000110001011000011110010100 && y_out <= 32'b00000000110001110001001000011100) ? "PASS" : "FAIL");

        // Test case 5: x = 10 (tanh(10) ≈ 1)
        x_in = 32'h0A000000; // 10.0
        #10;
        expected = 32'h01000000; // 1.0
        $display("Test 5: x=10.0  => y=%b (Expected: %b) %s", 
                y_out, expected, (y_out === expected) ? "PASS" : "FAIL");

        $finish;
    end
endmodule
