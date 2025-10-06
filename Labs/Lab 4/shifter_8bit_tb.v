`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ohm Patel
// 
// Create Date: 10/05/2025 03:29:19 PM
// Design Name: 8-bit shifter
// Assign Name: ECE 310 Lab 4
// Description: A testbench for an implementation of an 
//              8-bit shifter
// 
//////////////////////////////////////////////////////////////////////////////////


module shifter_8bit_tb;
    reg [7:0] d_in;
    reg [2:0] op;
    reg capture, clock;
    wire [7:0] d_out;
    shifter_8bit dut(d_out, d_in, op, capture, clock);
    
    initial begin       // Clock logic 
        clock = 0;
        forever #5 clock = ~clock;
    end
    
    initial begin

        d_in = 8'b00000000; op = 3'b000; capture = 1'b0;
        #10 $display("TC1 - Zero input | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        d_in = 8'b10110010; op = 3'b000; capture = 1'b0;
        #10 $display("TC2 - Shift Left 1 | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        d_in = 8'b11001100; op = 3'b001; capture = 1'b0;
        #10 $display("TC3 - Shift Left 2 | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        d_in = 8'b01111001; op = 3'b010; capture = 1'b0;
        #10 $display("TC4 - Shift Right 1 | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        d_in = 8'b10000001; op = 3'b011; capture = 1'b0;
        #10 $display("TC5 - Shift Right 2 | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        d_in = 8'b10101010; op = 3'b100; capture = 1'b0;
        #10 $display("TC6 - Rotate Left 1 | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        d_in = 8'b11100001; op = 3'b101; capture = 1'b0;
        #10 $display("TC7 - Rotate Right 1 | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        d_in = 8'b01010101; op = 3'b110; capture = 1'b0;
        #10 $display("TC8 - Hold (capture=0, load current value) | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        op = 3'b000; capture = 1'b1;// Re-run with capture=1 to verify hold behavior. try to shift, but should not change 
        #10 $display("TC9 - Hold (capture=1, keep old output) | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        d_in = 8'b11111111; op = 3'b111; capture = 1'b0;
        #10 $display("TC10 - Invalid op Load 0s | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        d_in = 8'b00000001; op = 3'b000; capture = 1'b0; // shift left 1
        #10 $display("TC11 - Edge bit left | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        d_in = 8'b10000000; op = 3'b011; capture = 1'b0; // shift right 2
        #10 $display("TC12 - Edge bit right | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        d_in = 8'b01010101; op = 3'b100; capture = 1'b0; // rotate left
        #10 $display("TC13 - Alternating rotate left | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        d_in = 8'b10101010; op = 3'b101; capture = 1'b0; // rotate right
        #10 $display("TC14 - Alternating rotate right | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);
    
        d_in = 8'b11111111; op = 3'b010; capture = 1'b0; // shift right 1
        #10 $display("TC15 - All ones shift right 1 | Input: %b | Op: %b | Capture: %b | Output: %b", d_in, op, capture, d_out);

    $finish;
    end
endmodule
