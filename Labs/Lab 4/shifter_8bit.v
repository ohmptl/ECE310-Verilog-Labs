`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ohm Patel
// 
// Create Date: 10/05/2025 03:29:19 PM
// Design Name: 8-bit shifter
// Assign Name: ECE 310 Lab 4
// Description: A dataflow implementation of an 
//              8-bit shifter
// 
//////////////////////////////////////////////////////////////////////////////////

module dff(
    output reg Q, 
    input D, clock);

always @(posedge clock)
    Q = D;

endmodule

module shifter_8bit(
    output [7:0] d_out,
    input [7:0] d_in,
    input [2:0] op,         // 3 bits to allow for 7 different combos
    input capture, clock);

wire [7:0] muxOut = 
    (op == 3'b000) ? {d_in[6:0], 1'b0} :    // Shift left 1
    (op == 3'b001) ? {d_in[5:0], 2'b00} :   // Shift left 2
    (op == 3'b010) ? {1'b0, d_in[7:1]} :    // Shift right 1
    (op == 3'b011) ? {2'b00, d_in[7:2]} :   // Shift right 2
    (op == 3'b100) ? {d_in[6:0], d_in[7]} : // Rotate left 1
    (op == 3'b101) ? {d_in[0], d_in[7:1]} : // Rotate right 1
    (op == 3'b110) ? d_out : 8'b00000000;   // Hold old, if no selection occurs then set out to 0

wire [7:0] regInput = (~capture) ? muxOut : d_out;

dff bit0 (d_out[0], regInput[0], clock);
dff bit1 (d_out[1], regInput[1], clock);
dff bit2 (d_out[2], regInput[2], clock);
dff bit3 (d_out[3], regInput[3], clock);
dff bit4 (d_out[4], regInput[4], clock);
dff bit5 (d_out[5], regInput[5], clock);
dff bit6 (d_out[6], regInput[6], clock);
dff bit7 (d_out[7], regInput[7], clock);

endmodule
