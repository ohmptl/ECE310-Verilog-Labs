`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ohm Patel
// 
// Create Date: 11/16/2025 01:03:08 AM
// Design Name: mult_seq_8x8_tb
// Assign Name: ECE 310 Lab 8
// Description: A verilog implementation of a
//              8x8 multiplier testbench
// 
//////////////////////////////////////////////////////////////////////////////////

module mult_seq_8x8_tb;

    reg clock;
    reg reset;
    reg [7:0] multiplier;
    reg [7:0] multiplicand;
    wire [15:0] product;

    mult_seq_8x8 dut(multiplier, multiplicand, product, reset, clock);
    
    initial clock = 0;
    always #5 clock = ~clock;

    initial begin

        reset = 0;
        multiplier = 8'd0;
        multiplicand = 8'd0;

        #20;

        // Test vector 1: 123 * 45 = 5535
        multiplier   = 8'd123;
        multiplicand = 8'd45;
        #10;
        reset = 1; #10;
        reset = 0;
        #100;
        $display("TV1: %d * %d = %d (expected 5535)", multiplier, multiplicand, product);

        #20;

        // Test vector 2: 200 * 200 = 40000
        multiplier   = 8'd200;
        multiplicand = 8'd200;
        #10;
        reset = 1; #10;
        reset = 0;
        #100;
        $display("TV2: %d * %d = %d (expected 40000)", multiplier, multiplicand, product);
        
        $finish;
        
    end

endmodule
