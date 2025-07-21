`timescale 1ns / 1ps

module uart_transceiver #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 115200
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        tx_start,
    input  wire [7:0]  tx_data,
    output wire        txd,
    output wire        tx_busy,

    input  wire        rxd,
    output wire [7:0]  rx_data,
    output wire        rx_valid
);

    wire baud_tick;
    reg [15:0] baud_cnt = 0;

    // Baud rate generator (tick at 1x baud rate)
    always @(posedge clk or posedge rst) begin
        if (rst)
            baud_cnt <= 0;
        else if (baud_cnt == (CLK_FREQ / BAUD_RATE - 1))
            baud_cnt <= 0;
        else
            baud_cnt <= baud_cnt + 1;
    end

    assign baud_tick = (baud_cnt == 0);

    // Transmitter instance
    uart_tx transmitter (
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .data(tx_data),
        .baud_tick(baud_tick),
        .tx(txd),
        .busy(tx_busy)
    );

    // Receiver instance
    uart_rx receiver (
        .clk(clk),
        .rst(rst),
        .rx(rxd),
        .baud_tick(baud_tick),
        .data(rx_data),
        .valid(rx_valid)
    );

endmodule
