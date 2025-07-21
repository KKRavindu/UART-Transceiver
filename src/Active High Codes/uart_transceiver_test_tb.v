`timescale 1ns / 1ps

module uart_transceiver_test_tb;

    // Parameters
    localparam CLK_FREQ = 50000000;
    localparam BAUD_RATE = 9600;
    localparam CLK_PERIOD = 20; // 50 MHz = 20 ns clock

    // Testbench signals
    reg clk = 0;
    reg rst = 0;
    reg key1 = 0;
    wire txd;
    wire tx_busy;
    wire rxd;
    wire [7:0] rx_data;
    wire rx_valid;
    wire [7:0] leds;

    // Instantiate the DUT (Device Under Test)
    uart_transceiver_test #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .key1(key1),
        .txd(txd),
        .tx_busy(tx_busy),
        .rxd(rxd),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .leds(leds)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Loopback TX to RX
    assign rxd = txd;

    initial begin
        $display("Starting UART Transceiver Testbench...");

        // Apply reset
        rst = 1;
        #100;
        rst = 0;

        // Wait some time then press key1 to send
        #100000;
        key1 = 1;
        #40;      // Hold key1 for a few clock cycles
        key1 = 0;

        // Wait for data to be received
        #2000000;

        $display("Received byte: %h", rx_data);
        $finish;
    end

endmodule
