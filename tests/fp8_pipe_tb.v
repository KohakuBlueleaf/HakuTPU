// test_fp8.v
`timescale 1ns / 1ps


module FP8VectorMulPipe_tb;
    reg clk, rst;
    reg in_valid;
    wire out_valid;
    reg [31:0] id;
    reg [31:0] id_out;
    wire [31:0] id_wire;
    reg [7:0] q;
    reg [7:0] a;
    reg [7:0] b;
    reg [7:0] c;
    reg [7:0] d;
    wire [31:0] vec = {d, c, b, a};
    wire [15:0] qa_out;
    wire [15:0] qb_out;
    wire [15:0] qc_out;
    wire [15:0] qd_out;
    reg [15:0] qa;
    reg [15:0] qb;
    reg [15:0] qc;
    reg [15:0] qd;

    always @(posedge clk) begin
        if(out_valid) begin
            qa <= qa_out;
            qb <= qb_out;
            qc <= qc_out;
            qd <= qd_out;
            id_out <= id_out + 1;
        end else begin
            id_out <= id_out;
            qa <= qa;
            qb <= qb;
            qc <= qc;
            qd <= qd;
        end
    end

    FP8VectorMulPipe1Design1 fp8 (
        .clk(clk),
        .rst(rst),
        .e5m2mode(1'b0),
        .q(q),
        .vec(vec),
        .qa(qa_out),
        .qb(qb_out),
        .qc(qc_out),
        .qd(qd_out),
        .in_valid(in_valid),
        .out_valid(out_valid)
    );

    //clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //setup
    initial begin
        qa = 0;
        qb = 0;
        qc = 0;
        qd = 0;
        in_valid = 0;
        id_out = 0;
        id = 0;
        q = 0;
        a = 0;
        b = 0;
        c = 0;
        d = 0;
    end

    //main
    initial begin
        rst = 1;
        #20
        rst = 0;
        in_valid = 1;
        // #10
        id = 1;
        q = {1'b0, 4'b0111, 3'b000}; // +1 * 2^(7-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = 1.0
        a = {1'b0, 4'b1001, 3'b100}; // +1 * 2^(9-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = 6
        b = {1'b1, 4'b1000, 3'b100}; // -1 * 2^(8-7) * (1 + 1/2 * 1 + 1/4 * 0 + 1/8 * 0) = -3
        c = {1'b0, 4'b1000, 3'b000}; // +1 * 2^(8-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = 2
        d = {1'b1, 4'b1001, 3'b000}; // -1 * 2^(9-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = -4
        #10;
        id = 2;
        q = {1'b0, 4'b0111, 3'b100}; // +1 * 2^(7-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = 1.5
        a = {1'b0, 4'b0111, 3'b100}; // +1 * 2^(7-7) * (1 + 1/2 * 1 + 1/4 * 0 + 1/8 * 0) = 1.5
        b = {1'b1, 4'b1000, 3'b100}; // -1 * 2^(8-7) * (1 + 1/2 * 1 + 1/4 * 0 + 1/8 * 0) = -3
        c = {1'b0, 4'b1000, 3'b000}; // +1 * 2^(8-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = 2
        d = {1'b1, 4'b1001, 3'b000}; // -1 * 2^(9-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = -4
        #10
        id = 3;
        q = {1'b1, 4'b1000, 3'b000}; // -1 * 2^(8-7) * (0 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = -2
        a = {1'b0, 4'b0111, 3'b100}; // +1 * 2^(7-7) * (1 + 1/2 * 1 + 1/4 * 0 + 1/8 * 0) = 1.5
        b = {1'b1, 4'b1000, 3'b100}; // -1 * 2^(8-7) * (1 + 1/2 * 1 + 1/4 * 0 + 1/8 * 0) = -3
        c = {1'b0, 4'b1000, 3'b000}; // +1 * 2^(8-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = 2
        d = {1'b1, 4'b1001, 3'b000}; // -1 * 2^(9-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = -4
        #10
        id = 4;
        q = {1'b1, 4'b0111, 3'b100}; // -1 * 2^(7-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = -1.5
        a = {1'b0, 4'b0111, 3'b100}; // +1 * 2^(7-7) * (1 + 1/2 * 1 + 1/4 * 0 + 1/8 * 0) = 1.5
        b = {1'b1, 4'b1000, 3'b100}; // -1 * 2^(8-7) * (1 + 1/2 * 1 + 1/4 * 0 + 1/8 * 0) = -3
        c = {1'b0, 4'b1000, 3'b000}; // +1 * 2^(8-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = 2
        d = {1'b1, 4'b1001, 3'b000}; // -1 * 2^(9-7) * (1 + 1/2 * 0 + 1/4 * 0 + 1/8 * 0) = -4
        #10
        in_valid = 0;
        #40;
        $finish;
    end

    initial begin
        $monitor(
            "Time = %f, rst=%b, id=%d, QA = %b, QB = %b, QC = %b , QD = %b", 
            $time, rst, id_out, qa, qb, qc, qd
        );
        $dumpfile("dump.vcd");
        $dumpvars(0, FP8VectorMulPipe_tb);
    end

endmodule