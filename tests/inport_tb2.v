module inport_switch_tb();

    // Parameters
    localparam DATA_WIDTH = 16;  // Using smaller width for easier testing
    localparam FIFO_DEPTH = 4096;  // Using smaller depth for simulation
    localparam CLK_PERIOD = 10;  // 100MHz clock
    
    // Signals
    reg                     clk;
    reg                     rst;
    reg  [DATA_WIDTH-1:0]   data_in;
    reg data_valid;
    wire                    port_busy;
    wire  [4:0]  port_valid;
    wire  [DATA_WIDTH-1:0]  port_out_north;
    wire  [DATA_WIDTH-1:0]  port_out_east;
    wire  [DATA_WIDTH-1:0]  port_out_south;
    wire  [DATA_WIDTH-1:0]  port_out_west;
    wire  [DATA_WIDTH-1:0]  port_out_local;
    wire  [DATA_WIDTH-1:0]  port_out;
    wire out_valid;
    wire [4:0] clear;
    
    // Test variables
    reg [7:0] i;
    
    // Instantiate FIFO
    InPortSwitch #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .POS_WIDTH(4),
        .POS_X(1),
        .POS_Y(1)
    ) switch (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .port_busy(port_busy),
        .port_out({port_out_local, port_out_west, port_out_south, port_out_east, port_out_north}),
        .port_valid(port_valid),
        .clear(clear)
    );

    OutPortSwitch #(
        .DATA_WIDTH(DATA_WIDTH)
    ) out_switch (
        .clk(clk),
        .rst(rst),
        .in_ports({port_out_local, port_out_west, port_out_south, port_out_east, port_out_north}),
        .ports_valid(port_valid),
        .ports_clear(clear),
        .port_out(port_out),
        .out_valid(out_valid),
        .busy(1'b0)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize signals
        rst = 1;
        data_valid = 0;
        data_in = 0;
        
        // Apply reset
        repeat(2) @(negedge clk);
        rst = 0;
        repeat(5) @(negedge clk);

        // Start Test
        @(negedge clk);
        data_valid = 1;
        for (i = 1; i < 9; i = i + 1) begin
            data_in = {4'h0, 4'h0, i}; // pos_x, pos_y, data
            @(negedge clk);
            data_in = {4'h0, 4'h2, i}; // pos_x, pos_y, data
            @(negedge clk);
            data_in = {4'h2, 4'h0, i}; // pos_x, pos_y, data
            @(negedge clk);
            data_in = {4'h2, 4'h2, i}; // pos_x, pos_y, data
            @(negedge clk);
            data_in = {4'h1, 4'h1, i}; // pos_x, pos_y, data
            @(negedge clk);
        end
        data_valid = 0;
        repeat(50) @(posedge clk);
        $display("Tests completed");
        $finish;
    end
    
    // Optional: Timeout
    initial begin
        #1000000;  // Adjust timeout value as needed
        $display("Timeout: Test did not complete in time");
        $finish;
    end
    
    // Optional: Dump waveform
    initial begin
        $dumpfile("inport_switch_tb.vcd");
        $dumpvars(0, inport_switch_tb);
    end

endmodule