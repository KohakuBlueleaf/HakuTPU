module FP16_ALU(
    input clk,
    input rst,
    input in_valid,
    input [3:0] opmode,
    input [15:0] a,
    input [15:0] b,
    input [15:0] c,
    output [15:0] out,
    output out_valid
);
    /*
        Supported Operation:
        0000: a*b + c
        0001: a*b - c
        0010: 1/a*b + c
        0011: 1/a*b - c
        0100: log(a)
        1000: exp(a)
        First bit: invert sign of c
        Second big: use inversion of a
        Third bit: use log mode result = log(a.exp) + log(a.mant)
        Fourth bit: use exp mode result = exp(a.exp) * exp(a.mant)
    */

    wire [11:0] a_12 = {a[15], a[14:10], a[9:4]};
    wire [15:0] a_inverse, a_log_exp, a_log_mant, a_exp_exp, a_exp_mant;

    FP12Inverse inverse_a(
        .a(a_12),
        .b(a_inverse)
    );

    FP12PartialExp exp_a(
        .a(a_12),
        .exp_exp(a_exp_exp),
        .mant_exp(a_exp_mant)
    );

    FP12PartialLog log_a(
        .a(a_12),
        .exp_log(a_log_exp),
        .mant_log(a_log_mant)
    );

    reg fma_in_valid;
    reg [15:0] fma_a, fma_b, fma_c;

    always @(clk) begin
        fma_in_valid <= in_valid;
        // fma_a <= opmode[3] ? a_exp_exp : opmode[2] ? a_log_exp : opmode[1] ? a_inverse : a;
        // fma_b <= opmode[3] ? a_exp_mant : opmode[2] ? 16'b0_01111_0000000000 : b;
        // fma_c <= opmode[3] ? 16'b0 : {c[15]^opmode[0], c[14:0]};
        if (opmode[3]) begin
            fma_a <= a_exp_exp;
            fma_b <= a_exp_mant;
            fma_c <= 16'b0;
        end else begin
            fma_a <= opmode[2] ? a_log_exp : opmode[1] ? a_inverse : a;
            fma_b <= opmode[2] ? 16'b0_01111_0000000000 : b;
            fma_c <= {c[15]^opmode[0], c[14:0]};
        end
    end

    FP16FMA fma_unit(
        .clk(clk),
        .rst(rst),
        .in_valid(fma_in_valid),
        .a(fma_a),
        .b(fma_b),
        .c(fma_c),
        .out_valid(out_valid),
        .out(out)
    );
endmodule