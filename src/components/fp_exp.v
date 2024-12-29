module FP16PartialExp (
    input [15:0] a,
    output [15:0] partial_exp1,
    output [15:0] partial_exp2
);
    wire sign = a[15];
    wire [4:0] exp = a[14:10];
    wire [9:0] mant = a[9:0];
    wire subnorm = exp==5'b00000;
    wire [25:0] fixed_point = subnorm?
                        (exp > 0 
                            ? {16'b0000000000000001, mant} << (exp - 15)
                            : {16'b0000000000000001, mant} >> (-exp + 15)
                        ) : {16'b0000000000000000, mant} >> 14;
    wire [10:0] overflow_part;
    wire [4:0] int, high_frac, low_frac;
    wire overflow;
    wire underflow;
    assign {overflow_part, int, high_frac, low_frac} = fixed_point;
    assign overflow = overflow_part != 11'd0;
    assign underflow = int == 5'b00000;

    wire [15:0] partial1, partial2;
    wire [14:0] int_out;
    wire [14:0] high_frac_out;
    wire [10:0] low_frac_out;
    assign partial1 = {1'b0, high_frac_out};
    assign partial2 = underflow ? {5'b00111, low_frac_out} : {1'b0, int_out};

    MultiBitLut #(
        .input_bits(6),
        .output_bits(15),
        .INIT({
            64'b0000000000000000000000000000000011111111111111111111111111111110,
            64'b0000000000000000000000000001111111111111111111111111111110000001,
            64'b0000000000000000000000001110011111111111111111111111110001110001,
            64'b0000000000000000000000110110100111111111111111111111101101101001,
            64'b0000000000000000000000010011001111111111111111111111011011001101,
            64'b0000000000000000000000001010100011111111111111111111101001010100,
            64'b0000000000000000000001011100001011111111111111111111111100001110,
            64'b0000000000000000000001000011001011111111111111111111001100110000,
            64'b0000000000000000000001011010111011111111111111111111111111010110,
            64'b0000000000000000000001011011001011111111111111111111011000100110,
            64'b0000000000000000000001011101110011111111111111111111000100010010,
            64'b0000000000000000000000111000100011111111111111111111101011000000,
            64'b0000000000000000000000010110110011111111111111111111100001001100,
            64'b0000000000000000000001110010101011111111111111111111101101110000,
            64'b0000000000000000000001110000111011111111111111111111110010111000
        })
    ) int_exp_lut (
        .in({sign, int}),
        .out(int_out)
    );

    MultiBitLut #(
        .input_bits(6),
        .output_bits(15),
        .INIT({
            64'b0000000000000000000000000000000011111111100000000000000000000000,
            64'b1111111111111111111111111111111100000000011111111111111111111111,
            64'b1111111111111111111111111111111100000000011111111111111111111111,
            64'b0000000001111111111111111111111100000000011111111111111111111111,
            64'b1111111110000000000000000000000100000000011111111111111111111111,
            64'b1111111110000000000000111111111000000000011111111110000000000000,
            64'b0000011110000000111111000001111011000000011111000001111100000000,
            64'b0001100110000111000111000110011000111100011000110001100011110000,
            64'b0110101010011001001001001010101010110010010100101001011011001100,
            64'b0011100000101010010010011100000000101001011110001100110110101010,
            64'b1010011000000011001001010010000001100011111110010101010011000000,
            64'b0001010110011101010011111011100001010011100110110000011010110000,
            64'b0110000111100110001010001001010010011011011011101000101000101000,
            64'b1011111101101101110001111101000001101110101010100101000111000100,
            64'b1011001100001100000000010001101011100000000101000010000101101000
        })
    ) high_frac_lut (
        .in({sign, high_frac}),
        .out(high_frac_out)
    );

    MultiBitLut #(
        .input_bits(6),
        .output_bits(11),
        .INIT({
            64'b0000000000000000000000000000000111111111111111111111111111111111,
            64'b1111111111111111111111111111111000000000000000000000000000000000,
            64'b1111111111111111111111111111111000000000000000000000000000000000,
            64'b1111111111111111111111111111111000000000000000000000000000000000,
            64'b1111111111111111111111111111111000000000000000000000000000000000,
            64'b0000000000000001111111111111111000000000000000000000000000000000,
            64'b0000000111111110000000011111111011111111111111110000000000000000,
            64'b0001111000011110000111100001111011111111000000001111111100000000,
            64'b0110011001100110011001100110011011110000111100001111000011110000,
            64'b1010101010101010101010101010101011001100110011001100110011001100,
            64'b1111110000000000000000000000000010101010101010101010101010101010
        })
    ) low_frac_lut (
        .in({sign, low_frac}),
        .out(low_frac_out)
    );

    assign partial_exp1 = overflow ? (sign? 16'b0000000000000000: 16'b0111110000000000) : partial1;
    assign partial_exp2 = overflow ? (sign? 16'b0000000000000000: 16'b0111110000000000) : partial2;
endmodule