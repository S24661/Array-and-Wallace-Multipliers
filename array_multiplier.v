module ArrayMultiplier (
    input  [15:0] A,
    input  [15:0] B, 
    output [31:0] PRODUCT
);
    wire [15:0] pp [15:0];
    genvar i, j;

   //Generating partial Products
    generate
        for (i = 0; i < 16; i = i + 1) begin 
            for (j = 0; j < 16; j = j + 1) begin 
                assign pp[i][j] = A[j] & B[i];
            end
        end
    endgenerate

 
    wire [31:0] sum [15:0];
    wire [31:0] carry [15:0];

    assign sum[0]   = {16'b0, pp[0]};
    assign carry[0] = 32'b0;

    generate
        for (i = 1; i < 16; i = i + 1) begin
            wire [31:0] sp = { { (16 - i){1'b0} }, pp[i], { i{1'b0} } };
            assign {carry[i], sum[i]} = sum[i-1] + sp;
        end
    endgenerate

    assign PRODUCT = sum[15];

endmodule
