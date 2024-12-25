module FP12PartialExp (
    input [11:0] a,
    output reg [15:0] exp_exp,
    output reg [15:0] mant_exp
);
    wire sign = a[11];
    wire [4:0] exp = a[10:6];
    wire [5:0] mant = a[5:0];
    wire [10:0] mant_out;
    wire [14:0] subnorm_out;
    wire [14:0] exp_out;

    MultiBitLut #(
        .input_bits(6),
        .output_bits(11),
        .INIT({
            64'b1111111111111111111111111111111111111110000000000000000000000000,
            64'b1111111111111000000000000000000000000001111111111111111110000000,
            64'b1110000000000111111111111000000000000001111111100000000001111111,
            64'b0001111100000111110000000111111000000001111000011111000001111110,
            64'b1001100011000111001110000111000111100001100110011100111001110001,
            64'b0101010010110100101101100100110110011001010101010010100101101001,
            64'b0001111001100110011011010010100101010100000011111000110011001101,
            64'b0110011010101010101101100110001111000001111100011011010101010100,
            64'b1010101100000000011001010101001000111110001101101101100000000110,
            64'b1000011011000000101010000000100100110000010100111001011000001010,
            64'b0111101110100001000001000001001110101101110010111011110100110000
        })
    ) mlut (
        .in(mant),
        .out(mant_out)
    );

    MultiBitLut #(
        .input_bits(6),
        .output_bits(15),
        .INIT({
            64'b1111111111111111111000000000000000000000000000000000000000000000,
            64'b0000000000000000000111111111111111111111111111111111111111111111,
            64'b0000000000000000000111111111111111111111111111111111111111111111,
            64'b0000000000000000000111111111111111111111111111111111111111111111,
            64'b0000000000000000000111111111111111111111111111111111111111111111,
            64'b0000000000000000000111111111111111111100000000000000000000000000,
            64'b1111100000000000000111111111000000000011111111111000000000000000,
            64'b0000011111110000000111100000111100000011111000000111111100000000,
            64'b1100011100001110000110011000110011100011000111000111100011110000,
            64'b0010011011001001100101010110101011010010110110110110010011001100,
            64'b1011010010101101010111111100001110011001100100100101001010101010,
            64'b1001000110000111111000011100110110101010101101101100011100000000,
            64'b0100100101100111000111100101010011000000011001001010010011000000,
            64'b1001110001010100111001101100011010110001101010011111001010110000,
            64'b0101110010000010100010111011101000101110100000010011010001101000
        })
    ) mlut_subnorm (
        .in(mant),
        .out(subnorm_out)
    );

    MultiBitLut #(
        .input_bits(6),
        .output_bits(15),
        .INIT({
            64'b0000000000000000000000000000000011111111111111111000000000000000,
            64'b0000000000000011111111111111111111111111111111000111111111111111,
            64'b0000000000000001111111111111111111111111111110100111111111111111,
            64'b0000000000000100011111111111111111111111111111000111111111111111,
            64'b0000000000000110100000000000111111111111111110010111111111111111,
            64'b0000000000000000001111111111111100000001111110110100000000000000,
            64'b0000000000000100100111111111000000000001111111011010000000000000,
            64'b0000000000000010110011111111000000000001111111100101000000000000,
            64'b0000000000000101110001111111000000000001111111111000100000000000,
            64'b0000000000000110101000111111000000000001111110011010010000000000,
            64'b0000000000000111011000011111000000000001111111101100001000000000,
            64'b0000000000000100011100001111000000000001111110000101000100000000,
            64'b0000000000000101000110000111000000000001111110010000000010000000,
            64'b0000000000000100111100000011000000000001111111100010100001000000,
            64'b0000000000000101101101000001000000000001111110100010000000100000
        })
    ) mlut_exp (
        .in({sign, exp}),
        .out(exp_out)
    );

    always @(*) begin
        exp_exp = {1'b0, exp_out};
        if(exp==5'b00000) begin
            mant_exp = {1'b0, subnorm_out};
        end else begin
            mant_exp = {5'b01000, mant_out};
        end
    end
endmodule