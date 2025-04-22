module cordic_linear_mode #(
    parameter ITERATIONS = 24  // CORDIC iterations (matches fractional precision)
)(
    input wire clk,
    input wire rst,
    input wire signed [31:0] x_in,  // Q8.24 format
    input wire signed [31:0] y_in,  // Q8.24 format
    input wire signed [31:0] z_in,  // scalar multiplier in Q8.24
    output reg signed [31:0] x_out,
    output reg signed [31:0] y_out
);

    // Internal registers
    reg signed [31:0] x ;
    reg signed [31:0] y ;
    reg signed [31:0] z ;

    // reg signed [31:0] x_new ;
    // reg signed [31:0] y_new ;
    // reg signed [31:0] z_new ;
    
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // for (i = 0; i <= ITERATIONS; i = i + 1) begin
            //     x <= x_in;
            //     y <= y_in;
            //     z <= z_in;
            // end
            x <= x_in;
            y <= y_in;
            z <= z_in;
            x_out <= 0;
            y_out <= 0;
            i = 0;
        end else begin
            // Initialization
            // x[0] <= x_in;
            // y[0] <= y_in;
            // z[0] <= z_in;

            // Iterative CORDIC in linear mode
            // for (i = 0; i < ITERATIONS; i = i + 1) begin
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
            
            // end

            // Outputs
            x_out <= x;
            y_out <= y;
        end
    end

    // always @(negedge clk) begin
    //     x <= x_new;
    //     y <= y_new;
    //     z <= z_new;
    // end

endmodule
