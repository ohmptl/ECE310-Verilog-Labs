`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ohm Patel
// 
// Create Date: 09/25/2025 2:20:20 PM
// Design Name: Lab 3 4-bit Kogge-Stone adder TESTBENCH
// Module Name: ksa_4bit_tb
// Description: A test bench to test implementation 
//              of an 4-bit Kogge-Stone adder
// 
//////////////////////////////////////////////////////////////////////////////////


module ksa_4bit_tb;
    reg [3:0] A, B;
    wire [3:0] S;
    wire Cout;
    ksa_4bit_df dut(A, B, S, Cout);
    
    initial
    begin
    
        // 1) Baseline all zero case
        A = 4'b0000; B = 4'b0000;
        #10 $display("A: %b B: %b S: %b Cout: %b", A, B, S, Cout);

        // 2) Simple no carry case
        A = 4'b0001; B = 4'b0010; // 1 + 2 = 3
        #10 $display("A: %b B: %b S: %b Cout: %b", A, B, S, Cout);

        // 3) Carry generation within bit 0
        A = 4'b0001; B = 4'b0001; // 1 + 1 = 2
        #10 $display("A: %b B: %b S: %b Cout: %b", A, B, S, Cout);

        // 4) Carry propagate across multiple bits
        A = 4'b0111; B = 4'b0001; // 7 + 1 = 8
        #10 $display("A: %b B: %b S: %b Cout: %b", A, B, S, Cout);

        // 5) Overflow case (Cout = 1)
        A = 4'b1111; B = 4'b0001; // 15 + 1 = 16
        #10 $display("A: %b B: %b S: %b Cout: %b", A, B, S, Cout);

        // 6) Random mid-range values
        A = 4'b1010; B = 4'b0101; // 10 + 5 = 15
        #10 $display("A: %b B: %b S: %b Cout: %b", A, B, S, Cout);

        // 7) Max + Max
        A = 4'b1111; B = 4'b1111; // 15 + 15 = 30
        #10 $display("A: %b B: %b S: %b Cout: %b", A, B, S, Cout);
        
    $finish;
    end
endmodule 