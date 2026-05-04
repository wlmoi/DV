// Simple 8N1 UART with separate TX and RX state machines.
module uart #(
    parameter int CLKS_PER_BIT = 434
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       rx,
    output logic       tx,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       tx_busy,
    output logic [7:0] rx_data,
    output logic       rx_valid
);

    typedef enum logic [1:0] {TX_IDLE, TX_START, TX_DATA, TX_STOP} tx_state_t;
    typedef enum logic [1:0] {RX_IDLE, RX_START, RX_DATA, RX_STOP} rx_state_t;

    tx_state_t tx_state;
    rx_state_t rx_state;

    logic [15:0] tx_clk_count;
    logic [2:0]  tx_bit_index;
    logic [7:0]  tx_shift;

    logic [15:0] rx_clk_count;
    logic [2:0]  rx_bit_index;
    logic [7:0]  rx_shift;

    // Transmit state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state     <= TX_IDLE;
            tx           <= 1'b1;
            tx_busy      <= 1'b0;
            tx_clk_count <= 16'd0;
            tx_bit_index <= 3'd0;
            tx_shift     <= 8'd0;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    tx           <= 1'b1;
                    tx_busy      <= 1'b0;
                    tx_clk_count <= 16'd0;
                    tx_bit_index <= 3'd0;
                    if (tx_start) begin
                        tx_shift <= tx_data;
                        tx_busy  <= 1'b1;
                        tx_state <= TX_START;
                    end
                end
                TX_START: begin
                    tx <= 1'b0;
                    if (tx_clk_count == CLKS_PER_BIT - 1) begin
                        tx_clk_count <= 16'd0;
                        tx_state     <= TX_DATA;
                    end else begin
                        tx_clk_count <= tx_clk_count + 1'b1;
                    end
                end
                TX_DATA: begin
                    tx <= tx_shift[tx_bit_index];
                    if (tx_clk_count == CLKS_PER_BIT - 1) begin
                        tx_clk_count <= 16'd0;
                        if (tx_bit_index == 3'd7) begin
                            tx_bit_index <= 3'd0;
                            tx_state     <= TX_STOP;
                        end else begin
                            tx_bit_index <= tx_bit_index + 1'b1;
                        end
                    end else begin
                        tx_clk_count <= tx_clk_count + 1'b1;
                    end
                end
                TX_STOP: begin
                    tx <= 1'b1;
                    if (tx_clk_count == CLKS_PER_BIT - 1) begin
                        tx_clk_count <= 16'd0;
                        tx_state     <= TX_IDLE;
                        tx_busy      <= 1'b0;
                    end else begin
                        tx_clk_count <= tx_clk_count + 1'b1;
                    end
                end
                default: begin
                    tx_state <= TX_IDLE;
                end
            endcase
        end
    end

    // Receive state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state     <= RX_IDLE;
            rx_clk_count <= 16'd0;
            rx_bit_index <= 3'd0;
            rx_shift     <= 8'd0;
            rx_data      <= 8'd0;
            rx_valid     <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            case (rx_state)
                RX_IDLE: begin
                    rx_clk_count <= 16'd0;
                    rx_bit_index <= 3'd0;
                    if (rx == 1'b0) begin
                        rx_state <= RX_START;
                    end
                end
                RX_START: begin
                    if (rx_clk_count == (CLKS_PER_BIT - 1) / 2) begin
                        if (rx == 1'b0) begin
                            rx_clk_count <= 16'd0;
                            rx_state     <= RX_DATA;
                        end else begin
                            rx_state <= RX_IDLE;
                        end
                    end else begin
                        rx_clk_count <= rx_clk_count + 1'b1;
                    end
                end
                RX_DATA: begin
                    if (rx_clk_count == CLKS_PER_BIT - 1) begin
                        rx_clk_count             <= 16'd0;
                        rx_shift[rx_bit_index]   <= rx;
                        if (rx_bit_index == 3'd7) begin
                            rx_bit_index <= 3'd0;
                            rx_state     <= RX_STOP;
                        end else begin
                            rx_bit_index <= rx_bit_index + 1'b1;
                        end
                    end else begin
                        rx_clk_count <= rx_clk_count + 1'b1;
                    end
                end
                RX_STOP: begin
                    if (rx_clk_count == CLKS_PER_BIT - 1) begin
                        rx_clk_count <= 16'd0;
                        rx_state     <= RX_IDLE;
                        rx_data      <= rx_shift;
                        rx_valid     <= 1'b1;
                    end else begin
                        rx_clk_count <= rx_clk_count + 1'b1;
                    end
                end
                default: begin
                    rx_state <= RX_IDLE;
                end
            endcase
        end
    end

endmodule
