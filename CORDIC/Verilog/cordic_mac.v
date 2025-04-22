/*
This code uses CORDIC linear mode the calculate MAC(Multiply-Accumulate) operation, readme 
file contains detailed explanation on cordic algorithm. Refer for theoritical understanding.
The mac output calculated is x*z + y

All numbers are in Q7.24 format
*/

module cordic_linear_mode #(
    parameter ITERATIONS = 24  // CORDIC iterations (matches fractional precision)
)(
    input wire clk,
    input wire rst,
    input wire signed [31:0] x_in,
    input wire signed [31:0] y_in,  
    input wire signed [31:0] z_in,  
    output reg signed [31:0] x_out,
    output reg signed [31:0] y_out // this signal will contain the final mac output
);

    // Internal registers, used for iterations
    reg signed [31:0] x ;
    reg signed [31:0] y ;
    reg signed [31:0] z ;
    
    integer i; // iteration count 

    always @(posedge clk or posedge rst) begin
        if (rst) begin // reset signal initialization
            x <= x_in;
            y <= y_in;
            z <= z_in;
            x_out <= 0;
            y_out <= 0;
            i = 0;
        end else begin
            if (i < ITERATIONS) 
            begin
                if (z[31] == 0) begin  // z >= 0
                    x <= x;
                    y <= y + (x >>> i);
                    z <= z - (32'sd1 <<< (24 - i));  // Subtract 2^-i
                end else begin
                    x <= x;
                    y <= y - (x >>> i);
                    z <= z + (32'sd1 <<< (24 - i));  // Add 2^-i
                end
                i = i+1;
            end
            

            // Outputs
            x_out <= x;
            y_out <= y;
        end
    end

endmodule
