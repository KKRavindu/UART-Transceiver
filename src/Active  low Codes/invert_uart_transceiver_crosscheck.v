`timescale 1ns / 1ps

module invert_uart_transceiver_crosscheck #(
    parameter CLK_FREQ  = 50000000,      // Clock frequency in Hz
    parameter BAUD_RATE = 115200         // UART baud rate
)(
    input  wire        clk,              // System clock
    input  wire        rst_n,            // Active-low reset (KEY0)
    input  wire        key1_n,           // Active-low transmit trigger (KEY1)
    output wire        txd,              // UART transmit pin
    output wire        tx_busy,          // UART transmit busy flag
    input  wire        rxd,              // UART receive pin
    output wire [7:0]  rx_data,          // Received 8-bit data
    output wire        rx_valid,         // Receive data valid flag
    output wire [7:0]  leds,             // Output received data to LEDs
    output wire [6:0]  seg0,             // 7-segment right digit
    output wire [6:0]  seg1              // 7-segment left digit
);

    wire rst = ~rst_n;                   // Invert reset (active-high inside logic)
    wire key1 = ~key1_n;                 // Invert key1 (active-high inside logic)

    wire baud_tick;                      // Baud rate tick
    reg [15:0] baud_cnt = 0;             // Baud rate counter

    reg tx_start;                        // UART transmit start signal
    reg [7:0] tx_data = 8'h00;           // Data to be transmitted

    // Debounce and edge detection for key1
    reg [2:0] key1_sync;                 // Shift register for synchronizing and edge detection
    wire key1_pressed;                   // Falling edge detected on key1

    always @(posedge clk) begin
        key1_sync <= {key1_sync[1:0], key1}; // Shift in the key1 signal
    end
    assign key1_pressed = (key1_sync[2:1] == 2'b10); // Detect falling edge (press)

    // Baud rate generator
    always @(posedge clk or posedge rst) begin
        if (rst)
            baud_cnt <= 0;                       // Reset baud counter
        else if (baud_cnt == (CLK_FREQ / BAUD_RATE - 1))
            baud_cnt <= 0;                       // Reset counter when threshold reached
        else
            baud_cnt <= baud_cnt + 1;            // Increment baud counter
    end

    assign baud_tick = (baud_cnt == 0);          // Tick high once per baud period

    // Transmitter instance
    uart_tx transmitter (
        .clk(clk),
        .rst(rst),
        .start(tx_start),            // Start transmission when high
        .data(tx_data),              // Data to transmit
        .baud_tick(baud_tick),       // Baud tick
        .tx(txd),                    // UART TX line
        .busy(tx_busy)               // TX busy status
    );

    // Receiver instance
    uart_rx receiver (
        .clk(clk),
        .rst(rst),
        .rx(rxd),                    // UART RX line
        .baud_tick(baud_tick),       // Baud tick
        .data(rx_data),              // Received data output
        .valid(rx_valid)             // Data valid flag
    );

    // Output received data to LEDs
    assign leds = rx_data;

    // Split received data for 7-segment display
    wire [3:0] upper_nibble = rx_data[7:4];
    wire [3:0] lower_nibble = rx_data[3:0];

    // 7-segment display decoders
    hex_to_7seg seg_decoder0 (
        .hex(lower_nibble),         // Show lower nibble
        .seg(seg0)
    );

    hex_to_7seg seg_decoder1 (
        .hex(upper_nibble),         // Show upper nibble
        .seg(seg1)
    );

    // Automatically process received data and prepare it for retransmission
    // This logic triggers transmission when a valid byte is received
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_data  <= 8'd0;        // Clear TX data on reset
            tx_start <= 1'b0;        // Clear TX start
        end else begin
            if (rx_valid && !tx_busy) begin
                // When valid data received and TX is idle:
                // Multiply lower nibble by 2 and transmit result
                tx_data <= {4'b0000, rx_data[3:0] << 1}; // Only use lower 4 bits, shift left (multiply by 2)
                tx_start <= 1'b1;     // Initiate transmission
            end else begin
                tx_start <= 1'b0;     // Clear start signal after 1 clock
            end
        end
    end

endmodule
