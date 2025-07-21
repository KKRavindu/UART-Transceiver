`timescale 1ns / 1ps

module uart_tx (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [7:0] data,
    input  wire baud_tick,
    output reg  tx,
    output reg  busy
);

    reg [3:0] bit_index = 0;
    reg [9:0] shift_reg = 10'b1111111111;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx <= 1'b1;
            busy <= 0;
            bit_index <= 0;
            shift_reg <= 10'b1111111111;
        end else begin
            if (start && !busy) begin
                // Frame: start(0), data[7:0], stop(1)
                shift_reg <= {1'b1, data, 1'b0};
                busy <= 1;
                bit_index <= 0;
            end else if (baud_tick && busy) begin
                tx <= shift_reg[0];
                shift_reg <= {1'b1, shift_reg[9:1]};  // shift right with stop bit padding
                bit_index <= bit_index + 1;
                if (bit_index == 9) begin
                    busy <= 0;
                end
            end
        end
    end
endmodule
