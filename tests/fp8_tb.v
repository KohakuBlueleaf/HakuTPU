// test_fp8.v
`timescale 1ns / 1ps


module FP16to32 (
    input  [15:0] fp16_in,
    output reg [31:0] fp32_out
);
    wire sign;
    wire [4:0] exp16;
    wire [9:0] mant16;

    reg [7:0] exp32;
    reg [23:0] mant32;

    assign sign = fp16_in[15];
    assign exp16 = fp16_in[14:10];
    assign mant16 = fp16_in[9:0];

    // Handle special cases (Zero, Infinity, NaN, Denormal)
    always @(*) begin
        if (exp16 == 5'b00000) begin // Zero or Denormal
            if (mant16 == 10'b0000000000) begin // Zero
                fp32_out = {sign, 8'b00000000, 23'b00000000000000000000000};
            end else begin // Denormal
                exp32 = 8'b00000000;
                mant32 = {1'b0, mant16, 13'b0000000000000}; // Implicit leading 0
                fp32_out = {sign, exp32, mant32};
            end
            end else if (exp16 == 5'b11111) begin // Infinity or NaN
                if (mant16 == 10'b0000000000) begin // Infinity
                    fp32_out = {sign, 8'b11111111, 23'b00000000000000000000000};
            end else begin // NaN
                fp32_out = {sign, 8'b11111111, {1'b1, mant16, 12'b000000000000}}; // At least one mantissa bit must be set for NaN
            end
        end else begin // Normal number
            exp32 = exp16 + 8'b01111000; // Bias adjustment: 127 (FP32) - 15 (FP16) = 112 = 01110000 in binary
            mant32 = {mant16, 14'b0000000000000}; // Implicit leading 1
            fp32_out = {sign, exp32, mant32};
        end
    end
endmodule


module FP8VectorMul_tb;
    reg clk;
    reg rst;
    reg [7:0] q = {1'b0, 4'b0111, 3'b100}; // +1 * 2^(7-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = 1.5
    reg [7:0] a = {1'b0, 4'b0111, 3'b100}; // +1 * 2^(7-7) * (1 + 1/2 * 1 + 1/4 * 0 + 1/8 * 0) = 1.5
    reg [7:0] b = {1'b1, 4'b1000, 3'b100}; // -1 * 2^(8-7) * (1 + 1/2 * 1 + 1/4 * 0 + 1/8 * 0) = -3
    reg [7:0] c = {1'b0, 4'b1000, 3'b000}; // +1 * 2^(8-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = 2
    reg [7:0] d = {1'b1, 4'b1001, 3'b000}; // -1 * 2^(9-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = -4
    wire [31:0] vec = {d, c, b, a};
    wire [63:0] res;
    reg [15:0] qa;
    reg [15:0] qb;
    reg [15:0] qc;
    reg [15:0] qd;
    wire [31:0] qa_32;
    wire [31:0] qb_32;
    wire [31:0] qc_32;
    wire [31:0] qd_32;

    wire [26:0] D;
    wire [17:0] B;
    wire [47:0] C;
    wire [47:0] PCIN;
    wire [47:0] P;

    wire [6:0] qa_exp;
    wire [6:0] qb_exp;
    wire [6:0] qc_exp;
    wire [6:0] qd_exp;

    always @(*) begin
        qa = res[15:0];
        qb = res[31:16];
        qc = res[47:32];
        qd = res[63:48];
    end

    FP16to32 fp16to32_qa (
        .fp16_in(qa),
        .fp32_out(qa_32)
    );
    FP16to32 fp16to32_qb (
        .fp16_in(qb),
        .fp32_out(qb_32)
    );
    FP16to32 fp16to32_qc (
        .fp16_in(qc),
        .fp32_out(qc_32)
    );
    FP16to32 fp16to32_qd (
        .fp16_in(qd),
        .fp32_out(qd_32)
    );

    FP8VectorMul fp8 (
        .clk(clk),
        .rst(rst),
        .e5m2mode(1'b0),
        .q(q),
        .vec(vec),
        .D(D),
        .B(B),
        .C(C),
        .PCIN(PCIN),
        .P(P),
        .qa_exp(qa_exp),
        .qb_exp(qb_exp),
        .qc_exp(qc_exp),
        .qd_exp(qd_exp)
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
            "Time = %f, QA = %f, QB = %f, QC = %f , QD = %f", 
            $time, qa_32, qb_32, qc_32, qd_32
        );
        // $monitor(
        //     "Time = %0d, B = %b, C = %b, D = %b, PCIN = %b, P = %b, res = %b", 
        //     $time, B, C, D, PCIN, P, res//, PCOUT, ACOUT, BCOUT
        // );
        $monitor(
            "Time = %0d, qa_exp = %b, qb_exp = %b, qc_exp = %b, qd_exp = %b", 
            $time, qa_exp, qb_exp, qc_exp, qd_exp
        );
        $dumpfile("dump.vcd");
        $dumpvars(0, FP8VectorMul_tb);
    end

endmodule