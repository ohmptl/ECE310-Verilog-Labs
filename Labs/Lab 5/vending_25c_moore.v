`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ohm Patel
// 
// Create Date: 10/26/2025 07:12:56 PM
// Design Name: vending_25c_moore
// Assign Name: ECE 310 Lab 5
// Description: A verilog implementation of a
//              vending machine FSM
// 
//////////////////////////////////////////////////////////////////////////////////

module vending_25c_moore(
    input wire clock, reset_n, D, Q,
    output reg  P, C       
    );
      
    reg [2:0] state, next_state;

    parameter S0 = 3'b000, // 0 cents
              S1 = 3'b001, // 10 cents
              S2 = 3'b010, // 20 cents
              S3 = 3'b011, // 25 cents - vend no change
              S4 = 3'b100; // 25 cents - vend with change

    always @(*) begin
        next_state = state;
        P = 1'b0; C = 1'b0;
        case (state)
            S0: begin
                case ({D, Q})
                    2'b10: next_state = S1;   // +10
                    2'b01: next_state = S3;   // +25 -> vend exact
                    default: next_state = S0; // 00 or 11: no advance
                endcase
            end

            S1: begin
                case ({D, Q})
                    2'b10: next_state = S2;   // +10 (20)
                    2'b01: next_state = S4;   // +25 (35)
                    default: next_state = S1; // 00/11
                endcase
            end

            S2: begin
                case ({D, Q})
                    2'b10: next_state = S4;   // +10 (30)
                    2'b01: next_state = S4;   // +25 (45)
                    default: next_state = S2; // 00/11
                endcase
            end

            S3: begin
                P = 1'b1; C = 1'b0; // Vend no change
                case ({D, Q})
                    2'b00, 2'b11: next_state = S0;  // 00/11
                    2'b10: next_state = S1;         // +10 (10)
                    2'b01: next_state = S3;         // +25 (25)
                    default: next_state = S3;       // do not unconditionally reset
                endcase
            end

            S4: begin
                P = 1'b1; C = 1'b1; // Vend + Change
                case ({D, Q})
                    2'b00, 2'b11: next_state = S0;  // 00/11
                    2'b10: next_state = S1;         // +10 (10)
                    2'b01: next_state = S3;         // +25 (25)
                    default: next_state = S4;       // do not unconditionally reset
                endcase
            end

            default: begin next_state = S0; end // Default S0 case
        endcase
    end

    always @(posedge clock) begin
        if (!reset_n) // Active low reset to S0
            state <= S0;
        else
            state <= next_state; // Advance state
    end

endmodule