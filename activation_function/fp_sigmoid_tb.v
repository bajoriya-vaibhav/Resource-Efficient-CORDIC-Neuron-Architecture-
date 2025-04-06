`timescale 1ns/1ps

module tb_sigmoid();
    reg signed [31:0] x_in;
    wire signed [31:0] y_out;
    reg [31:0] expected;

    sigmoid #(.Q(24), .N(32)) dut (
        .x(x_in),
        .y(y_out)
    );

    initial begin
        // Test case 1: x = -10 (should output 0)
        x_in = 32'b10001010000000000000000000000000; // -10.0
        #10;
        expected = 32'h00000000;
        $display("Test 1: x=-10.0 => y=%b (Expected: %b) %s", 
                y_out, expected, (y_out === expected) ? "PASS" : "FAIL");

        // Test case 2: x = -6 (-8 < x <= -4.5)
        x_in = 32'b10000110000000000000000000000000; // -6.0
        #10;
        expected = 32'h0000EE58; // ~0.00363
        $display("Test 2: x=-6.0  => y=%b (Expected: ~%b) %s", 
                y_out, expected, (y_out >= 32'h0000ecb0 && y_out <= 32'h0000EF00) ? "PASS" : "FAIL");

        // Test case 3: x = 0 (-1 < x <= 1)
        x_in = 32'b00000000000000000000000000000000; // 0.0
        #10;
        expected = 32'h00800000; // 0.5 exactly
        $display("Test 3: x=0.0   => y=%b (Expected: %b) %s", 
                y_out, expected, (y_out === expected) ? "PASS" : "FAIL");

        // Test case 4: x = 2.5 (2 < x <= 3)
        x_in = 32'h02800000; // 2.5
        #10;
        expected = 32'h00EC85A9; // ~0.922185
        $display("Test 4: x=2.5   => y=%b (Expected: ~%b) %s", 
                y_out, expected, (y_out >= 32'h00EC0000 && y_out <= 32'h00ED0000) ? "PASS" : "FAIL");

        // Test case 5: x = 10 (should output 1)
        x_in = 32'h0A000000; // 10.0
        #10;
        expected = 32'h01000000; // 1.0 exactly
        $display("Test 5: x=10.0  => y=%b (Expected: %b) %s", 
                y_out, expected, (y_out === expected) ? "PASS" : "FAIL");

        $finish;
    end
endmodule