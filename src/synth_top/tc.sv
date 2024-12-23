module tensorcore_synth_fate_top(
    input clk,
    input rst,
    output [7:0] led_tri_io
);
    logic clk_600m;
    logic pll_locked;

    // Instantiate the clocking wizard
    clk_wiz_0 clock_gen (
        .clk_out1   (clk_600m),
        .locked     (pll_locked),
        .clk_in1    (clk),
        .reset      (rst)
    );

    reg [7:0] fp8state;
    reg [15:0] fp16state;
    reg [7:0] a [0:3][0:7];
    reg [7:0] b [0:7][0:3];
    reg [15:0] c [0:3][0:3];
    reg e5m2mode;
    reg in_valid;
    wire out_valid;
    wire [15:0] d [0:3][0:3];
    wire [15:0] test;

    assign test = d[0][0]^d[0][1]^d[0][2]^d[0][3]^d[1][0]^d[1][1]^d[1][2]^d[1][3]^d[2][0]^d[2][1]^d[2][2]^d[2][3]^d[3][0]^d[3][1]^d[3][2]^d[3][3];
    assign led_tri_io = test[7:0];

    tensorcore tensorcore_inst (
        .clk(clk_600m),
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
    always @(posedge clk_600m) begin
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