`timescale 1ns / 1ps

module FP16Exponent_tb();
    reg clk;
    reg rst;
    reg in_valid;
    reg [15:0] a;
    reg [15:0] b;
    reg [15:0] c;
    wire out_valid;
    wire [63:0] a_real, b_real, c_real, out_real;
    wire signed [15:0] out;
    float_display #("a", 5, 10) fd1 (
        .float_num(a), .decoded(a_real)
    );
    float_display #("b", 5, 10) fd2 (
        .float_num(b), .decoded(b_real)
    );
    float_display #("c", 5, 10) fd3 (
        .float_num(c), .decoded(c_real)
    );
    float_display #("out", 5, 10) fd4 (
        .float_num(out), .decoded(out_real)
    );

    FP16FMA fma_unit(
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .a(a),
        .b(b),
        .c(c),
        .out(out),
        .out_valid(out_valid)
    );

    initial begin
        in_valid = 0;
        a = 0;
        b = 0;
        c = 0;
    end

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        #10 rst = 0;
        in_valid = 1;
        a = 16'b0_10000_0000000000;
        b = 16'b0_10000_1000000000;
        c = 16'b1_10011_1100000000;
        #10
        in_valid = 0;
        #40
        $display(
            "T=%0d, a=%f, b=%f, c=%f, out=%f",
            $time, $bitstoreal(a_real), $bitstoreal(b_real), $bitstoreal(c_real), $bitstoreal(out_real)
        );
        in_valid = 1;
        a = 16'b1_10000_0000000000;
        b = 16'b1_10000_0000000000;
        c = 16'b0_10001_1100000000;
        #10
        in_valid = 0;
        #40
        $display(
            "T=%0d, a=%f, b=%f, c=%f, out=%f",
            $time, $bitstoreal(a_real), $bitstoreal(b_real), $bitstoreal(c_real), $bitstoreal(out_real)
        );
        $finish;
    end

    // initial begin
    //     $monitor(
    //         "T=%0d, a=%f, b=%f, c=%f, out=%f",
    //         $time, $bitstoreal(a_real), $bitstoreal(b_real), $bitstoreal(c_real), $bitstoreal(out_real)
    //     );
    // end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, FP16Exponent_tb);
    end
endmodule