module qadd #(
	//Parameterized values
	parameter Q = 15,
	parameter N = 32
	)
	(
    input [N-1:0] a,
    input [N-1:0] b,
    output [N-1:0] c,
    output ovr
    );
reg [N-1:0] res;
reg ovr_reg;
reg [N-1:0] sum_mag;

assign ovr = ovr_reg;
assign c = res;

always @(a,b) begin
    sum_mag = 0;
    ovr_reg = 0;
    res = 0;
	// both negative or both positive
	if(a[N-1] == b[N-1]) begin		
        sum_mag = a[N-2:0] + b[N-2:0];		
		res[N-2:0] = a[N-2:0] + b[N-2:0];	 	
		res[N-1] = a[N-1];				
        ovr_reg = sum_mag[N-1];
	    end												
	//	one of them is negative...
	else if(a[N-1] == 0 && b[N-1] == 1) begin		
		if( a[N-2:0] > b[N-2:0] ) begin					
			res[N-2:0] = a[N-2:0] - b[N-2:0];			
			res[N-1] = 0;										
			end
		else begin												
			res[N-2:0] = b[N-2:0] - a[N-2:0];			
			if (res[N-2:0] == 0)
				res[N-1] = 0;										
			else
				res[N-1] = 1;										
			end
        ovr_reg = 0;
		end
	else begin												
		if( a[N-2:0] > b[N-2:0] ) begin					
			res[N-2:0] = a[N-2:0] - b[N-2:0];			
			if (res[N-2:0] == 0)
				res[N-1] = 0;										
			else
				res[N-1] = 1;										
			end
		else begin												
			res[N-2:0] = b[N-2:0] - a[N-2:0];			
			res[N-1] = 0;										
			end
        ovr_reg = 0;
		end
	end
endmodule

// module Test_add;

//     // Inputs
//     reg [1:0] a;
//     reg [1:0] b;

//     // Outputs
//     wire [1:0] c;
//     wire overflow;

//     // Instantiate the UUT with N=2 and Q=0
//     qadd #(0, 2) uut (
//         .a(a),
//         .b(b),
//         .c(c),
//         .ovr(overflow)
//     );

//     // Monitor signals
//     wire a_sign, b_sign, c_sign;
//     wire [0:0] a_mag, b_mag, c_mag;

//     assign a_sign = a[1];
//     assign b_sign = b[1];
//     assign c_sign = c[1];
//     assign a_mag = a[0];
//     assign b_mag = b[0];
//     assign c_mag = c[0];

//     initial begin
//         // Initialize Inputs
//         a = 0;
//         b = 0;

//         // Wait for initial reset
//         #10;

//         // Test all combinations
//         $display("Testing all 2-bit combinations...");
//         $display("a\tb\tc\ta_sign\ta_mag\tb_sign\tb_mag\tc_sign\tc_mag\toverflow");
//         for (integer i = 0; i < 4; i = i + 1) begin
//             a = i;
//             for (integer j = 0; j < 4; j = j + 1) begin
//                 b = j;
//                 #10; // Wait for the result to stabilize
//                 $display("%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b", 
//                     a, b, c, 
//                     a_sign, a_mag, 
//                     b_sign, b_mag, 
//                     c_sign, c_mag,
//                     overflow);
//             end
//         end

//         $finish;
//     end

// endmodule
