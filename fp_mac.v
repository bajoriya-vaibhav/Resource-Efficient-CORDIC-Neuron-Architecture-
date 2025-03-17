module qmac #(
    parameter Q = 0,       
    parameter N = 2        
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

module Test_qmac;

    reg clk;
    reg reset;
    reg [1:0] a;
    reg [1:0] b;
    wire [3:0] result;
    wire overflow;

    // Instantiate the MAC module
    qmac #(.Q(0), .N(2)) uut (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .result(result),
        .overflow(overflow)
    );

    reg expected_ovf;
    integer expected_accum;
    integer product;
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        
        // Initialize
        a = 0;
        b = 0;
        expected_accum = 0;
        expected_ovf = 0;

        // Reset sequence
        reset = 1;
        @(negedge clk);
        reset = 0;
        @(negedge clk);

        $display("Starting MAC tests...\n");

        // Test 1: Basic MAC (1*1)
        a = 2'b01;  // 1
        b = 2'b01;  // 1
        @(negedge clk);  // Wait only one clock cycle
        product = $signed(a) * $signed(b);
        expected_accum += product;
        expected_ovf = (expected_accum > 7) || (expected_accum < -8);
        print_results(1);

        // Test 2: Accumulate again (1+1)
        a = 2'b01;
        b = 2'b01;
        @(negedge clk);
        product = $signed(a) * $signed(b);
        expected_accum += product;
        expected_ovf = (expected_accum > 7) || (expected_accum < -8);
        print_results(2);

        // Test 3: Multiply (1*-1)
        a = 2'b01;  // 1
        b = 2'b11;  // -1
        @(negedge clk);
        product = $signed(a) * $signed(b);
        expected_accum += product;
        expected_ovf = (expected_accum > 7) || (expected_accum < -8);
        print_results(3);

        // Test 4: Multiply negatives (-1*-1)
        a = 2'b11;
        b = 2'b11;
        @(negedge clk);
        product = $signed(a) * $signed(b);
        expected_accum += product;
        expected_ovf = (expected_accum > 7) || (expected_accum < -8);
        print_results(4);

        // Test 5: Reset test
        reset = 1;
        @(negedge clk);
        reset = 0;
        expected_accum = 0;
        expected_ovf = 0;
        @(negedge clk);
        $display("Test 5: Reset functionality");
        print_results(5);

        // test 6
        a = 2'b01;
        b = 2'b11;
        @(negedge clk);
        product = $signed(a) * $signed(b);
        expected_accum += product;
        expected_ovf = (expected_accum > 7) || (expected_accum < -8);
        print_results(6);

        $display("\nAll tests completed!");
        $finish;
    end

    task print_results;
        input integer test_num;
        begin
            $display("Test %0d:", test_num);
            $display("a = %b (%0d), b = %b (%0d)", 
                     a, $signed(a), b, $signed(b));
            $display("Result = %b (%0d), Overflow = %b",
                     result, $signed(result), overflow);
            $display("-----------------------------------");
        end
    endtask

endmodule