`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ohm Patel
//
// Create Date: 11/16/2025 05:34:54 PM
// Design Name: Project3
// Description: Arithmetic Logic Unit 
//
//////////////////////////////////////////////////////////////////////////////////

module Project3(
    input wire clock,
    input wire reset,
    input wire din,
    output reg result
);

    localparam inReset  = 2'b00, inShift  = 2'b01;
    localparam outIdle  = 1'b0, outShift = 1'b1;

    reg [1:0] inState;
    reg outState;

    reg [40:0] regIN;        // SIPO
    reg [27:0] regOUT;       // PISO
    reg [4:0] count;

    reg op;
    reg [15:0] opA, opB;

    reg [3:0] A3, A2, A1, A0, B3, B2, B1, B0;
    reg [4:0] add0, add1, add2, add3, sub0, sub1, sub2, sub3;

    function [4:0] bcd_add;
        input [3:0] a, b;
        input cin;
        reg [4:0] sum;
        begin
            sum = a + b + cin;
            if (sum > 5'd9)
                sum = sum + 5'd6;
            bcd_add = sum;
        end
    endfunction

    // Input FSM (SIPO)
    always @(posedge clock) begin
        if (reset) begin
            inState <= inReset;
            regIN <= 41'b0;
            opA <= 16'd0;
            opB <= 16'd0;
            op <= 1'b0;
        end
        else begin
            case (inState)
                inReset: begin
                    regIN <= 41'b0;
                    inState <= inShift;
                end

                inShift: begin
                    regIN = {regIN[39:0], din};         // blocking shift (immediate)

                    if (regIN[40:33] == 8'h5A) begin     // header detected (packet ready)
                        op = regIN[32];
                        opA = regIN[31:16];
                        opB = regIN[15:0];

                        regIN <= 41'b0;               // clear for next packet

                        A3 = opA[15:12];
                        A2 = opA[11:8];
                        A1 = opA[7:4];
                        A0 = opA[3:0];

                        B3 = opB[15:12];
                        B2 = opB[11:8];
                        B1 = opB[7:4];
                        B0 = opB[3:0];

                        if (op == 1'b0) begin
                            // BCD addition (propagate carries)
                            add0 = bcd_add(A0, B0, 1'b0);
                            add1 = bcd_add(A1, B1, add0[4]);
                            add2 = bcd_add(A2, B2, add1[4]);
                            add3 = bcd_add(A3, B3, add2[4]);

                            regOUT <= {8'h96, 3'b0, add3[4:0], add2[3:0], add1[3:0], add0[3:0]};
                        end
                        else begin
                            // BCD subtraction via 9's complement on B then add
                            sub0 = bcd_add((4'd9 - B0), 4'd1, 1'b0);
                            sub1 = bcd_add((4'd9 - B1), 4'd0, sub0[4]);
                            sub2 = bcd_add((4'd9 - B2), 4'd0, sub1[4]);
                            sub3 = bcd_add((4'd9 - B3), 4'd0, sub2[4]);

                            add0 = bcd_add(A0, sub0[3:0], 1'b0);
                            add1 = bcd_add(A1, sub1[3:0], add0[4]);
                            add2 = bcd_add(A2, sub2[3:0], add1[4]);
                            add3 = bcd_add(A3, sub3[3:0], add2[4]);

                            regOUT <= {8'h96, 4'd0, add3[3:0], add2[3:0], add1[3:0], add0[3:0]};
                        end
                    end
                end

                default: inState <= inReset;
            endcase
        end
    end


    // Output FSM (PISO)
    always @(posedge clock) begin
        if (reset) begin
            count <= 5'd0;
            regOUT <= 28'd0;
            result <= 1'b0;
            outState <= outIdle;
        end
        else begin
            case (outState)
                outIdle: begin
                    if (regOUT[27:20] == 8'h96) begin
                        count <= 0;
                        outState <= outShift;
                    end
                    else begin
                        result <= 1'b0;
                    end
                end

                outShift: begin
                    result <= regOUT[27];
                    regOUT <= {regOUT[26:0], 1'b0};

                    if (count < 27)
                        count <= count + 1;
                    else begin
                        outState <= outIdle;
                        count <= 0;
                    end
                end
            endcase
        end
    end

endmodule
