`timescale 1ns/1ps

module uart_tb_003;
    localparam int CLK_PERIOD_NS = 10;
    localparam int CLKS_PER_BIT  = 16;
    localparam time RX_DELAY      = (CLK_PERIOD_NS * CLKS_PER_BIT) / 2;

    int error_count;

    logic clk;
    logic rst_n;
    wire rx;
    logic tx;
    logic tx_start;
    logic [7:0] tx_data;
    logic tx_busy;
    logic [7:0] rx_data;
    logic rx_valid;

    // Loopback with half-bit delay to avoid sampling on TX edge
    assign #(RX_DELAY) rx = tx;

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
        $display("TEST FAIL: UART-003 (timeout)");
        $finish;
    end

    initial begin
        $display("Running test: UART-003");
        $dumpfile("waves/uart_003.vcd");
        $dumpvars(0, uart_tb_003);
    end

    task automatic send_byte(input logic [7:0] data);
        int cycles;
        begin
            @(posedge clk);
            tx_data  <= data;
            tx_start <= 1'b1;
            @(posedge clk);
            tx_start <= 1'b0;
            cycles = 0;
            while (tx_busy == 1'b1) begin
                @(posedge clk);
                cycles++;
                if (cycles > (CLKS_PER_BIT * 20)) begin
                    error_count++;
                    $error("TX busy timeout");
                    disable send_byte;
                end
            end
        end
    endtask

    task automatic expect_byte(input logic [7:0] exp);
        int cycles;
        bit seen;
        begin
            seen = 1'b0;
            for (cycles = 0; cycles <= (CLKS_PER_BIT * 40); cycles = cycles + 1) begin
                if (rx_valid === 1'b1) begin
                    seen = 1'b1;
                    cycles = (CLKS_PER_BIT * 40) + 1;
                end else begin
                    @(posedge clk);
                end
            end
            if (!seen) begin
                error_count++;
                $error("RX valid timeout");
            end else if (rx_data !== exp) begin
                error_count++;
                $error("RX mismatch: expected 0x%0h got 0x%0h", exp, rx_data);
            end
        end
    endtask

    initial begin
        rst_n    = 1'b0;
        tx_start = 1'b0;
        tx_data  = 8'h00;
        error_count = 0;

        #(CLK_PERIOD_NS * 10);
        rst_n = 1'b1;

        // Back-to-back bytes
        send_byte(8'h00);
        expect_byte(8'h00);

        send_byte(8'hFF);
        expect_byte(8'hFF);

        send_byte(8'h3C);
        expect_byte(8'h3C);

        #(CLK_PERIOD_NS * 20);
        if (error_count == 0) begin
            $display("TEST PASS: UART-003");
        end else begin
            $display("TEST FAIL: UART-003 (%0d errors)", error_count);
        end
        $finish;
    end

endmodule
