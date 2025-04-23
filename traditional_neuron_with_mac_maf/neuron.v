module neuron #(
    parameter Q          = 24,       
    parameter N_INPUTS   = 4,         
    parameter DATA_WIDTH = 32         
) (
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         af_sel,     // 0: tanh, 1: sigmoid
    input  wire signed [N_INPUTS*DATA_WIDTH-1:0] x_packed,  
    input  wire signed [N_INPUTS*DATA_WIDTH-1:0] w_packed, 
    input  wire signed [DATA_WIDTH-1:0] bias,
    output reg  signed [DATA_WIDTH-1:0] out
);

// Unpack Inputs/Weights
wire signed [DATA_WIDTH-1:0] x [N_INPUTS-1:0];
wire signed [DATA_WIDTH-1:0] w [N_INPUTS-1:0];

genvar p;
generate
    for (p=0; p<N_INPUTS; p=p+1) begin : UNPACK
        assign x[p] = x_packed[p*DATA_WIDTH +: DATA_WIDTH];
        assign w[p] = w_packed[p*DATA_WIDTH +: DATA_WIDTH];
    end
endgenerate
// We used the piplined architecture used in the paper
// Stage 1: Input Buffering
reg signed [DATA_WIDTH-1:0] x_buf [N_INPUTS-1:0];
reg signed [DATA_WIDTH-1:0] w_buf [N_INPUTS-1:0];
reg signed [DATA_WIDTH-1:0] bias_buf;

integer j;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j=0; j<N_INPUTS; j=j+1) begin
            x_buf[j] <= 0;
            w_buf[j] <= 0;
        end
        bias_buf <= 0;
    end else begin
        for (j=0; j<N_INPUTS; j=j+1) begin
            x_buf[j] <= x[j];
            w_buf[j] <= w[j];
        end
        bias_buf <= bias;
    end
end

//Stage 2: Parallel Multiplication
wire [2*DATA_WIDTH-1:0] mult_results [N_INPUTS-1:0];
reg [2*DATA_WIDTH-1:0] mult_results_reg [N_INPUTS-1:0];

genvar i;

generate
    for (i=0; i<N_INPUTS; i=i+1) begin : MULT
        qmult #(.Q(Q), .N(DATA_WIDTH)) mult (
            .i_multiplicand(x_buf[i]),
            .i_multiplier(w_buf[i]),
            .o_result(mult_results[i]),
            .ovr()
        );
        
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) mult_results_reg[i] <= 0;
            else mult_results_reg[i] <= mult_results[i];
        end
    end
endgenerate

// Stage 3: Accumulation Tree
wire [2*DATA_WIDTH-1:0] sum_stage1 [N_INPUTS/2-1:0];
wire [2*DATA_WIDTH-1:0] sum_stage2;

generate
    // first layer of addition wixi(pairs)
    for (i=0; i<N_INPUTS/2; i=i+1) begin : ADD_STAGE1
        qadd #(.Q(2*Q), .N(2*DATA_WIDTH)) adder (
            .a(mult_results_reg[2*i]),
            .b(mult_results_reg[2*i+1]),
            .c(sum_stage1[i]),
            .ovr()
        );
    end
    
    // Second layer of addition (final sum(wixi))
    if (N_INPUTS > 2) begin : ADD_STAGE2
        qadd #(.Q(2*Q), .N(2*DATA_WIDTH)) final_adder (
            .a(sum_stage1[0]),
            .b(sum_stage1[1]),
            .c(sum_stage2),
            .ovr()
        );
    end else begin
        assign sum_stage2 = sum_stage1[0];
    end
endgenerate

// Stage 4: Bias Addition
wire [2*DATA_WIDTH-1:0] bias_ext = {bias_buf, {Q{1'b0}}};
wire [2*DATA_WIDTH-1:0] sum_with_bias_wire;

qadd #(.Q(2*Q), .N(2*DATA_WIDTH)) bias_adder (
    .a(sum_stage2),
    .b(bias_ext),
    .c(sum_with_bias_wire),
    .ovr()
);

reg [DATA_WIDTH-1:0] sum_with_bias;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) sum_with_bias <= 0;
    else begin
        sum_with_bias <= sum_with_bias_wire[Q +: DATA_WIDTH];
    end
end

// Stage 5: Activation Function
wire signed [DATA_WIDTH-1:0] tanh_out, sigmoid_out;

tanh #(.Q(Q), .N(DATA_WIDTH)) tanh_inst (
    .x(sum_with_bias),
    .y(tanh_out)
);

sigmoid #(.Q(Q), .N(DATA_WIDTH)) sigmoid_inst (
    .x(sum_with_bias),
    .y(sigmoid_out)
);

// Activation function selection
reg signed [DATA_WIDTH-1:0] af_result;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) af_result <= 0;
    else af_result <= af_sel ? sigmoid_out : tanh_out;
end

// Stage 5: Output Buffering
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) out <= 0;
    else out <= af_result;
end

endmodule

`timescale 1ns/1ps

module tb_neuron();

parameter Q = 24;
parameter N_INPUTS = 4;
parameter DATA_WIDTH = 32;
parameter CLK_PERIOD = 50;  // 50ns

reg clk;
reg rst_n;
reg af_sel;

reg signed [N_INPUTS*DATA_WIDTH-1:0] x_packed;
reg signed [N_INPUTS*DATA_WIDTH-1:0] w_packed;
reg signed [DATA_WIDTH-1:0] bias;
wire signed [DATA_WIDTH-1:0] out;

reg signed [DATA_WIDTH-1:0] x0, x1, x2, x3;
reg signed [DATA_WIDTH-1:0] w0, w1, w2, w3;

neuron #(
    .Q(Q),
    .N_INPUTS(N_INPUTS),
    .DATA_WIDTH(DATA_WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .af_sel(af_sel),
    .x_packed(x_packed),
    .w_packed(w_packed),
    .bias(bias),
    .out(out)
);

always #(CLK_PERIOD/2) clk = ~clk;

always @(*) begin
    x_packed = {x3, x2, x1, x0};
    w_packed = {w3, w2, w1, w0};
end

initial begin
    clk = 0;
    rst_n = 1;
    af_sel = 0;
    bias = 0;
    x0 = 0; x1 = 0; x2 = 0; x3 = 0;
    w0 = 0; w1 = 0; w2 = 0; w3 = 0;

    $display("\n[Stage 0] Applying reset...");
    rst_n = 0;
    #(CLK_PERIOD*2);
    rst_n = 1;
    #(CLK_PERIOD);
    
    $display("\nMAC operation with tanh");
    af_sel = 0;  // tanh
    
    x0 = 32'h01000000;  // 1.0
    x1 = 32'h02000000;  // 2.0
    x2 = 32'h03000000;  // 3.0
    x3 = 32'h04000000;  // 4.0
    
    w0 = 32'h01000000;  // 1.0
    w1 = 32'h01000000;  // 1.0
    w2 = 32'h01000000;  // 1.0
    w3 = 32'h01000000;  // 1.0
    
    bias = 32'hFC000000;  // -4.0 

    #CLK_PERIOD;
    $display("[Stage 1] Inputs buffered");
    
    #CLK_PERIOD;
    $display("[Stage 2] Products calculated");
    
    #CLK_PERIOD; 
    $display("[Stage 3] Sum with bias: 6.0");
    
    #CLK_PERIOD;
    $display("[Stage 4] Applying tanh...");
    
    #CLK_PERIOD;
    $display("[Stage 5] Output: %h", out);
    if(out >= 32'h00FFFF00 && out <= 32'h01000000) 
        $display("Tanh test PASSED");
    else
        $display("Tanh test FAILED");

    $display("\n[Test Case 2] Sigmoid activation");
    af_sel = 1;
    
    #(CLK_PERIOD*5);
    
    $display("[Stage 5] Output: %h", out);
    if(out >= 32'h00FF0000 && out <= 32'h00FFFFFF)
        $display("Sigmoid test PASSED");
    else
        $display("Sigmoid test FAILED");
    
    $finish;
end

always @(posedge clk) begin
    $display("Cycle %0d:", $time/CLK_PERIOD);
    $display("Inputs: %h %h %h %h", x0, x1, x2, x3);
    $display("Weights: %h %h %h %h", w0, w1, w2, w3);
    $display("Bias: %h", bias);
end

endmodule


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

module qadd #(
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
	if(a[N-1] == b[N-1]) begin		
        sum_mag = a[N-2:0] + b[N-2:0];		
		res[N-2:0] = a[N-2:0] + b[N-2:0];	 	
		res[N-1] = a[N-1];				
        ovr_reg = sum_mag[N-1];
	    end							
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
    localparam THRESHOLD = ( (1 << (N-1)) - 1 ) << Q;

    always @(*) begin
        magnitude_product = i_multiplicand[N-2:0] * i_multiplier[N-2:0];
        sign_bit = i_multiplicand[N-1] ^ i_multiplier[N-1];
        ovr = (magnitude_product > THRESHOLD);
    end

    assign o_result = {sign_bit, magnitude_product};

endmodule

module sigmoid #(
    parameter Q = 24,
    parameter N = 32
) (
    input [N-1:0] x,
    output [N-1:0] y
);
    // Thresholds
    localparam [N-1:0] T_1       = 32'b00000001000000000000000000000000; // 1.0
    localparam [N-1:0] T_2       = 32'b00000010000000000000000000000000; // 2.0
    localparam [N-1:0] T_3       = 32'b00000011000000000000000000000000; // 3.0
    localparam [N-1:0] T_4_5     = 32'b00000100100000000000000000000000; // 4.5
    localparam [N-1:0] T_8       = 32'b00001000000000000000000000000000; // 8.0

    // Coefficients for the piecewise linear approximation
    localparam signed [N-1:0] SLOPE1    = 32'b00000000000000001010010100100111; // 0.00252
    localparam signed [N-1:0] INTERCEPT1= 32'b00000000000001001100110011001101; // 0.01875
    localparam signed [N-1:0] SLOPE2    = 32'b00000000000001100000111100111101; // 0.02367
    localparam signed [N-1:0] INTERCEPT2= 32'b00000000000111010010110100100011; // 0.11397
    localparam signed [N-1:0] SLOPE3    = 32'b00000000000100011101101100100011; // 0.06975
    localparam signed [N-1:0] INTERCEPT3= 32'b00000000010000001000111110000110; // 0.25219
    localparam signed [N-1:0] SLOPE4    = 32'b00000000001001011111111000110011; // 0.14841
    localparam signed [N-1:0] INTERCEPT4= 32'b00000000011010001101010110100110; // 0.40951
    localparam signed [N-1:0] SLOPE5    = 32'b00000000001111010010100010001101; // 0.2389
    localparam signed [N-1:0] INTERCEPT5= 32'b00000000100000000000000000000000; // 0.5
    localparam signed [N-1:0] SLOPE6    = 32'b00000000001001011111111000110011; // 0.14841
    localparam signed [N-1:0] INTERCEPT6= 32'b00000000100101110010101001011010; // 0.59049
    localparam signed [N-1:0] SLOPE7    = 32'b00000000000100011101101100100011; // 0.06975
    localparam signed [N-1:0] INTERCEPT7= 32'b00000000101111110111000001111010; // 0.74781
    localparam signed [N-1:0] SLOPE8    = 32'b00000000000001100000111100111101; // 0.02367
    localparam signed [N-1:0] INTERCEPT8= 32'b00000000111000101101001011011101; // 0.88603
    localparam signed [N-1:0] SLOPE9    = 32'b00000000000000001010010100100111; // 0.00252
    localparam signed [N-1:0] INTERCEPT9= 32'b00000000111110110011001100110011; // 0.98125

    reg [N-1:0] slope;
    reg [N-1:0] intercept;
    wire [2*N-1:0] product;
    wire [N-1:0] product_trunc;
    wire [N-1:0] sum;
    wire ovr_mult, ovr_add;
    
    wire [N-2:0] x_mag = x[N-2:0];
    wire x_sign = x[N-1];
    
    // coefficient selection logic
    always @(*) begin
        if (x_sign == 1'b1) begin  
            if (x_mag >= T_8[N-2:0]) begin  // |x| >= 8.0
                slope = 32'b00000000000000000000000000000000;  // 0
                intercept = 32'b00000000000000000000000000000000;  // 0
            end else if (x_mag >= T_4_5[N-2:0] && x_mag < T_8[N-2:0]) begin  // 4.5 <= |x| < 8.0
                slope = SLOPE1;
                intercept = INTERCEPT1;
            end else if (x_mag >= T_3[N-2:0] && x_mag < T_4_5[N-2:0]) begin  // 3.0 <= |x| < 4.5
                slope = SLOPE2;
                intercept = INTERCEPT2;
            end else if (x_mag >= T_2[N-2:0] && x_mag < T_3[N-2:0]) begin  // 2.0 <= |x| < 3.0
                slope = SLOPE3;
                intercept = INTERCEPT3;
            end else if (x_mag >= T_1[N-2:0] && x_mag < T_2[N-2:0]) begin  // 1.0 <= |x| < 2.0
                slope = SLOPE4;
                intercept = INTERCEPT4;
            end else begin  // 0 < |x| < 1.0
                slope = SLOPE5;
                intercept = INTERCEPT5;
            end
        end else begin
            if (x_mag >= T_8[N-2:0]) begin  // x >= 8.0
                slope = 32'b00000000000000000000000000000000;  // 0
                intercept = 32'b00000001000000000000000000000000;  // 1.0
            end else if (x_mag >= T_4_5[N-2:0] && x_mag < T_8[N-2:0]) begin  // 4.5 <= x < 8.0
                slope = SLOPE9;
                intercept = INTERCEPT9;
            end else if (x_mag >= T_3[N-2:0] && x_mag < T_4_5[N-2:0]) begin  // 3.0 <= x < 4.5
                slope = SLOPE8;
                intercept = INTERCEPT8;
            end else if (x_mag >= T_2[N-2:0] && x_mag < T_3[N-2:0]) begin  // 2.0 <= x < 3.0
                slope = SLOPE7;
                intercept = INTERCEPT7;
            end else if (x_mag >= T_1[N-2:0] && x_mag < T_2[N-2:0]) begin  // 1.0 <= x < 2.0
                slope = SLOPE6;
                intercept = INTERCEPT6;
            end else begin  // 0 <= x < 1.0
                slope = SLOPE5;
                intercept = INTERCEPT5;
            end
        end
    end

    qmult #(.Q(Q), .N(N)) mult (
        .i_multiplicand(x),
        .i_multiplier(slope),
        .o_result(product),
        .ovr(ovr_mult)
    );

    assign product_trunc = {product[2*N-1], product[Q+N-2:Q]};

    qadd #(.Q(Q), .N(N)) add (
        .a(product_trunc),
        .b(intercept),
        .c(sum),
        .ovr(ovr_add)
    );

    assign y = (x_sign == 1'b1 && x_mag >= T_8[N-2:0]) ? 32'b00000000000000000000000000000000 :  // 0.0 for x <= -8.0
               (x_sign == 1'b0 && x_mag >= T_8[N-2:0]) ? 32'b00000001000000000000000000000000 :  // 1.0 for x >= 8.0
               sum;
endmodule

module tanh #(
    parameter Q = 24,
    parameter N = 32
) (
    input [N-1:0] x,
    output [N-1:0] y
);
    localparam [N-1:0] TWO       = 32'b00000010000000000000000000000000; // +2.0
    localparam [N-1:0] ONE       = 32'b00000001000000000000000000000000; // +1.0
    localparam [N-1:0] NEG_ONE   = 32'b10000001000000000000000000000000; // -1.0
    
    wire [2*N-1:0] doubled_x;
    wire [N-1:0] sigmoid_result;
    wire [2*N-1:0] scaled_sigmoid;
    wire [N-1:0] final_result;
    
    qmult #(.Q(Q), .N(N)) double_mult (
        .i_multiplicand(x),
        .i_multiplier(TWO),
        .o_result(doubled_x), 
        .ovr()
    );

    sigmoid #(.Q(Q), .N(N)) sigmoid_inst (
        .x(doubled_x[N-1:0]), 
        .y(sigmoid_result)
    );
    
    qmult #(.Q(Q), .N(N)) scale_mult (
        .i_multiplicand(sigmoid_result),
        .i_multiplier(TWO),
        .o_result(scaled_sigmoid),
        .ovr()
    );
    
    qadd #(.Q(Q), .N(N)) subtr (
        .a(scaled_sigmoid[N-1:0]),
        .b(ONE),  
        .c(final_result),
        .ovr()
    );
    
    assign y = final_result[N-1] ? 
        {1'b1, final_result[N-2:0]} : 
        final_result;
    
endmodule
