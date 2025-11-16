`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ohm Patel
// 
// Create Date: 11/16/2025 01:03:08 AM
// Design Name: mult_seq_8x8
// Assign Name: ECE 310 Lab 8
// Description: A verilog implementation of a
//              8x8 multiplier
// 
//////////////////////////////////////////////////////////////////////////////////

module mult_seq_8x8(
    input  [7:0] multiplier, multiplicand,
    output reg [15:0] product,
    input reset, clock
);

    reg [7:0] multiplierReg;
    reg [15:0] multiplicandReg;
    reg [3:0] count;

    always @(posedge clock) begin
        if (reset) begin
            product <= 16'b0;
            multiplierReg <= multiplier;
            multiplicandReg <= {8'b0, multiplicand};
            count <= 4'd8;
        end 
        else if (count > 0) begin
            if (multiplierReg[0]) begin
                product <= product + multiplicandReg;
            end
            multiplicandReg <= multiplicandReg << 1;
            multiplierReg <= multiplierReg >> 1;
            count <= count - 1;
        end
    end

endmodule