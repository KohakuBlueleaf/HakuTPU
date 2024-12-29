module FP16_ALU(
    input clk,
    input rst,
    input in_valid,
    input [5:0] opmode,
    input [15:0] a,
    input [15:0] b,
    input [15:0] c,
    output reg [15:0] out,
    output out_valid
);
    /*
        Supported Operation:
        xx0000: a * b + c
        xx0001: a * b - c
        xx0010: 1/a * b + c
        xx0011: 1/a * b - c
        xx0100: log(a)
        xx1000: exp(a)

        01xxxx: result is zero     (floating point 1.0 or 0.0)
        10xxxx: result is positive (floating point 1.0 or 0.0)
        11xxxx: result is negative (floating point 1.0 or 0.0)

        First bit: invert sign of c
        Second big: use inversion of a
        Third bit: use log mode result = log(a.exp) + log(a.mant)
        Fourth bit: use exp mode result = exp(a.exp) * exp(a.mant)
    */

    wire [15:0] fp16_one = 16'b0_01111_0000000000;
    wire [15:0] fp16_zero = 16'b0_00000_0000000000;
    wire [11:0] a_12 = {a[15], a[14:10], a[9:4]};
    wire [15:0] a_inverse, a_log_exp, a_log_mant, a_partial_exp1, a_partial_exp2;

    FP12Inverse inverse_a(
        .a(a_12),
        .b(a_inverse)
    );

    FP12PartialExp exp_a(
        .a(a),
        .partial_exp1(a_partial_exp1),
        .partial_exp2(a_partial_exp2)
    );

    FP12PartialLog log_a(
        .a(a_12),
        .exp_log(a_log_exp),
        .mant_log(a_log_mant)
    );

    reg fma_in_valid;
    reg [15:0] fma_a, fma_b, fma_c;
    reg [1:0] post_opmode_reg1, post_opmode_reg2, post_opmode_reg3, post_opmode_reg4;

    always @(clk) begin
        fma_in_valid <= in_valid;
        post_opmode_reg1 <= opmode[5:4];
        post_opmode_reg2 <= post_opmode_reg1;
        post_opmode_reg3 <= post_opmode_reg2;
        post_opmode_reg4 <= post_opmode_reg3;

        if (opmode[3]) begin
            fma_a <= a_partial_exp1;
            fma_b <= a_partial_exp2;
            fma_c <= 16'b0;
        end else begin
            fma_a <= opmode[2] ? a_log_exp : opmode[1] ? a_inverse : a;
            fma_b <= opmode[2] ? fp16_one : b;
            fma_c <= {c[15]^opmode[0], c[14:0]};
        end
    end

    wire [15:0] fma_out;
    FP16FMA fma_unit(
        .clk(clk),
        .rst(rst),
        .in_valid(fma_in_valid),
        .a(fma_a),
        .b(fma_b),
        .c(fma_c),
        .out_valid(out_valid),
        .out(fma_out)
    );

    always @(*) begin
        if(post_opmode_reg4[1]) begin
            out = (fma_out[15] == post_opmode_reg4[0]) ? fp16_one : fp16_zero;
        end else if(post_opmode_reg4[0]) begin
            out = (fma_out == fp16_zero) ? fp16_zero : fp16_one;
        end else begin
            out = fma_out;
        end
    end
endmodule


module FP16ALUArray(
    input clk,
    input rst,
    input in_valid,
    input [5:0] opmode,
    input [0:15][15:0] a,
    input [0:15][15:0] b,
    input [0:15][15:0] c,
    output [0:15][15:0] out,
    output out_valid
);
    genvar i;
    wire [15:0] total_out_valid;
    assign out_valid = total_out_valid[0];
    generate
        for(i = 0; i < 16; i = i + 1) begin: FP16_ALU
            FP16_ALU alu(
                .clk(clk),
                .rst(rst),
                .in_valid(in_valid),
                .opmode(opmode),
                .a(a[i]),
                .b(b[i]),
                .c(c[i]),
                .out(out[i]),
                .out_valid(total_out_valid)
            );
        end
    endgenerate
endmodule