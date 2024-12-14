module FP8VectorMul (
    input clk,
    input rst,
    input e5m2mode,
    input [7:0] q,
    input [31:0] vec,

    output [63:0] res,
    output [17:0] B,
    output [47:0] C,
    output [47:0] PCIN,
    output [47:0] P,
    output [26:0] D,

    output [6:0] qa_exp,
    output [6:0] qb_exp,
    output [6:0] qc_exp,
    output [6:0] qd_exp
);
    /*
        q = fp8 value
        vec = fp8 vector {a, b, c, d}
        res = fp16 vector {qa, qb, qc, qd}
        
        q and vec can be in either e5m2mode or e4m3mode
    */
    wire [7:0] a;
    wire [7:0] b;
    wire [7:0] c;
    wire [7:0] d;
    assign a = vec[7:0];
    assign b = vec[15:8];
    assign c = vec[23:16];
    assign d = vec[31:24];

    // wire [26:0] D;
    // wire [17:0] B;
    // wire [47:0] C;
    // wire [47:0] PCIN;
    // wire [47:0] P;

    assign B = e5m2mode ? {16'b0, q[1:0]} : {15'b0, q[2:0]};
    assign D = e5m2mode 
                ? {13'b0, d[1:0], 2'b0, c[1:0], 2'b0, b[1:0], 2'b0, a[1:0]} 
                : { 6'b0, d[2:0], 3'b0, c[2:0], 3'b0, b[2:0], 3'b0, a[2:0]} ;
    assign C = e5m2mode
                ? {1'b0, d[6:2], 1'b0, c[6:2], 1'b0, b[6:2], 1'b0, a[6:2], 24'b0}
                : {1'b0, d[5:3], 1'b0, c[5:3], 1'b0, b[5:3], 1'b0, a[5:3], 28'b0};
    assign PCIN = e5m2mode
                ? {1'b0, q[6:2], 1'b0, q[6:2], 1'b0, q[6:2], 1'b0, q[6:2], 24'b0}
                : {1'b0, q[5:3], 1'b0, q[5:3], 1'b0, q[5:3], 1'b0, q[5:3], 28'b0};

    DSP dsp(
        .enable(1'b1),
        .clk(clk),
        .rst(rst),
        .A(30'd0),
        .B(B),
        .C(C),
        .D(D),
        .PCIN(PCIN),
        .ALUMODE(4'b0000),     // Z + W + X + Y + CIN
        .INMODE(5'b10101),     // M = D * B
        .OPMODE(9'b110010101), // XY = M, W = C, Z = PCIN
        .P(P)
    );

    // wire [6:0] qa_exp;
    // wire [6:0] qb_exp;
    // wire [6:0] qc_exp;
    // wire [6:0] qd_exp;
    assign qd_exp = e5m2mode 
                ? P[47:42]
                : {1'b0, P[47:43]};
    assign qc_exp = e5m2mode
                ? P[41:36]
                : {1'b0, P[42:37]};
    assign qb_exp = e5m2mode
                ? P[35:30]
                : {1'b0, P[37:32]};
    assign qa_exp = e5m2mode
                ? P[29:24]
                : {1'b0, P[32:27]};

    wire [7:0] qa_mant;
    wire [7:0] qb_mant;
    wire [7:0] qc_mant;
    wire [7:0] qd_mant;
    assign qa_mant = e5m2mode
                ? {2'b01, P[3:0], 4'b0000} + {2'b00, q[1:0], 4'b0000} + {2'b00, a[1:0], 4'b0000}
                : {2'b01, P[5:0]} + {2'b00, q[2:0], 3'b00} + {2'b00, a[2:0], 3'b00};
    // assign qa_exp = qa_exp + qa_mant[7] - (e5m2mode ? 8'd127 : -8'd1);
    // assign qa_exp = qa_exp[5] ? 6'b111111 : qa_exp;
    // assign qa_mant = qa_mant[7] ? qa_mant[7:0] : {qa_mant[6:0], 1'b0};
    // assign qa_mant = qa_exp[5] ? 8'b0 : qa_mant;
    assign res[15:0] = {q[7] ^ a[7], qa_exp[4:0], qa_mant, 2'b00};

    assign qb_mant = e5m2mode
                ? {2'b01, P[7:4], 4'b0000} + {2'b00, q[1:0], 4'b0000} + {2'b00, b[1:0], 4'b0000}
                : {2'b01, P[11:6]} + {2'b00, q[2:0], 3'b00} + {2'b00, b[2:0], 3'b00};
    // assign qb_exp = qb_exp + qb_mant[7] - (e5m2mode ? 8'd127 : -8'd1);
    // assign qb_exp = qb_exp[5] ? 6'b111111 : qb_exp;
    // assign qb_mant = qb_mant[7] ? qb_mant[7:0] : {qb_mant[6:0], 1'b0};
    // assign qb_mant = qb_exp[5] ? 8'b0 : qb_mant;
    assign res[31:16] = {q[7] ^ b[7], qb_exp[4:0], qb_mant, 2'b00};

    assign qc_mant = e5m2mode
                ? {2'b01, P[11:8], 4'b0000} + {2'b00, q[1:0], 4'b0000} + {2'b00, c[1:0], 4'b0000}
                : {2'b01, P[17:12]} + {2'b00, q[2:0], 3'b00} + {2'b00, c[2:0], 3'b00};
    // assign qc_exp = qc_exp + qc_mant[7] - (e5m2mode ? 8'd127 : -8'd1);
    // assign qc_exp = qc_exp[5] ? 6'b111111 : qc_exp;
    // assign qc_mant = qc_mant[7] ? qc_mant[7:0] : {qc_mant[6:0], 1'b0};
    // assign qc_mant = qc_exp[5] ? 8'b0 : qc_mant;
    assign res[47:32] = {q[7] ^ c[7], qc_exp[4:0], qc_mant, 2'b00};

    assign qd_mant = e5m2mode
                ? {2'b01, P[15:12], 4'b0000} + {2'b00, q[1:0], 4'b0000} + {2'b00, d[1:0], 4'b0000}
                : {2'b01, P[23:18]} + {2'b00, q[2:0], 3'b00} + {2'b00, d[2:0], 3'b00};
    // assign qd_exp = qd_exp + qd_mant[7] - (e5m2mode ? 8'd127 : -8'd1);
    // assign qd_exp = qd_exp[5] ? 6'b111111 : qd_exp;
    // assign qd_mant = qd_mant[7] ? qd_mant[7:0] : {qd_mant[6:0], 1'b0};
    // assign qd_mant = qd_exp[5] ? 8'b0 : qd_mant;
    assign res[63:48] = {q[7] ^ d[7], qd_exp[4:0], qd_mant, 2'b00};
endmodule