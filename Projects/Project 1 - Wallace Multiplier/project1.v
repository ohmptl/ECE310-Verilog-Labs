`timescale 1ns / 1ps


//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ohm Patel
// 
// Create Date: 09/15/2025 12:09:41 AM
// Design Name: 8 by 8 Wallace Multiplier
// Module Name: Project1
// Description: A gate level implementation of an 
//              8-bit by 8-bit wallace multiplier
// 
//////////////////////////////////////////////////////////////////////////////////




module full_adder(
    input  A, B, Cin,           // Define inputs
    output S, Cout              // Define outputs
);
    wire w1, w2, w3;            // Internal Wires
    xor(w1, A, B);              // First XOR gate
    xor(S, w1, Cin);            // Second XOR output S (Sum)
    and(w2, A, B);              // First AND gate
    and(w3, w1, Cin);           // Second AND gate
    or(Cout, w2, w3);           // First OR output Cout (Carry Out)

endmodule


module half_adder(
    input  A, B,                // Define inputs
    output S, Cout              // Define outputs
);
    xor(S, A, B);               // XOR output S (sum)
    and(Cout, A, B);            // AND output Cout (carry out)

endmodule


module wallace_8x8(
    input [7:0] a, b,
    output [15:0] prod
    );
    
    // Make all the partial sums using generate
    
    wire p[7:0][7:0];
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_i
            for (j = 0; j < 8; j = j + 1) begin : gen_j
                and and_gates ((p[i][j]), (a[i]), (b[j]));
            end
        end
    endgenerate
    
    // First slice of wallace multiplication
    // Refer to project design to understand wallace breakdown
    
    wire [46:0]fs, fc;                                              // Full adder 0-37 sum/carry
    wire [16:0]hs, hc;                                              // Half adder 0-14 sum/carry
    
    // Top row from design
    half_adder ha0  (p[1][0], p[0][1], hs[0], hc[0]);                
    full_adder fa0  (p[2][0], p[1][1], p[0][2], fs[0], fc[0]);       
    full_adder fa1  (p[3][0], p[2][1], p[1][2], fs[1], fc[1]);
    full_adder fa2  (p[4][0], p[3][1], p[2][2], fs[2], fc[2]);
    full_adder fa3  (p[5][0], p[4][1], p[3][2], fs[3], fc[3]);
    full_adder fa4  (p[6][0], p[5][1], p[4][2], fs[4], fc[4]);
    full_adder fa5  (p[7][0], p[6][1], p[5][2], fs[5], fc[5]);       
    half_adder ha1  (p[7][1], p[6][2], hs[1], hc[1]);  
    
    // Second row from design
    half_adder ha2  (p[1][3], p[0][4], hs[2], hc[2]);                
    full_adder fa6  (p[2][3], p[1][4], p[0][5], fs[6], fc[6]);       
    full_adder fa7  (p[3][3], p[2][4], p[1][5], fs[7], fc[7]);
    full_adder fa8  (p[4][3], p[3][4], p[2][5], fs[8], fc[8]);
    full_adder fa9  (p[5][3], p[4][4], p[3][5], fs[9], fc[9]);
    full_adder fa10 (p[6][3], p[5][4], p[4][5], fs[10], fc[10]);
    full_adder fa11 (p[7][3], p[6][4], p[5][5], fs[11], fc[11]);       
    half_adder ha3  (p[7][4], p[6][5], hs[3], hc[3]); 
    
// -----------------End of wallace slice 1 ---------------------------------------------------------------    
    
    // Third row from design
    half_adder ha4  (hc[0], fs[0], hs[4], hc[4]);                
    full_adder fa12 (p[0][3], fc[0], fs[1], fs[12], fc[12]);       
    full_adder fa13 (fc[1], fs[2], hs[2], fs[13], fc[13]);
    full_adder fa14 (fc[2], hc[2], fs[3], fs[14], fc[14]);
    full_adder fa15 (p[0][6], fc[3], fc[6], fs[15], fc[15]);
    full_adder fa16 (p[1][6], p[0][7], fc[4], fs[16], fc[16]);
    full_adder fa17 (p[2][6], p[1][7], fc[5], fs[17], fc[17]);       
    full_adder fa18 (p[3][6], p[2][7], p[7][2], fs[18], fc[18]);  
    
    // Fourth row from design
    half_adder ha5  (fs[4], fs[7], hs[5], hc[5]);                
    full_adder fa19 (fc[7], fs[5], fs[8], fs[19], fc[19]);       
    full_adder fa20 (fc[8], hs[1], fs[9], fs[20], fc[20]);
    full_adder fa21 (hc[1], fc[9], fs[10], fs[21], fc[21]);
    full_adder fa22 (p[3][7], fc[10], fs[11], fs[22], fc[22]);
    full_adder fa23 (p[4][7], fc[11], hs[3], fs[23], fc[23]);
    full_adder fa24 (p[6][6], p[5][7], hc[3], fs[24], fc[24]);       
    half_adder ha6  (p[7][6], p[6][7], hs[6], hc[6]);   

// -----------------End of wallace slice 2 --------------------------------------------------------------- 

    // Fifth row from design
    half_adder ha7  (hc[4], fs[12], hs[7], hc[7]);
    half_adder ha8  (fc[12], fs[13], hs[8], hc[8]);                
    full_adder fa25 (fs[6], fc[13], fs[14], fs[25], fc[25]);       
    full_adder fa26 (fc[14], fs[15], hs[5], fs[26], fc[26]);
    full_adder fa27 (fc[15], hc[5], fs[16], fs[27], fc[27]);
    full_adder fa28 (fc[16], fc[19], fs[17], fs[28], fc[28]);
    full_adder fa29 (fc[17], fc[20], fs[18], fs[29], fc[29]);
    full_adder fa30 (p[4][6], fc[18], fc[21], fs[30], fc[30]);       
    half_adder ha9  (p[5][6], fc[22], hs[9], hc[9]); 
    half_adder ha10 (p[7][5], fc[23], hs[10], hc[10]);  
   
// -----------------End of wallace slice 3 --------------------------------------------------------------- 

    // Sixth row from design
    half_adder ha11 (hc[7], hs[8], hs[11], hc[11]);
    half_adder ha12 (hc[8], fs[25], hs[12], hc[12]);
    half_adder ha13 (fc[25], fs[26], hs[13], hc[13]);                
    full_adder fa31 (fs[19], fc[26], fs[27], fs[31], fc[31]);       
    full_adder fa32 (fs[20], fc[27], fs[28], fs[32], fc[32]);
    full_adder fa33 (fs[21], fc[28], fs[29], fs[33], fc[33]);
    full_adder fa34 (fs[22], fc[29], fs[30], fs[34], fc[34]);
    full_adder fa35 (fs[23], fc[30], hs[9], fs[35], fc[35]);
    full_adder fa36 (fs[24], hc[9], hs[10], fs[36], fc[36]);       
    full_adder fa37 (fc[24], hs[6], hc[10], fs[37], fc[37]); 
    half_adder ha14 (p[7][7], hc[6], hs[14], hc[14]);  
    
 // -----------------End of wallace slice 4 --------------------------------------------------------------- 
 
    // Use RCA to finish up the wallace multiplication

    half_adder ha15 (hc[11], hs[12], hs[15], hc[15]);                
    full_adder fa38 (hc[15], hc[12], hs[13], fs[38], fc[38]);
    full_adder fa39 (fc[38], hc[13], fs[31], fs[39], fc[39]);
    full_adder fa40 (fc[39], fc[31], fs[32], fs[40], fc[40]);
    full_adder fa41 (fc[40], fc[32], fs[33], fs[41], fc[41]);
    full_adder fa42 (fc[41], fc[33], fs[34], fs[42], fc[42]);
    full_adder fa43 (fc[42], fc[34], fs[35], fs[43], fc[43]);
    full_adder fa44 (fc[43], fc[35], fs[36], fs[44], fc[44]);
    full_adder fa45 (fc[44], fc[36], fs[37], fs[45], fc[45]);
    full_adder fa46 (fc[45], fc[37], hs[14], fs[46], fc[46]);  
    half_adder ha16 (fc[46], hc[14], hs[16], hc[16]);   // Note hc[16] does not matter (8*8 bit always = 16 bits)
    
    // Final product mapping without assign
    buf (prod[0],  p[0][0]);   // column 0
    buf (prod[1],  hs[0]);     // from ha0
    buf (prod[2],  hs[4]);     // from ha4
    buf (prod[3],  hs[7]);     // from ha7
    buf (prod[4],  hs[11]);    // from ha11
    buf (prod[5],  hs[15]);    // from ha15
    buf (prod[6],  fs[38]);    // from fa38
    buf (prod[7],  fs[39]);    // from fa39
    buf (prod[8],  fs[40]);    // from fa40
    buf (prod[9],  fs[41]);    // from fa41
    buf (prod[10], fs[42]);    // from fa42
    buf (prod[11], fs[43]);    // from fa43
    buf (prod[12], fs[44]);    // from fa44
    buf (prod[13], fs[45]);    // from fa45
    buf (prod[14], fs[46]);    // from fa46
    buf (prod[15], hs[16]);    // final HA (MSB)


endmodule



// Testbench for wallace multiplier
module wallace_multiplier_tb;
    reg [7:0] a, b;
    wire [15:0] P;
    wallace_8x8 dut(a, b, P);
    
    initial
    begin
    
        // 1) Baseline all zero case
        a = 8'b00000000; b = 8'b00000000; 
        #10 $display("A: %b B: %b P: %b (dec=%0d)", a, b, P, P);

        // 2) One operand zero, the other max
        a = 8'b00000000; b = 8'b11111111; 
        #10 $display("A: %b B: %b P: %b (dec=%0d)", a, b, P, P);

        // 3) Smallest nontrivial (1 * anything)
        a = 8'b00000001; b = 8'b11111111; 
        #10 $display("A: %b B: %b P: %b (dec=%0d)", a, b, P, P);

        // 4) Power-of-two operands (shift check: 2^7 * 2^1 = 2^8)
        a = 8'b10000000; b = 8'b00000010; 
        #10 $display("A: %b B: %b P: %b (dec=%0d)", a, b, P, P);

        // 5) Mid-size values (15 * 15 = 225, check partial products)
        a = 8'b00001111; b = 8'b00001111; 
        #10 $display("A: %b B: %b P: %b (dec=%0d)", a, b, P, P);

        // 6) Uneven operands (25 * 12 = 300)
        a = 8'b00011001; b = 8'b00001100; 
        #10 $display("A: %b B: %b P: %b (dec=%0d)", a, b, P, P);

        // 7) Large * small (200 * 13 = 2600)
        a = 8'b11001000; b = 8'b00001101; 
        #10 $display("A: %b B: %b P: %b (dec=%0d)", a, b, P, P);

        // 8) Large * large but not max (150 * 151 = 22650)
        a = 8'b10010110; b = 8'b10010111; 
        #10 $display("A: %b B: %b P: %b (dec=%0d)", a, b, P, P);

        // 9) Max edge case (255 * 255 = 65025)
        a = 8'b11111111; b = 8'b11111111; 
        #10 $display("A: %b B: %b P: %b (dec=%0d)", a, b, P, P);

        

        
    $finish;
    end


endmodule 





