`timescale 1ns/1ps

module uart_tb;
    localparam int CLK_PERIOD_NS = 10;
    localparam int CLKS_PER_BIT  = 16;

    logic clk;
    logic rst_n;
    logic rx;
    logic tx;
    logic tx_start;
    logic [7:0] tx_data;
    logic tx_busy;
    logic [7:0] rx_data;
    logic rx_valid;

    // Loopback connection for basic sanity checks
    assign rx = tx;

    uart #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .tx(tx),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_busy(tx_busy),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    task automatic send_byte(input logic [7:0] data);
        begin
            @(negedge clk);
            tx_data  <= data;
            tx_start <= 1'b1;
            @(negedge clk);
            tx_start <= 1'b0;
            wait (tx_busy == 1'b0);
        end
    endtask

    initial begin
        rst_n    = 1'b0;
        tx_start = 1'b0;
        tx_data  = 8'h00;

        #(CLK_PERIOD_NS * 10);
        rst_n = 1'b1;

        send_byte(8'h55);
        wait (rx_valid == 1'b1);

        send_byte(8'hA5);
        wait (rx_valid == 1'b1);

        #(CLK_PERIOD_NS * 20);
        $finish;
    end

endmodule
