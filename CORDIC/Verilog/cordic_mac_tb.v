`timescale 1ns/1ps

module cordic_linear_tb;

    reg clk, rst;
    reg signed [31:0] x_in, y_in, z_in;
    wire signed [31:0] x_out, y_out;

    cordic_linear_mode dut (
        .clk(clk),
        .rst(rst),
        .x_in(x_in),
        .y_in(y_in),
        .z_in(z_in),
        .x_out(x_out),
        .y_out(y_out)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

    task display_result;
        real x_real, y_real, z_real, x_res, y_res;
        begin
            x_real = $itor(x_in) / (2.0 ** 24);
            y_real = $itor(y_in) / (2.0 ** 24);
            z_real = $itor(z_in) / (2.0 ** 24);
            x_res  = $itor(x_out) / (2.0 ** 24);
            y_res  = $itor(y_out) / (2.0 ** 24);
            $display("Input: x=%.6f y=%.6f z=%.6f => Output: x_out=%.6f y_out=%.6f",
                     x_real, y_real, z_real, x_res, y_res);
        end
    endtask

    initial begin
        rst = 1;
        // Example test case: multiply (1.0, 0.0) by 0.5
        x_in = 32'sd16777216; // 1.0 in Q8.24
        y_in = 32'sd16777216; // 0.0 in Q8.24
        z_in = 32'sd8388608;  // 0.5 in Q8.24
        #20;
        rst = 0;

        

        #500;
        display_result();

        rst = 1;
        // Multiply (2.0, 1.0) by -0.25
        x_in = 32'sd33554432; // 2.0
        // y_in = 32'sd16777216; // 1.0
        y_in = 32'sd0; // 0
        z_in = -32'sd4194304; // -0.25
        #20;
        rst = 0;

        #500;
        display_result();

        rst = 1;


        // Multiply (0.0, 1.0) by 2.0
        x_in = 32'sd0;
        y_in = 32'sd16777216;
        z_in = 32'sd33554432;

        #20;
        rst = 0;
        #500;
        display_result();

        $finish;
    end

endmodule
