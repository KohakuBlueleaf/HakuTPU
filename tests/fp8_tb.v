// test_fp8.v
`timescale 1ns / 1ps


module FP8VectorMul_tb;
    reg clk;
    reg rst;
    reg [7:0] q = {1'b0, 4'b0111, 3'b100}; // +1 * 2^(7-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = 1.5
    reg [7:0] a = {1'b0, 4'b0111, 3'b100}; // +1 * 2^(7-7) * (1 + 1/2 * 1 + 1/4 * 0 + 1/8 * 0) = 1.5
    reg [7:0] b = {1'b1, 4'b1000, 3'b100}; // -1 * 2^(8-7) * (1 + 1/2 * 1 + 1/4 * 0 + 1/8 * 0) = -3
    reg [7:0] c = {1'b0, 4'b1000, 3'b000}; // +1 * 2^(8-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = 2
    reg [7:0] d = {1'b1, 4'b1001, 3'b000}; // -1 * 2^(9-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = -4
    wire [31:0] vec = {d, c, b, a};
    wire [63:0] res; // {qa, qb, qc, qd} = {1.25, -4.5, 3.0, -6.0}
    reg [15:0] qa;
    reg [15:0] qb;
    reg [15:0] qc;
    reg [15:0] qd;

    always @(*) begin
        qa = res[15:0];
        qb = res[31:16];
        qc = res[47:32];
        qd = res[63:48];
    end

    FP8VectorMul fp8 (
        .clk(clk),
        .rst(rst),
        .e5m2mode(1'b0),
        .q(q),
        .vec(vec),
        .res(res)
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
        #100;
        $finish;
    end

    initial begin
        $monitor(
            "Time = %f, QA = %b, QB = %b, QC = %b , QD = %b", 
            $time, qa, qb, qc, qd
        );
        $dumpfile("dump.vcd");
        $dumpvars(0, FP8VectorMul_tb);
    end

endmodule