`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ohm Patel
// 
// Create Date: 10/26/2025 07:12:56 PM
// Design Name: vending_25c_moore TESTBENCH
// Assign Name: ECE 310 Lab 5
// Description: Testbench for vending_25c_moore.v
// 
//////////////////////////////////////////////////////////////////////////////////



module vending_25c_moore_tb;
    reg clock, reset_n, D, Q;
    wire P, C;

    vending_25c_moore dut (
        .clock(clock), .reset_n(reset_n),
        .D(D), .Q(Q), .P(P), .C(C)
        );

    initial begin
        clock = 1'b0;
        forever #5 clock = ~clock;
    end

    initial begin
        
        // Reset
        reset_n = 0;
        D = 1'b0; Q = 1'b0; #10;
        reset_n = 1; #10;
        
        // Testcase 1
        D = 1'b0; Q = 1'b1; #10; // Input quarter (25)
        D = 1'b0; Q = 1'b0; #20; // Clear input
        
        // Reset
        reset_n = 0;
        D = 1'b0; Q = 1'b0; #10;
        reset_n = 1; #10;
        
        // Testcase 2
        D = 1'b1; Q = 1'b0; #10; // Input dime (10)
        D = 1'b1; Q = 1'b0; #10; // Input dime (20)
        D = 1'b1; Q = 1'b0; #10; // Input dime (30)
        D = 1'b0; Q = 1'b0; #50; // Clear input

        // Reset
        reset_n = 0;
        D = 1'b0; Q = 1'b0; #10;
        reset_n = 1; #10;

        // Testcase 3
        D = 1'b1; Q = 1'b0; #10; // Input dime (10)
        D = 1'b1; Q = 1'b1; #10; // Invalid Input
        D = 1'b0; Q = 1'b0; #10; // Invalid Input
        D = 1'b0; Q = 1'b1; #10; // Input quarter (35)
        D = 1'b0; Q = 1'b0; #50; // Clear input

        // Reset
        reset_n = 0;
        D = 1'b0; Q = 1'b0; #10;
        reset_n = 1; #10;

        // Testcase 4
        D = 1'b1; Q = 1'b0; #10; // Input dime (10)
        D = 1'b1; Q = 1'b0; #10; // Input dime (20)
        D = 1'b0; Q = 1'b1; #10; // Input quarter (45)
        D = 1'b0; Q = 1'b0; #50; // Clear input
        
    $finish;
    end
        
endmodule