`timescale 1ns / 1ps

// Black Cell
module black_cell(
    input  wire g_left, p_left,
    input  wire g_right, p_right,
    output wire g_out, p_out
);
    assign g_out = g_left | (p_left & g_right);
    assign p_out = p_left & p_right;
endmodule

// Gray Cell
module gray_cell(
    input  wire g_left, p_left,
    input  wire g_right,
    output wire g_out
);
    assign g_out = g_left | (p_left & g_right);
endmodule

//Han_carlson Adder for final addition
module han_carlson_32(
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] s,
    output wire        ca
);

    // Generate / Propagate
    wire [31:0] g0, p0;
    assign g0 = a & b;
    assign p0 = a ^ b;

    
    wire [31:0] gg1, pp1;
    wire [31:0] gg2, pp2;
    wire [31:0] gg3, pp3;
    wire [31:0] gg4, pp4;
    wire [31:0] gg5, pp5;

    genvar i;

    // Stage 1 (distance = 1)
    generate
        for (i = 0; i < 32; i = i + 1) begin : STAGE1
            if (i >= 1) begin
                assign gg1[i] = g0[i] | (p0[i] & g0[i-1]);
                assign pp1[i] = p0[i] & p0[i-1];
            end else begin
                assign gg1[i] = g0[i];
                assign pp1[i] = p0[i];
            end
        end
    endgenerate

    // Stage 2 (distance = 2)
    generate
        for (i = 0; i < 32; i = i + 1) begin : STAGE2
            if (i >= 2) begin
                assign gg2[i] = gg1[i] | (pp1[i] & gg1[i-2]);
                assign pp2[i] = pp1[i] & pp1[i-2];
            end else begin
                assign gg2[i] = gg1[i];
                assign pp2[i] = pp1[i];
            end
        end
    endgenerate

    // Stage 3 (distance = 4)
    generate
        for (i = 0; i < 32; i = i + 1) begin : STAGE3
            if (i >= 4) begin
                assign gg3[i] = gg2[i] | (pp2[i] & gg2[i-4]);
                assign pp3[i] = pp2[i] & pp2[i-4];
            end else begin
                assign gg3[i] = gg2[i];
                assign pp3[i] = pp2[i];
            end
        end
    endgenerate

    // Stage 4 (distance = 8)
    generate
        for (i = 0; i < 32; i = i + 1) begin : STAGE4
            if (i >= 8) begin
                assign gg4[i] = gg3[i] | (pp3[i] & gg3[i-8]);
                assign pp4[i] = pp3[i] & pp3[i-8];
            end else begin
                assign gg4[i] = gg3[i];
                assign pp4[i] = pp3[i];
            end
        end
    endgenerate

    // Stage 5 (distance =16)
    generate
        for (i = 0; i < 32; i = i + 1) begin : STAGE5
            if (i >= 16) begin
                assign gg5[i] = gg4[i] | (pp4[i] & gg4[i-16]);
                assign pp5[i] = pp4[i] & pp4[i-16];
            end else begin
                assign gg5[i] = gg4[i];
                assign pp5[i] = pp4[i];
            end
        end
    endgenerate

    wire [31:0] c;
    assign c[0] = 1'b0;
    generate
        for (i = 1; i < 32; i = i + 1) begin : CARRY_ASSIGN
            // safe, gg5 is defined for all indices 0..31
            assign c[i] = gg5[i-1];
        end
    endgenerate

    // final carry-out (carry into bit 32)
    assign ca = gg5[31];

    // sum
    assign s = p0 ^ c;

endmodule


module full_adder(
    input a, b, c,
    output s, ca
);
    assign s  = a ^ b ^ c;
    assign ca = (a & b) | (b & c) | (c & a);
endmodule

//compressor_7:3
module compressor_7to3(
    input  [31:0] a1, a2, a3, a4, a5, a6, a7,
    output [31:0] s,
    output [31:0] c1,   
    output [31:0] c2    
);
    genvar j;
    generate
        for (j = 0; j < 32; j = j + 1) begin
            wire s1, s2, s3, s4, d1, d2, d3, d4;
            full_adder f1 (.a(a1[j]), .b(a2[j]), .c(a3[j]), .s(s1), .ca(d1));
            full_adder f2 (.a(a4[j]), .b(a5[j]), .c(a6[j]), .s(s2), .ca(d2));
            full_adder f3 (.a(s1),   .b(s2),   .c(a7[j]),  .s(s3), .ca(d3));
            full_adder f4 (.a(d1),   .b(d2),   .c(d3),    .s(s4), .ca(d4));
            assign s[j]  = s3;
            assign c1[j] = s4;  
            assign c2[j] = d4;  
        end
    endgenerate
endmodule

// 3:2 compressor shifted left by 1
module csa(
    input  [31:0] a, b, c,
    output [31:0] s,
    output [31:0] ca 
);
    assign s  = a ^ b ^ c;
    assign ca = ((a & b) | (b & c) | (c & a)) << 1;
endmodule


//Wallace Multiplier
module Optimized_Wallace(
    input clk, rst,
    input [15:0] A, B,
    output reg [31:0] PRODUCT
);
    genvar i, j;
    wire [31:0] pp [0:15];

    //Partial Product Generation
    generate
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                if ((j >= i) && (j < i + 16))
                    assign pp[i][j] = A[j - i] & B[i];
                else
                    assign pp[i][j] = 1'b0;
            end
        end
    endgenerate

    //Stage 1
    wire [31:0] s0, s1_1, c0, c1, c0_2, c1_2, b0, b1, b0_2, b1_2;
     compressor_7to3 u1 (.a1(pp[0]), .a2(pp[1]), .a3(pp[2]), .a4(pp[3]), .a5(pp[4]), .a6(pp[5]), .a7(pp[6]), .s(s0), .c1(b0), .c2(b0_2));
     compressor_7to3 u2 (.a1(pp[7]), .a2(pp[8]), .a3(pp[9]), .a4(pp[10]), .a5(pp[11]), .a6(pp[12]), .a7(pp[13]), .s(s1_1), .c1(b1), .c2(b1_2));

   assign c0   = b0<<1;      
   assign c1   = b1<<1;      
   assign c0_2 = b0_2<<2;    
   assign c1_2 = b1_2<<2;   


    reg [31:0] r_s0, r_s1, r_c0, r_c1, r_c02, r_c12, r_pp14, r_pp15;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_s0 <= 0; r_s1 <= 0;
            r_c0 <= 0; r_c1 <= 0;
            r_c02 <= 0; r_c12 <= 0;
            r_pp14 <= 0; r_pp15 <= 0;
        end 
        else begin
            r_s0 <= s0; r_s1 <= s1_1;
            r_c0 <= c0; r_c1 <= c1;
            r_c02 <= c0_2; r_c12 <= c1_2;
            r_pp14 <= pp[14]; r_pp15 <= pp[15];
        end
    end

    //Stage 2
    wire [31:0] sum2, c1_s2, c2_s2, ca1, ca2;
    compressor_7to3 p1 (.a1(r_s0), .a2(r_s1), .a3(r_c0), .a4(r_c1), .a5(r_c02), .a6(r_c12), .a7(r_pp14), .s(sum2), .c1(c1_s2), .c2(c2_s2));
    assign ca1 = c1_s2<<1;     
    assign ca2 = c2_s2<<2;     


    reg [31:0] rsum2, rca1, rca2, rlt;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rsum2 <= 0;
            rca1 <= 0;
            rca2 <= 0;
            rlt <= 0;
        end
        else begin
            rsum2 <= sum2;
            rca1 <= ca1;
            rca2 <= ca2;
            rlt <= r_pp15;
        end
    end

    //Stage 3
    wire [31:0] ps1, pca1, s, ca;
    csa q1 (.a(rsum2), .b(rca1), .c(rca2), .s(ps1), .ca(pca1));
    csa q2 (.a(rlt), .b(ps1), .c(pca1), .s(s), .ca(ca));

    reg [31:0] rsum, rcarry;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rsum <= 0;
            rcarry <= 0;
        end 
        else begin
            rsum <= s;
            rcarry <= ca;
        end
    end

    //Stage 4
    wire [31:0] sum;
    wire carry;
    han_carlson_32 p2 (.a(rsum), .b(rcarry), .s(sum), .ca(carry));

    always @(posedge clk or posedge rst) begin
        if (rst)
            PRODUCT <= 0;
        else
            PRODUCT <= sum;
    end
endmodule
