/*
This module combines the two modules used for the calculation of the MAC and hyperbolic tangent
function to complete the architecture of the neuron.
This code has been written in FSM design to maximise resource sharing optimisation during 
RTL synthesis. 
*/

module cordic_combined #(
    parameter MAC_ITERATIONS = 24,
    parameter INT_SIZE = 8,
    parameter FLOAT_SIZE = 24
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire signed [31:0] x_in,  
    input wire signed [31:0] y_in,  
    input wire signed [31:0] z_in,  
    output wire signed [31:0] mac_x_out, 
    output wire signed [31:0] mac_y_out, // this signal is used to display mac output during simulation
    output wire signed [31:0] tanh_out,
    output reg done
);

    // State definitions
    localparam IDLE = 2'd0;
    localparam MAC_PROCESS = 2'd1;
    localparam TANH_PROCESS = 2'd2;
    localparam COMPLETE = 2'd3;
    
    reg [1:0] current_state, next_state;
    
    // Signals for MAC operation
    reg mac_rst;
    
    // Signals for tanh operation
    reg tanh_en;
    
    // Instantiate the MAC module (cordic_linear_mode)
    cordic_linear_mode #(
        .ITERATIONS(MAC_ITERATIONS)
    ) mac_inst (
        .clk(clk),
        .rst(mac_rst),
        .x_in(x_in),
        .y_in(y_in),
        .z_in(z_in),
        .x_out(mac_x_out),
        .y_out(mac_y_out)
    );
    
    // Instantiate the tanh module
    cordictanh tanh_inst (
        .CLK(clk),
        .EN(tanh_en),
        .z(mac_y_out),
        .out(tanh_out)
    );
    
    // Counter for MAC iterations
    reg [7:0] mac_counter;
    reg mac_complete;
    
    // Timer for tanh process (to determine when it's complete)
    reg [7:0] tanh_counter;
    localparam TANH_CYCLES = 50; // Adjust based on actual cycles needed for tanh to complete
    
    // State machine - sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            mac_counter <= 0;
            tanh_counter <= 0;
            mac_complete <= 0;
            done <= 0;
        end else begin
            current_state <= next_state;
            
            // MAC counter logic
            if (current_state == MAC_PROCESS) begin
                mac_counter <= mac_counter + 1;
                if (mac_counter >= MAC_ITERATIONS - 1) begin
                    mac_complete <= 1;
                end
            end else if (current_state == IDLE) begin
                mac_counter <= 0;
                mac_complete <= 0;
            end
            
            // Tanh counter logic
            if (current_state == TANH_PROCESS) begin
                tanh_counter <= tanh_counter + 1;
            end else if (current_state == IDLE) begin
                tanh_counter <= 0;
            end
            
            // Done signal
            if (current_state == COMPLETE) begin
                done <= 1;
            end else begin
                done <= 0;
            end
        end
    end
    
    // State machine - combinational logic
    always @(*) begin
        // Default values
        mac_rst = 0;
        tanh_en = 0;
        
        case (current_state)
            IDLE: begin
                mac_rst = 1; // Reset MAC module
                if (start) begin
                    next_state = MAC_PROCESS;
                end else begin
                    next_state = IDLE;
                end
            end
            
            MAC_PROCESS: begin
                mac_rst = 0; // MAC module active
                if (mac_complete) begin
                    next_state = TANH_PROCESS;
                end else begin
                    next_state = MAC_PROCESS;
                end
            end
            
            TANH_PROCESS: begin
                if (tanh_counter == 0) begin
                    tanh_en = 1; // Start tanh calculation
                end else begin
                    tanh_en = 0; // Keep tanh running
                end
                
                if (tanh_counter >= TANH_CYCLES) begin
                    next_state = COMPLETE;
                end else begin
                    next_state = TANH_PROCESS;
                end
            end
            
            COMPLETE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

endmodule