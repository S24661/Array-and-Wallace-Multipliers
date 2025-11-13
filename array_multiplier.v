`timescale 1ns / 1ps

module ArrayMultiplier(
    input[15:0] A,B,
    output[31:0] PRODUCT
    );
    reg [32:0] ca;
    integer i;
    always @(*) begin
        ca = {17'b0, A};
        for (i = 0; i < 16; i = i + 1) begin
            if (ca[0] == 1'b1)
                ca[32:16] = ca[32:16] + B;
            ca = ca >> 1;    
        end
    end
    assign PRODUCT = ca[31:0];
endmodule
