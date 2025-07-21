`timescale 1ns / 1ps

module tb_invert_uart_transceiver_test;

    // Parameters
    parameter CLK_FREQ  = 50000000;
    parameter BAUD_RATE = 115200;
    parameter CLK_PERIOD = 20;  // 50 MHz = 20 ns period

    // DUT signals
    reg clk = 0;
    reg rst_n = 1;      // Active-low reset
    reg key1_n = 1;     // Active-low trigger
    wire txd;
    wire tx_busy;
    wire rxd;
    wire [7:0] rx_data;
    wire rx_valid;
    wire [7:0] leds;

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Connect TX to RX for loopback
    assign rxd = txd;

    // Invert active-low signals to active-high for the DUT
    wire rst  = ~rst_n;
    wire key1 = ~key1_n;

    // Instantiate DUT
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

    initial begin
        // Initial state
        rst_n = 1;
        key1_n = 1;

        // Apply reset
        #100;
        rst_n = 0;
        #100;
        rst_n = 1;

        // Wait a bit then press KEY1
        #1000;
        key1_n = 0;   // Press button
        #40;          // Hold for a short time
        key1_n = 1;   // Release

        // Wait for transmission and reception to complete
        #100000;

        // Check results
        if (leds == 8'hA5)
            $display("PASS: Received 0xA5 correctly.");
        else
            $display("FAIL: Unexpected LED value = %h", leds);

        $stop;
    end

endmodule
