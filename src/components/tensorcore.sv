module tensorcore (
    input wire clk,
    input wire rst,
    input e5m2mode,
    input in_valid,
    input wire [7:0] a [3:0][7:0],
    input wire [7:0] b [7:0][3:0],
    input wire [15:0] c [3:0][3:0],
    output wire [15:0] d [3:0][3:0],
    output reg out_valid
);
    reg [11:0] mul_intermediate [7:0][3:0][3:0];
    reg mul_outvalid [7:0][3:0];
    reg [11:0] acc_intermediate [6:0][3:0][3:0];
    reg acc_outvalid [6:0][3:0];
    reg [3:0] final_out_valid;
    assign out_valid = final_out_valid == 4'b1111;

    genvar i, j, acc_j;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                wire [11:0] qa, qb, qc, qd;
                wire out_valid_temp;
                FP8VectorMul1 fp8mul(
                    .clk(clk),
                    .rst(rst),
                    .e5m2mode(e5m2mode),
                    .in_valid(in_valid),
                    .out_valid(out_valid_temp),
                    .q(a[i][j]),
                    .a(b[j][0]),
                    .b(b[j][1]),
                    .c(b[j][2]),
                    .d(b[j][3]),
                    .qa(qa),
                    .qb(qb),
                    .qc(qc),
                    .qd(qd)
                );
                always @(posedge clk) begin
                    if (out_valid_temp) begin
                        mul_intermediate[j][i][0] <= qa;
                        mul_intermediate[j][i][1] <= qb;
                        mul_intermediate[j][i][2] <= qc;
                        mul_intermediate[j][i][3] <= qd;
                        mul_outvalid[j][i] <= 1;
                    end else begin
                        mul_outvalid[j][i] <= 0;
                    end
                end
            end
            for (acc_j = 0; acc_j < 4; acc_j = acc_j + 1) begin
                wire [11:0] aa, bb, cc, dd;
                wire out_valid_temp;
                FPVectorAdd #(
                    .EXP_BITS(5),
                    .MANT_BITS(6)
                ) fpadd (
                    .clk(clk),
                    .rst(rst),
                    .in_valid(mul_outvalid[2*acc_j][i] & mul_outvalid[2*acc_j+1][i]),
                    .out_valid(out_valid_temp),
                    .a_1(mul_intermediate[2*acc_j][i][0]),
                    .b_1(mul_intermediate[2*acc_j][i][1]),
                    .c_1(mul_intermediate[2*acc_j][i][2]),
                    .d_1(mul_intermediate[2*acc_j][i][3]),
                    .a_2(mul_intermediate[2*acc_j+1][i][0]),
                    .b_2(mul_intermediate[2*acc_j+1][i][1]),
                    .c_2(mul_intermediate[2*acc_j+1][i][2]),
                    .d_2(mul_intermediate[2*acc_j+1][i][3]),
                    .a_out(aa),
                    .b_out(bb),
                    .c_out(cc),
                    .d_out(dd)
                );
                always @(posedge clk) begin
                    if (out_valid_temp) begin
                        acc_intermediate[acc_j][i][0] <= aa;
                        acc_intermediate[acc_j][i][1] <= bb;
                        acc_intermediate[acc_j][i][2] <= cc;
                        acc_intermediate[acc_j][i][3] <= dd;
                        acc_outvalid[acc_j][i] <= 1;
                    end else begin
                        acc_outvalid[acc_j][i] <= 0;
                    end
                end
            end
            for (acc_j = 4; acc_j < 7; acc_j = acc_j + 1) begin
                wire [11:0] aa, bb, cc, dd;
                wire out_valid_temp;
                FPVectorAdd #(
                    .EXP_BITS(5),
                    .MANT_BITS(6)
                ) fpadd (
                    .clk(clk),
                    .rst(rst),
                    .in_valid(acc_outvalid[(acc_j-4)*2][i] & acc_outvalid[(acc_j-4)*2+1][i]),
                    .out_valid(out_valid_temp),
                    .a_1(acc_intermediate[(acc_j-4)*2][i][0]),
                    .b_1(acc_intermediate[(acc_j-4)*2][i][1]),
                    .c_1(acc_intermediate[(acc_j-4)*2][i][2]),
                    .d_1(acc_intermediate[(acc_j-4)*2][i][3]),
                    .a_2(acc_intermediate[(acc_j-4)*2+1][i][0]),
                    .b_2(acc_intermediate[(acc_j-4)*2+1][i][1]),
                    .c_2(acc_intermediate[(acc_j-4)*2+1][i][2]),
                    .d_2(acc_intermediate[(acc_j-4)*2+1][i][3]),
                    .a_out(aa),
                    .b_out(bb),
                    .c_out(cc),
                    .d_out(dd)
                );
                always @(posedge clk) begin
                    if (out_valid_temp) begin
                        acc_intermediate[acc_j][i][0] <= aa;
                        acc_intermediate[acc_j][i][1] <= bb;
                        acc_intermediate[acc_j][i][2] <= cc;
                        acc_intermediate[acc_j][i][3] <= dd;
                        acc_outvalid[acc_j][i] <= 1;
                    end else begin
                        acc_outvalid[acc_j][i] <= 0;
                    end
                end
            end
            
            wire [3:0] final_out_valid_temp;
            FPVectorAdd #(
                .EXP_BITS(5),
                .MANT_BITS(10)
            ) fp16add (
                .clk(clk),
                .rst(rst),
                .in_valid(acc_outvalid[6][i]),
                .out_valid(final_out_valid_temp[i]),
                .a_1({acc_intermediate[6][i][0], 4'b0}),
                .b_1({acc_intermediate[6][i][1], 4'b0}),
                .c_1({acc_intermediate[6][i][2], 4'b0}),
                .d_1({acc_intermediate[6][i][3], 4'b0}),
                .a_2(c[i][0]),
                .b_2(c[i][1]),
                .c_2(c[i][2]),
                .d_2(c[i][3]),
                .a_out(d[i][0]),
                .b_out(d[i][1]),
                .c_out(d[i][2]),
                .d_out(d[i][3])
            );
            always @(posedge clk) begin
                if (final_out_valid_temp[i]) begin
                    final_out_valid[i] <= 1;
                end else begin
                    final_out_valid[i] <= 0;
                end
            end
        end
    endgenerate
endmodule


module tensorcore_synth_fate_top(
    input clk,
    input rst,
    output [7:0] led_tri_io
);
    reg [7:0] fp8state;
    reg [15:0] fp16state;
    reg [7:0] a [3:0][7:0];
    reg [7:0] b [7:0][3:0];
    reg [15:0] c [3:0][3:0];
    reg e5m2mode;
    reg in_valid;
    wire out_valid;
    wire [15:0] d [3:0][3:0];
    wire [15:0] test;

    assign test = d[0][0]&d[0][1]&d[0][2]&d[0][3]&d[1][0]&d[1][1]&d[1][2]&d[1][3]&d[2][0]&d[2][1]&d[2][2]&d[2][3]&d[3][0]&d[3][1]&d[3][2]&d[3][3];
    assign led_tri_io = test[7:0];

    tensorcore tensorcore_inst (
        .clk(clk),
        .rst(rst),
        .e5m2mode(e5m2mode),
        .in_valid(in_valid),
        .out_valid(out_valid),
        .a(a),
        .b(b),
        .c(c),
        .d(d)
    );
    integer i, j;
    always @(posedge clk) begin
        if (rst) begin
            e5m2mode <= 0;
            in_valid <= 0;
            fp8state <= 0;
            fp16state <= 0;
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    a[i][j] <= 0;
                    b[j][i] <= 0;
                end
            end
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    c[i][j] <= 0;
                end
            end
        end else begin
            in_valid <= 1;
            e5m2mode <= ~e5m2mode;
            fp8state <= fp8state + 1;
            fp16state <= fp16state + 1;
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    a[i][j] <= fp8state;
                    b[j][i] <= fp8state;
                end
            end
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    c[i][j] <= fp16state;
                end
            end
        end
    end
endmodule