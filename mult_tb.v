`timescale 1ns / 1ps

module mult_tb();

    reg         clk;
    reg         rst;
    reg  [15:0] tb_a, tb_b;
    wire [31:0] P_wallace;
    
    wire [31:0] P_array;

  ArrayMultiplier dut1 (
    .A(tb_a),
    .B(tb_b),
    .PRODUCT(P_array)
  );

    Optimized_Wallace dut2 (
        .clk(clk),
       .rst(rst),
        .A(tb_a),
       .B(tb_b),
        .PRODUCT(P_wallace)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;  
    end
    
    integer i;
    initial begin
        rst = 1;
        tb_a = 0;
        tb_b = 0;
         #20        
        rst = 0;
        
       for (i = 0; i < 100; i = i + 1) begin
     @(posedge clk); tb_a = $random;
 tb_b = $random; #60
      if (P_array !== P_wallace) begin
        $display("Mismatch at %0t ns: A=%h, B=%h, Array=%h, Wallace=%h",
              $time, tb_a, tb_b, P_array, P_wallace);
     end
      else begin
      $display("Both are equal! at %0t ns: A=%h, B=%h, Array=%h, Wallace=%h",
                $time, tb_a, tb_b, P_array, P_wallace);
      end
     #10; 
    end
    $display("Testbench completed.");
        repeat (5) @(posedge clk);

        $stop;
    end
endmodule
