// test_fp8.v
`timescale 1ns / 1ps


module FP12Inverse_tb;
    reg [11:0] a;
    wire [15:0] ainv;

    FP12Inverse fp12inv (
        .a(a),
        .b(ainv)
    );
    float_display #("a", 5, 6) fd (
        .float_num(a)
    );
    float_display #("1/a", 5, 10) fd2 (
        .float_num(ainv)
    );

    //main
    initial begin
        a = 0;
        #10; $display("--------------------");
        a = 16'b0_10000_100101; //3.125
        #10; $display("--------------------");
        a = 16'b0_10000_100100; //3.15625
        #10; $display("--------------------");
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, FP12Inverse_tb);
    end

endmodule