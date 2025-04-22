/*
This code is the test bench for testing lookup table retrieval in case of CORDIC
hyperbolic mode. 

SF is basically the conversion factor for our fixed point representation which should be 
equivalent to shifting a number by the float size accordingly.
*/

`timescale 10ns / 100ps
module atanh_LOOKUP_tb;
    localparam FLOAT_SIZE = 24;
    localparam INT_SIZE = 8;

	// Input
	reg signed [4:0] i;

	// Output
	wire signed [INT_SIZE-1:-FLOAT_SIZE] v;

	// Instantiate the Unit Under Test (UUT)
	atanh_LOOKUP uut ( 
		.index(i), 
		.value(v)
    );
    
    localparam SF = 2.0**-FLOAT_SIZE;

	always
	begin
        #1
		$display($time, "0ns: ",
			"i=%b(%d)", i, i,
			" --- >",
			" atanh:%h(%f)", v, $itor(v*SF));
        i = i + 1;
    end
	
    initial begin
		// Initialize Inputs
		$display("[START]");
		i = -5;
    end	  
endmodule

