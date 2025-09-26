`timescale 1ns / 1ps

// Full adder module
module full_adder_struct(
    output S, Cout,             // Define outputs
    input  A, B, Cin            // Define inputs
);
    wire w1, w2, w3;            // Internal Wires
    xor(w1, A, B);              // First XOR gate
    xor(S, w1, Cin);            // Second XOR output S (Sum)
    and(w2, A, B);              // First AND gate
    and(w3, w1, Cin);           // Second AND gate
    or(Cout, w2, w3);           // First OR output Cout (Carry Out)

endmodule

// 4-Bit RCA
module rca_4bit(
    output [3:0] S,             // Define Outputs
    output Cout,
    input [3:0] A, B            // Define Inputs
);

    wire c1, c2, c3;
    full_adder_struct fa0 (S[0], c1, A[0], B[0], 1'b0);
    full_adder_struct fa1 (S[1], c2, A[1], B[1], c1);
    full_adder_struct fa2 (S[2], c3, A[2], B[2], c2);
    full_adder_struct fa3 (S[3], Cout, A[3], B[3], c3);

endmodule

// Testbench for 4-bit RCA
module rca_4bit_tb;
    reg [3:0] A, B;
    wire [3:0] S;
    wire Cout;
    rca_4bit dut(S, Cout, A, B);
    
    initial
    begin
    
        A = 4'b0000; B = 4'b0000; // Baseline all zero case to ensure no odd outputs.
        #10 $display("A: %b B: %b S: %b Cout: %b ", A, B, S, Cout);
        
        A = 4'b1111; B = 4'b1111; // Max vals to test overflow and carry behaviour.
        #10 $display("A: %b B: %b S: %b Cout: %b ", A, B, S, Cout);
        
        A = 4'b1111; B = 4'b0001; // Carry propagation test to see if all 4-bits are properly carried
        #10 $display("A: %b B: %b S: %b Cout: %b ", A, B, S, Cout);
        
        A = 4'b1010; B = 4'b0110; // Mixed test mixing both carry and non-carry behaviour.
        #10 $display("A: %b B: %b S: %b Cout: %b ", A, B, S, Cout);
        
        A = 4'b0111; B = 4'b0001; // Testing carry propagation to stop at Cout.
        #10 $display("A: %b B: %b S: %b Cout: %b ", A, B, S, Cout);
        
        A = 4'b1000; B = 4'b1000; // Testing MSB addition.
        #10 $display("A: %b B: %b S: %b Cout: %b ", A, B, S, Cout);
        
    $finish;
    end


endmodule 
