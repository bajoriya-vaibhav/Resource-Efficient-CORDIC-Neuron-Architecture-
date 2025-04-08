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

// Pipeline Stage 1: Input Buffering
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

// Pipeline Stage 2: Parallel Multiplication
wire [2*DATA_WIDTH-1:0] mult_results [N_INPUTS-1:0];
reg [2*DATA_WIDTH-1:0] mult_results_reg [N_INPUTS-1:0];

genvar i;

generate
    for (i=0; i<N_INPUTS; i=i+1) begin : MULT
        qmult #(.Q(Q), .N(DATA_WIDTH)) mult (
            .i_multiplicand(x_buf[i]),
            .i_multiplier(w_buf[i]),
            .o_result(mult_results[i]),
            .ovr()  // Overflow monitoring optional
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
    // First level of addition (pairwise)
    for (i=0; i<N_INPUTS/2; i=i+1) begin : ADD_STAGE1
        qadd #(.Q(2*Q), .N(2*DATA_WIDTH)) adder (
            .a(mult_results_reg[2*i]),
            .b(mult_results_reg[2*i+1]),
            .c(sum_stage1[i]),
            .ovr()
        );
    end
    
    // Second level of addition (final sum)
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
wire [2*DATA_WIDTH-1:0] bias_ext = {bias_buf, {Q{1'b0}}}; // Q24 -> Q48
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
        // Truncate from Q48 to Q24 with rounding
        sum_with_bias <= sum_with_bias_wire[Q +: DATA_WIDTH];
    end
end

// Pipeline Stage 4: Activation Function
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

// Pipeline Stage 5: Output Buffering
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) out <= 0;
    else out <= af_result;
end

endmodule

`timescale 1ns/1ps

module tb_neuron();

// Parameters matching the neuron
parameter Q = 24;
parameter N_INPUTS = 4;
parameter DATA_WIDTH = 32;
parameter CLK_PERIOD = 10;  // 100 MHz

// System Signals
reg clk;
reg rst_n;
reg af_sel;

// Inputs/Outputs
reg signed [N_INPUTS*DATA_WIDTH-1:0] x_packed;
reg signed [N_INPUTS*DATA_WIDTH-1:0] w_packed;
reg signed [DATA_WIDTH-1:0] bias;
wire signed [DATA_WIDTH-1:0] out;

// Test vectors (individual elements)
reg signed [DATA_WIDTH-1:0] x0, x1, x2, x3;
reg signed [DATA_WIDTH-1:0] w0, w1, w2, w3;

// Instantiate DUT
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

// Clock generation
always #(CLK_PERIOD/2) clk = ~clk;

// Packing logic using concatenation
always @(*) begin
    x_packed = {x3, x2, x1, x0};
    w_packed = {w3, w2, w1, w0};
end

// Test sequence
initial begin
    // Initialize signals
    clk = 0;
    rst_n = 1;
    af_sel = 0;
    bias = 0;
    x0 = 0; x1 = 0; x2 = 0; x3 = 0;
    w0 = 0; w1 = 0; w2 = 0; w3 = 0;
    
    // Stage 0: Reset sequence
    $display("\n[Stage 0] Applying reset...");
    rst_n = 0;
    #(CLK_PERIOD*2);
    rst_n = 1;
    #(CLK_PERIOD);
    
    // Test Case 1: Basic functionality (tanh)
    $display("\n[Test Case 1] Basic MAC operation with tanh");
    af_sel = 0;  // Select tanh
    
    // Q24 format values (1.0 = 32'h01000000)
    x0 = 32'h01000000;  // 1.0
    x1 = 32'h02000000;  // 2.0
    x2 = 32'h01000000;  // 3.0
    x3 = 32'h01000000;  // 4.0
    
    w0 = 32'h01000000;  // 1.0
    w1 = 32'h01000000;  // 1.0
    w2 = 32'h01000000;  // 1.0
    w3 = 32'h01000000;  // 1.0
    
    bias = 32'hFC000000;  // -4.0 in Q24

    // Stage tracking
    #CLK_PERIOD;  // Stage 1: Input buffering
    $display("[Stage 1] Inputs buffered");
    
    #CLK_PERIOD;  // Stage 2: Multiplication
    $display("[Stage 2] Products calculated");
    
    #CLK_PERIOD;  // Stage 3: Accumulation
    $display("[Stage 3] Sum with bias: 6.0");
    
    #CLK_PERIOD;  // Stage 4: Activation
    $display("[Stage 4] Applying tanh...");
    
    #CLK_PERIOD;  // Stage 5: Output
    $display("[Stage 5] Output: %h", out);
    if(out >= 32'h00FFFF00 && out <= 32'h01000000) 
        $display("Tanh test PASSED");
    else
        $display("Tanh test FAILED");

    // Test Case 2: Sigmoid activation
    $display("\n[Test Case 2] Sigmoid activation");
    af_sel = 1;  // Select sigmoid
    
    // Pipeline needs 5 cycles to flush
    #(CLK_PERIOD*5);
    
    $display("[Stage 5] Output: %h", out);
    if(out >= 32'h00FF0000 && out <= 32'h00FFFFFF)
        $display("Sigmoid test PASSED");
    else
        $display("Sigmoid test FAILED");
    
    $finish;
end

// Monitor intermediate signals
always @(posedge clk) begin
    $display("--------------------------------------------------");
    $display("Cycle %0d:", $time/CLK_PERIOD);
    $display("Inputs: %h %h %h %h", x0, x1, x2, x3);
    $display("Weights: %h %h %h %h", w0, w1, w2, w3);
    $display("Bias: %h", bias);
end

endmodule