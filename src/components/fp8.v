module FP8VectorMulPipe1Design1 #(
    parameter integer ID_WIDTH = 4
) (
    input clk,
    input rst,
    input e5m2mode,
    input [7:0] q,
    input [31:0] vec,
    input [ID_WIDTH-1:0] id,

    output [63:0] res,
    output reg [ID_WIDTH-1:0] id_out
);
    // Input Part
    wire [7:0] a;
    wire [7:0] b;
    wire [7:0] c;
    wire [7:0] d;
    reg [7:0] a_reg1; reg [7:0] a_reg2; reg[7:0] a_reg3;
    reg [7:0] b_reg1; reg [7:0] b_reg2; reg[7:0] b_reg3;
    reg [7:0] c_reg1; reg [7:0] c_reg2; reg[7:0] c_reg3;
    reg [7:0] d_reg1; reg [7:0] d_reg2; reg[7:0] d_reg3;
    reg [7:0] q_reg1; reg [7:0] q_reg2; reg[7:0] q_reg3;
    assign a = vec[7:0];
    assign b = vec[15:8];
    assign c = vec[23:16];
    assign d = vec[31:24];

    wire [17:0] B;
    wire [47:0] C; reg [47:0] Creg1;
    wire [47:0] P;
    wire [29:0] A;
    assign B = e5m2mode ? {16'b1, q[1:0]} : {15'b1, q[2:0]};
    assign A = e5m2mode 
                ? {10'b0, d[1:0], 4'b0, c[1:0], 4'b0, b[1:0], 4'b0, a[1:0]} 
                : { 3'b0, d[2:0], 5'b0, c[2:0], 5'b0, b[2:0], 5'b0, a[2:0]} ;
    assign C = e5m2mode
                ? {26'b0, d[1:0], 4'b0, c[1:0], 4'b0, b[1:0], 4'b0, a[1:0], 2'b0}
                : {18'b0, d[2:0], 5'b0, c[2:0], 5'b0, b[2:0], 5'b0, a[2:0], 3'b0};

    /*
        Enable input reg, pipe reg and output reg to implement pipeline for FP8VectorMul
        Since the output logic after DSP is still complex,
        we need to add a register between the DSP alu and output logic, which is the output reg here
    */
    DSP #(
        .INPUTREG(1),
        .OUTPUTREG(1),
        .DSPPIPEREG(1),
        .CONTROLREG(0),
        .NEEDPREADDER(0)
    ) dsp(
        .enable(1'b1),
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .C(Creg1),
        .ALUMODE(4'b0000),     // Z + W + X + Y + CIN
        .INMODE(5'b00000),     // M = A * B
        .OPMODE(9'b110000101), // XY = M, W = C, Z = 0
        .P(P)
    );

    // Output Part
    wire [15:0] qa;
    wire [15:0] qb;
    wire [15:0] qc;
    wire [15:0] qd;
    reg [5:0] qa_exp;
    reg [5:0] qb_exp;
    reg [5:0] qc_exp;
    reg [5:0] qd_exp;
    reg [5:0] qa_exp_reg;
    reg [5:0] qb_exp_reg;
    reg [5:0] qc_exp_reg;
    reg [5:0] qd_exp_reg;
    reg [7:0] qa_mant;
    reg [7:0] qb_mant;
    reg [7:0] qc_mant;
    reg [7:0] qd_mant;

    always @(*) begin
        if (e5m2mode) begin
            qa_mant = P[5:0];
            qb_mant = P[11:6];
            qc_mant = P[17:12];
            qd_mant = P[23:18];
        end else begin
            qa_mant = P[7:0];
            qb_mant = P[15:8];
            qc_mant = P[23:16];
            qd_mant = P[31:24];
        end
        qa_exp = qa_exp_reg + qa_mant[7];
        qb_exp = qb_exp_reg + qb_mant[7];
        qc_exp = qc_exp_reg + qc_mant[7];
        qd_exp = qd_exp_reg + qd_mant[7];
    end

    always @(posedge clk) begin
        if (e5m2mode) begin
            qa_exp_reg <= q_reg2[6:2] + a_reg2[6:2] + 6'd48;
            qb_exp_reg <= q_reg2[6:2] + b_reg2[6:2] + 6'd48;
            qc_exp_reg <= q_reg2[6:2] + c_reg2[6:2] + 6'd48;
            qd_exp_reg <= q_reg2[6:2] + d_reg2[6:2] + 6'd48;
        end else begin
            qa_exp_reg <= q_reg2[6:3] + a_reg2[6:3] + 6'd1;
            qb_exp_reg <= q_reg2[6:3] + b_reg2[6:3] + 6'd1;
            qc_exp_reg <= q_reg2[6:3] + c_reg2[6:3] + 6'd1;
            qd_exp_reg <= q_reg2[6:3] + d_reg2[6:3] + 6'd1;
        end
    end

    assign qa = {q_reg3[7] ^ a_reg3[7], qa_exp[5] ? 5'b11111 : qa_exp[4:0], qa_mant[7] ? qa_mant[6:1] : qa_mant[5:0], 4'b0000};
    assign qb = {q_reg3[7] ^ b_reg3[7], qb_exp[5] ? 5'b11111 : qb_exp[4:0], qb_mant[7] ? qb_mant[6:1] : qb_mant[5:0], 4'b0000};
    assign qc = {q_reg3[7] ^ c_reg3[7], qc_exp[5] ? 5'b11111 : qc_exp[4:0], qc_mant[7] ? qc_mant[6:1] : qc_mant[5:0], 4'b0000};
    assign qd = {q_reg3[7] ^ d_reg3[7], qd_exp[5] ? 5'b11111 : qd_exp[4:0], qd_mant[7] ? qd_mant[6:1] : qd_mant[5:0], 4'b0000};

    assign res = {qd, qc, qb, qa};

    reg [ID_WIDTH-1:0] id_reg1;
    reg [ID_WIDTH-1:0] id_reg2;

    always @(posedge clk) begin
        if (rst) begin
            Creg1 <= 48'b0;
            id_reg1 <= 0;
            id_reg2 <= 0;
            id_out <= 0;
            a_reg1 <= 0;
            a_reg2 <= 0;
            a_reg3 <= 0;
            b_reg1 <= 0;
            b_reg2 <= 0;
            b_reg3 <= 0;
            c_reg1 <= 0;
            c_reg2 <= 0;
            c_reg3 <= 0;
            d_reg1 <= 0;
            d_reg2 <= 0;
            d_reg3 <= 0;
            q_reg1 <= 0;
            q_reg2 <= 0;
            q_reg3 <= 0;
        end else begin
            Creg1 <= C;
            id_reg1 <= id;
            id_reg2 <= id_reg1;
            id_out <= id_reg2;
            a_reg1 <= a;
            a_reg2 <= a_reg1;
            a_reg3 <= a_reg2;
            b_reg1 <= b;
            b_reg2 <= b_reg1;
            b_reg3 <= b_reg2;
            c_reg1 <= c;
            c_reg2 <= c_reg1;
            c_reg3 <= c_reg2;
            d_reg1 <= d;
            d_reg2 <= d_reg1;
            d_reg3 <= d_reg2;
            q_reg1 <= q;
            q_reg2 <= q_reg1;
            q_reg3 <= q_reg2;
        end
    end
endmodule