// DSP48E2_example_tb.v
`timescale 1ns / 1ps

module DSP48E2_example_tb;
  reg clk;
  reg rst;
  reg signed [29:0] A;
  reg signed [17:0] B;
  reg signed [47:0] C;
  reg signed [26:0] D;
  reg signed [47:0] PCIN;
  wire signed [47:0] P;
  wire signed [47:0] PCOUT;
  wire signed [29:0] ACOUT;
  wire signed [17:0] BCOUT;

  DSP unit (
    .enable(1'b1),
    .clk(clk),
    .rst(rst),
    .A(A),
    .B(B),
    .C(C),
    .D(D),
    .PCIN(PCIN),
    .ALUMODE(4'b0000),
    .INMODE(5'b10101),
    .OPMODE(9'b110010101), // (A+D) * B + C + PCIN
    .P(P),
    .PCOUT(PCOUT),
    .ACOUT(ACOUT),
    .BCOUT(BCOUT)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst = 1;
    #10;
    rst = 0;
  end

  initial begin
    A = 30'd0;
    B = 18'd0;
    C = 48'd0;
    D = 27'd0;
    PCIN = 48'd0;
    #20;
    A = 30'd1;
    B = 18'd1;
    C = 48'd1;
    D = 27'd1;
    PCIN = 48'd1;
    #20;
    A = 30'd2;
    B = 18'd3;
    C = 48'd4;
    D = 27'd5;
    PCIN = 48'd6;
    #20;
    $finish;
  end

  initial begin
    $monitor(
      "Time = %0d, A = %0d, B = %0d, C = %0d , D = %0d, PCIN = %0d, P = %0d", 
      $time, A, B, C, D, PCIN, P//, PCOUT, ACOUT, BCOUT
    );
    $dumpfile("dump.vcd");
    $dumpvars(0, DSP48E2_example_tb);
  end

endmodule