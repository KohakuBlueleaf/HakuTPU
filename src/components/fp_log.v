module FP12PartialLog (
    input [11:0] a,
    output reg [15:0] exp_log,
    output reg [15:0] mant_log
);
    wire sign = a[11];
    wire [4:0] exp = a[10:6];
    wire [5:0] mant = a[5:0];
    wire [13:0] mant_out;
    wire [15:0] subnorm_out;
    wire [15:0] exp_out;

    MultiBitLut #(
        .input_bits(6),
        .output_bits(14),
        .INIT({
            64'b1111111111111111111111111111111111111111111111111111111111111110,
            64'b1111111111111111111111111111111111111111111111111111111000000000,
            64'b1111111111111111111111000000000000000000000000000000000111111000,
            64'b0000000000000000000000111111111111111111111110000000000111100100,
            64'b0000000000000000000000111111111111000000000001111100000110010110,
            64'b1111111100000000000000111111000000111111000001110011100101011110,
            64'b0000000011111110000000111000111000111000111001101011010111111110,
            64'b1111000011110001111000110110110110110110100101000110000000111110,
            64'b1100110011001001100100100101101101101100110011011010011011000110,
            64'b1010101010101101010110001100110110100101010100001100101001101010,
            64'b1111111000000111100011101010100100110001111111101010000101001000,
            64'b1000000111100110010010111111001101010110000001011100011011001000,
            64'b0111100110010101001000000000101011111010111101100010101100010000,
            64'b0110010101000000010001011110111100100010000010001010110000001100
        })
    ) mlut (
        .in(mant),
        .out(mant_out)
    );

    MultiBitLut #(
        .input_bits(6),
        .output_bits(16),
        .INIT({
            64'b1111111111111111111111111111111111111111111111111111111111111110,
            64'b0000000000000000000000000000000000000000000000000000000111111111,
            64'b1111111111111111111111111111111111111111111111111111111000000001,
            64'b0000000111111111111111111111111111111111111111111111111000000001,
            64'b0111111000000000000000000111111111111111111111111111111000000001,
            64'b1001111000000011111111111000000000000000111111111111111000000011,
            64'b0010011000111100000011111000000001111111000000000111111000001101,
            64'b0000101001001100011100111000011110000111000001111000111000110001,
            64'b0000000010010101101101011001100110011011000110011001001001010101,
            64'b0000011111001110110110001010101010101001011010101010011010000101,
            64'b0011101001010100101101101110000000001100001100000011010111000111,
            64'b0100100011000001100111000001100001110101101011000101001001101001,
            64'b1000011010100001010111001101011110011001100010111000111111111111,
            64'b0010110100011110000111011100111110110110011110111100010011011101,
            64'b0000001100000111001100000011010000000000000101001001100000001101,
            64'b0011110010110000011111011000010000110111011101100000111110101011
        })
    ) mlut_subnorm (
        .in(mant),
        .out(subnorm_out)
    );

    MultiBitLut #(
        .input_bits(5),
        .output_bits(16),
        .INIT({
            32'b00000000000000000111111111111111,
            32'b11111111111111000001111111111111,
            32'b00000000000000110110000000000000,
            32'b00000000000000110110000000000000,
            32'b11111000000000110110000000001111,
            32'b00000111111000100010001111110000,
            32'b00000111000100000000010001110000,
            32'b11000100100010110110100010010001,
            32'b10110110110110110110110110110110,
            32'b00100010010100000000010100100010,
            32'b01001111001101000001011001111001,
            32'b01100001010000000000000101000011,
            32'b10101011111111110111111111101010,
            32'b10000011100110110110110011100000,
            32'b01100010010100000000010100100011,
            32'b01011001001001000001001001001101
        })
    ) mlut_exp (
        .in(exp),
        .out(exp_out)
    );

    always @(*) begin
        exp_log = exp_out;
        if(exp==5'b00000) begin
            mant_log = subnorm_out;
        end else begin
            mant_log = {2'b0, mant_out};
        end
    end
endmodule