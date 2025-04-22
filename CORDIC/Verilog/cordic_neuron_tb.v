`timescale 1ns / 1ps

module cordic_combined_tb;
    // Parameters
    parameter CLK_PERIOD = 10; // 10ns = 100MHz
    parameter INT_SIZE = 8;
    parameter FLOAT_SIZE = 24;
    
    // Signals
    reg clk;
    reg rst;
    reg start;
    reg signed [31:0] x_in;
    reg signed [31:0] y_in;
    reg signed [31:0] z_in;
    wire signed [31:0] mac_x_out;
    wire signed [31:0] mac_y_out;
    wire signed [31:0] tanh_out;
    wire done;
    
    // Instantiate the unit under test (UUT)
    cordic_combined uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .x_in(x_in),
        .y_in(y_in),
        .z_in(z_in),
        .mac_x_out(mac_x_out),
        .mac_y_out(mac_y_out),
        .tanh_out(tanh_out),
        .done(done)
    );
    
    // Clock generation
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Helper function to convert fixed-point to real
    real fixed_to_real;
    function real to_real;
        input signed [31:0] fixed;
        begin
            to_real = $itor(fixed) / (2.0 ** FLOAT_SIZE);
        end
    endfunction
    
    // Temp storage for MAC results
    reg signed [31:0] mac_x_result;
    reg signed [31:0] mac_y_result;
    
    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        start = 0;
        x_in = 0;
        y_in = 0;
        z_in = 0;
        
        // Reset the system
        #(CLK_PERIOD*2);
        rst = 0;
        #(CLK_PERIOD);
        
        // Test case 1: Simple MAC followed by tanh
        // x_in = 1.5 in Q8.24 format
        x_in = 32'h01_800000;
        // y_in = 0.5 in Q8.24 format
        y_in = 32'h00_800000;
        // z_in = 0.75 in Q8.24 format
        z_in = 32'h00_C00000;
        
        $display("Test Case 1:");
        $display("x_in = %f, y_in = %f, z_in = %f", to_real(x_in), to_real(y_in), to_real(z_in));
        
        // Start the computation
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        
        // Wait until MAC processing is complete
        wait(uut.mac_complete);
        #(CLK_PERIOD);
        
        // Store MAC results
        mac_x_result = mac_x_out;
        mac_y_result = mac_y_out;
        
        // Wait for final completion
        wait(done);
        #(CLK_PERIOD);
        
        // Display both MAC and tanh results
        $display("MAC x_out = %f", to_real(mac_x_result));
        $display("MAC y_out = %f", to_real(mac_y_result));
        $display("tanh_out = %f", to_real(tanh_out));
        $display("tanh(MAC y_out) = %f", to_real(tanh_out));
        
        // Test case 2: Another input set
        #(CLK_PERIOD*5);
        
        // x_in = 2.0 in Q8.24 format
        x_in = 32'h02_000000;
        // y_in = -1.0 in Q8.24 format
        y_in = 32'hFF_000000;
        // z_in = 1.5 in Q8.24 format
        z_in = 32'h01_800000;
        
        $display("\nTest Case 2:");
        $display("x_in = %f, y_in = %f, z_in = %f", to_real(x_in), to_real(y_in), to_real(z_in));
        
        // Start the computation
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        
        // Wait until MAC processing is complete
        wait(uut.mac_complete);
        #(CLK_PERIOD);
        
        // Store MAC results
        mac_x_result = mac_x_out;
        mac_y_result = mac_y_out;
        
        // Wait for final completion
        wait(done);
        #(CLK_PERIOD);
        
        // Display both MAC and tanh results
        $display("MAC x_out = %f", to_real(mac_x_result));
        $display("MAC y_out = %f", to_real(mac_y_result));
        $display("tanh_out = %f", to_real(tanh_out));
        $display("tanh(MAC y_out) = %f", to_real(tanh_out));
        
        // Test case 3: Larger values
        #(CLK_PERIOD*5);
        
        // x_in = 3.0 in Q8.24 format
        x_in = 32'h03_000000;
        // y_in = 2.0 in Q8.24 format
        y_in = 32'h02_000000;
        // z_in = 0.5 in Q8.24 format
        z_in = 32'h00_800000;
        
        $display("\nTest Case 3:");
        $display("x_in = %f, y_in = %f, z_in = %f", to_real(x_in), to_real(y_in), to_real(z_in));
        
        // Start the computation
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        
        // Wait until MAC processing is complete
        wait(uut.mac_complete);
        #(CLK_PERIOD);
        
        // Store MAC results
        mac_x_result = mac_x_out;
        mac_y_result = mac_y_out;
        
        // Wait for final completion
        wait(done);
        #(CLK_PERIOD);
        
        // Display both MAC and tanh results
        $display("MAC x_out = %f", to_real(mac_x_result));
        $display("MAC y_out = %f", to_real(mac_y_result));
        $display("tanh_out = %f", to_real(tanh_out));
        $display("tanh(MAC y_out) = %f", to_real(tanh_out));
        
        // Test case 4: Negative result from MAC
        #(CLK_PERIOD*5);
        
        // x_in = -2.0 in Q8.24 format
        x_in = 32'hFE_000000;
        // y_in = 1.0 in Q8.24 format
        y_in = 32'h01_000000;
        // z_in = 2.0 in Q8.24 format
        z_in = 32'h02_000000;
        
        $display("\nTest Case 4:");
        $display("x_in = %f, y_in = %f, z_in = %f", to_real(x_in), to_real(y_in), to_real(z_in));
        
        // Start the computation
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        
        // Wait until MAC processing is complete
        wait(uut.mac_complete);
        #(CLK_PERIOD);
        
        // Store MAC results
        mac_x_result = mac_x_out;
        mac_y_result = mac_y_out;
        
        // Wait for final completion
        wait(done);
        #(CLK_PERIOD);
        
        // Display both MAC and tanh results
        $display("MAC x_out = %f", to_real(mac_x_result));
        $display("MAC y_out = %f", to_real(mac_y_result));
        $display("tanh_out = %f", to_real(tanh_out));
        $display("tanh(MAC y_out) = %f", to_real(tanh_out));
        
        // Run for a bit longer to see final output
        #(CLK_PERIOD*10);
        
        $finish;
    end
    
    // Monitor state changes
    initial begin
        $monitor("Time: %t, State: %d, MAC Complete: %b, Done: %b", 
                 $time, uut.current_state, uut.mac_complete, done);
    end

endmodule