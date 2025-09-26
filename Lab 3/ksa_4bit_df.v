`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ohm Patel
// 
// Create Date: 09/25/2025 2:20:20 PM
// Design Name: Lab 3 4-bit Kogge-Stone adder
// Module Name: ksa_4bit_df
// Description: A design flow implementation of an 
//              4-bit Kogge-Stone adder
// 
//////////////////////////////////////////////////////////////////////////////////

module ksa_4bit_df(
    input wire [3:0] A, B,
    output wire [3:0] S,
    output wire Cout
    );


wire [3:0] g0, p0, g1, p1, g2, p2, C;

assign p0 = A ^ B;
assign g0 = A & B;

// Stage 1

assign p1[0] = p0[0];
assign g1[0] = g0[0];

assign p1[1] = p0[1] & p0[0];
assign g1[1] = (p0[1] & g0[0]) | g0[1];

assign p1[2] = p0[2] & p0[1];
assign g1[2] = (p0[2] & g0[1]) | g0[2];

assign p1[3] = p0[3] & p0[2];
assign g1[3] = (p0[3] & g0[2]) | g0[3];

// Stage 2 

assign p2[0] = p1[0];
assign g2[0] = g1[0];

assign p2[1] = p1[1];
assign g2[1] = g1[1];

assign p2[2] = p1[2] & p1[0];
assign g2[2] = (p1[2] & g1[0]) | g1[2];

assign p2[3] = p1[3] & p1[1];
assign g2[3] = (p1[3] & g1[1]) | g1[3];


// Stage 3

assign C[0] = 1'b0;  // no carry-in
assign C[1] = g1[0]; // carry into bit1
assign C[2] = g1[1]; // carry into bit2
assign C[3] = g2[2]; // carry into bit3
assign Cout = g2[3]; // carry out

// Assign Sum output

assign S[0] = p0[0] ^ C[0];
assign S[1] = p0[1] ^ C[1];
assign S[2] = p0[2] ^ C[2];
assign S[3] = p0[3] ^ C[3];

endmodule