`timescale 1ns/1ps

module uart_tb_002;
    localparam int CLK_PERIOD_NS = 10;
    localparam int CLKS_PER_BIT  = 16;
    localparam time BIT_TIME      = CLK_PERIOD_NS * CLKS_PER_BIT;

    int error_count;

    logic clk;
    logic rst_n;
    logic rx;
    logic rx_drive;
    logic tx;
    logic tx_start;
    logic [7:0] tx_data;
    logic tx_busy;
    logic [7:0] rx_data;
    logic rx_valid;

    // RX is directly driven for start-bit detection test.
    assign rx = rx_drive;

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

    // Hard timeout to avoid hanging sims
    initial begin
        #(CLK_PERIOD_NS * CLKS_PER_BIT * 200);
        $display("TEST FAIL: UART-002 (timeout)");
        $finish;
    end

    initial begin
        $display("Running test: UART-002");
        $dumpfile("waves/uart_002.vcd");
        $dumpvars(0, uart_tb_002);
    end

    task automatic rx_wait_bit();
        begin
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task automatic drive_rx_frame(input logic [7:0] data);
        int i;
        begin
            // Offset transitions away from sampling edge
            rx_drive <= 1'b1;
            #(BIT_TIME / 2);

            // Start bit: rx = 0 for one bit period
            rx_drive <= 1'b0;
            #(BIT_TIME);

            // Data bits: LSB first
            for (i = 0; i < 8; i = i + 1) begin
                rx_drive <= data[i];
                #(BIT_TIME);
            end

            // Stop bit: rx = 1 for one bit period
            rx_drive <= 1'b1;
            #(BIT_TIME);
        end
    endtask

    task automatic expect_rx_valid();
        int cycles;
        bit seen;
        begin
            seen = 1'b0;
            for (cycles = 0; cycles <= (CLKS_PER_BIT * 20); cycles = cycles + 1) begin
                if (rx_valid === 1'b1) begin
                    seen = 1'b1;
                    cycles = (CLKS_PER_BIT * 20) + 1;
                end else begin
                    @(posedge clk);
                end
            end
            if (!seen) begin
                error_count++;
                $error("RX valid timeout");
            end
        end
    endtask

    initial begin
        rst_n    = 1'b0;
        tx_start = 1'b0;
        tx_data  = 8'h00;
        rx_drive = 1'b1;
        error_count = 0;

        #(CLK_PERIOD_NS * 10);
        rst_n = 1'b1;

        // Let RX settle on idle before start bit
        #(BIT_TIME);

        // Start bit detect (single frame on RX)
        fork
            drive_rx_frame(8'h00);
            expect_rx_valid();
        join

        #(CLK_PERIOD_NS * 20);
        if (error_count == 0) begin
            $display("TEST PASS: UART-002");
        end else begin
            $display("TEST FAIL: UART-002 (%0d errors)", error_count);
        end
        $finish;
    end

endmodule
