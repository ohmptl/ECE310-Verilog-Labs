`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ohm Patel
// 
// Create Date: 10/16/2025 05:09:41 PM
// Design Name: Project2
// Description: Performs (A+B) - (C+D) with 4 8bit inputs
// 
//////////////////////////////////////////////////////////////////////////////////

module datapath(
    input clock,
    input reset_n,
    input [7:0] d_in,
    input [1:0] op,
    input capture,
    output [8:0] result
);

    reg [7:0] A, B, C, D; // Store A, B, C, D
    wire [7:0] demuxA, demuxB, demuxC, demuxD;
    
    // Capture logic with d_in and op
    assign demuxA = (op == 2'b00 && capture) ? d_in : A;
    assign demuxB = (op == 2'b01 && capture) ? d_in : B;
    assign demuxC = (op == 2'b10 && capture) ? d_in : C;
    assign demuxD = (op == 2'b11 && capture) ? d_in : D;
    
    // DFF for A, B, C, D with reset
    always @(posedge clock) begin
        if (!reset_n) begin
            A <= 8'b0;
            B <= 8'b0;
            C <= 8'b0;
            D <= 8'b0;
        end 
        else begin
            A <= demuxA;
            B <= demuxB;
            C <= demuxC;
            D <= demuxD;
        end
    end

    wire [8:0] sumAB, sumCD; // Interwires for sums

    rca_8bit AB (sumAB, A, B); // Sum A and B
    rca_8bit CD (sumCD, C, D); // Sum C and D
    subtractor_9bit sub (result, sumAB, sumCD); // Subtract (A+B) - (C+D)

    
endmodule

//------------------------------------------------------------------------------
module controller(
    input clock,
    input reset_n,
    input capture,
    output valid
);

    reg [2:0] count; 
    reg done_d, valid_r;
    wire [2:0] next_count, subtracted_count;
    wire decrement, done;

    assign decrement = capture & (count != 3'b000);

    subtractor_3bit sub3 (subtracted_count, count, 3'b001);

    assign next_count = (!reset_n)  ? 3'b100 :           // reset to 4
                        (decrement) ? subtracted_count : // decrement on capture
                                    count;               // otherwise hold

    assign done = decrement & (count == 3'b001);

    always @(posedge clock) begin
        if (!reset_n) begin
            count   <= 3'b100;
            done_d  <= 1'b0;
            valid_r <= 1'b0;
        end else begin
            count   <= next_count;
            done_d  <= done;    // delay done by one cycle
            valid_r <= done_d;  // assert valid for only one cycle
        end
    end

    assign valid = valid_r;
    
endmodule

//------------------------------------------------------------------------------
module Project2(
    input reset_n,
    input clock,
    input [7:0] d_in,
    input [1:0] op,
    input capture,
    output [8:0] result,
    output valid
);

    datapath dp (clock, reset_n, d_in, op, capture, result);
    controller ctrl (clock, reset_n, capture, valid);

endmodule