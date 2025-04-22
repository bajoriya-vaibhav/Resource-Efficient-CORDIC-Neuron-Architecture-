/*
This code implements the CORDIC algorithm in linear mode to calculate division operation. 
Theory given in README file. 
To do division, CORDIC has been used in vector mode rather than rotation mode. This can 
lead to interesting results combined with the other modes. In this case, it is very similar
to MAC operations.
*/

module cordicdiv(CLK, EN, y, x, out);
    parameter FLOAT_SIZE = 24;
    parameter INT_SIZE = 8;

    input wire CLK;
    input wire EN;
    input wire signed [INT_SIZE-1:-FLOAT_SIZE] y;
    input wire signed [INT_SIZE-1:-FLOAT_SIZE] x;
    output reg signed [INT_SIZE-1:-FLOAT_SIZE] out;

    parameter MAX_ITERATION = FLOAT_SIZE+1; // number of iterations, matches floating precision
    reg signed [INT_SIZE-1:-FLOAT_SIZE] y_;
    reg signed [INT_SIZE-1:-FLOAT_SIZE] z_; // converges to the division output

    /* 
    NOTE - in vector mode, z signal converges to desired value and not the y signal like
    rotation mode
    */

    reg [4:0] i; // iteration count
    always @(posedge CLK)
    begin
        if (EN) //  Like Reset
        begin
            out <= 32'h00_000000;
            z_ <= 32'h00_000000;
            y_ <= y;
            i <= 5'b0000;
        end
        else
        begin
            if (i < MAX_ITERATION && |y_) 
            begin
                // vector mode sees the sign of y signal for sign bit
                y_ <= y_[INT_SIZE-1] ? y_ + (x >>> i) : y_ - (x >>> i);
                z_ <= y_[INT_SIZE-1] ? z_ - $signed(32'h01_000000 >> i) : z_ + $signed(32'h01_000000 >> i);
                i <= i + 1;
            end
            out <= z_;
        end   
    end
endmodule