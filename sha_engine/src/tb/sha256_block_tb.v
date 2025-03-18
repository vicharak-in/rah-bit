`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.01.2025 11:01:29
// Design Name: 
// Module Name: sha256_block_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_sha256_block;

    // Testbench signals
    reg clk;
    reg rst;
    reg [255:0] H_in;
    reg [511:0] M_in;
    reg input_valid;
    wire [255:0] H_out;
    wire output_valid;

    // Instantiate the DUT (Device Under Test)
    sha256_block dut (
        .clk(clk),
        .rst(rst),
        .H_in(H_in),
        .M_in(M_in),
        .input_valid(input_valid),
        .H_out(H_out),
        .output_valid(output_valid)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz clock

    // Test stimulus
    initial begin
        // Initialize inputs
        rst = 0;
        input_valid = 0;
        H_in = 256'h6a09e667bb67ae85_3c6ef372a54ff53a_510e527f9b05688c_1f83d9ab5be0cd19;
        M_in = 512'h6162638000000000_0000000000000000_0000000000000000_0000000000000000_0000000000000000_0000000000000000_0000000000000000_0000000000000018; // "abc"

        // Wait for global reset to finish
        #10;

        // Apply input and start processing
        input_valid = 1;
        #10;
        input_valid = 0;

        // Wait for processing to complete
        wait(output_valid == 1);

        // Display the output hash
        $display("H_out: %h", H_out);

        // Finish simulation
        #20;
        $stop;
    end

endmodule
