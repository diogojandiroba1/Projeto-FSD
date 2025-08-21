module uart_tx #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input        clk,
    input        reset,
    input        tx_start,     // pulso de 1 ciclo para iniciar transmissão
    input  [7:0] tx_data,      // byte a transmitir
    output reg   tx,           // saída serial
    output reg   tx_busy       // 1 = ocupada
);

    localparam BIT_TIME = CLK_FREQ / BAUD_RATE; // ciclos por bit (~434 em 50MHz/115200)

    reg [3:0] state;
    reg [12:0] counter;
    reg [2:0] bit_idx;
    reg [7:0] shift_reg;

    // Estados
    localparam IDLE  = 0,
               START = 1,
               DATA  = 2,
               STOP  = 3;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx        <= 1'b1;  // linha idle = HIGH
            tx_busy   <= 1'b0;
            state     <= IDLE;
            counter   <= 0;
            bit_idx   <= 0;
            shift_reg <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    tx      <= 1'b1;
                    tx_busy <= 1'b0;
                    counter <= 0;
                    if (tx_start) begin
                        tx_busy   <= 1'b1;
                        shift_reg <= tx_data;
                        tx        <= 1'b0; // start bit
                        state     <= START;
                        counter   <= 0;
                    end
                end

                START: begin
                    if (counter == BIT_TIME-1) begin
                        counter <= 0;
                        tx      <= shift_reg[0];
                        state   <= DATA;
                        bit_idx <= 0;
                    end else counter <= counter + 1;
                end

                DATA: begin
                    if (counter == BIT_TIME-1) begin
                        counter   <= 0;
                        bit_idx   <= bit_idx + 1;
                        shift_reg <= {1'b0, shift_reg[7:1]}; // desloca LSB → MSB
                        if (bit_idx == 7) begin
                            tx    <= 1'b1; // prepara stop
                            state <= STOP;
                        end else begin
                            tx    <= shift_reg[1];
                        end
                    end else counter <= counter + 1;
                end

                STOP: begin
                    if (counter == BIT_TIME-1) begin
                        counter <= 0;
                        state   <= IDLE;
                    end else counter <= counter + 1;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
