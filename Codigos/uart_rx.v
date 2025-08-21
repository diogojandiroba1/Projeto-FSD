// -----------------------------------------------------------------------------
// UART Receiver (parametrizable)
// - Recebe LSB primeiro
// - Sincroniza entrada RX (2FF) e amostra no meio de cada bit
// -----------------------------------------------------------------------------
module uart_rx #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input        clk,
    input        reset,
    input        rx,           // entrada serial
    output reg [7:0] rx_data,  // byte recebido
    output reg       rx_valid, // 1 = dado válido disponível
    output reg       rx_error  // 1 = erro de stop bit
);

    localparam BIT_TIME  = CLK_FREQ / BAUD_RATE; // ciclos por bit
    localparam HALF_BIT  = BIT_TIME / 2;

    reg [3:0] state;
    reg [12:0] counter;
    reg [2:0] bit_idx;
    reg [7:0] shift_reg;

    // Estados
    localparam IDLE  = 0,
               START = 1,
               DATA  = 2,
               STOP  = 3;

    // Sincronizador de RX
    reg rx_ff1, rx_ff2;
    always @(posedge clk) begin
        rx_ff1 <= rx;
        rx_ff2 <= rx_ff1;
    end
    wire rx_s = rx_ff2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state    <= IDLE;
            counter  <= 0;
            bit_idx  <= 0;
            rx_valid <= 0;
            rx_error <= 0;
            rx_data  <= 8'h00;
            shift_reg<= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    rx_valid <= 0;
                    rx_error <= 0;
                    counter  <= 0;
                    if (rx_s == 1'b0) begin
                        state   <= START;
                        counter <= 0;
                    end
                end

                START: begin
                    if (counter == HALF_BIT-1) begin
                        if (rx_s == 1'b0) begin
                            state    <= DATA;
                            counter  <= 0;
                            bit_idx  <= 0;
                        end else state <= IDLE; // falso start
                    end else counter <= counter + 1;
                end

                DATA: begin
                    if (counter == BIT_TIME-1) begin
                        counter   <= 0;
                        shift_reg <= {rx_s, shift_reg[7:1]};
                        if (bit_idx == 7) begin
                            state   <= STOP;
                        end
                        bit_idx <= bit_idx + 1;
                    end else counter <= counter + 1;
                end

                STOP: begin
                    if (counter == BIT_TIME-1) begin
                        counter  <= 0;
                        state    <= IDLE;
                        if (rx_s == 1'b1) begin
                            rx_data  <= shift_reg;
                            rx_valid <= 1'b1;
                            rx_error <= 0;
                        end else begin
                            rx_valid <= 0;
                            rx_error <= 1'b1;
                        end
                    end else counter <= counter + 1;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
