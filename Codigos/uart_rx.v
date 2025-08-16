module uart_rx (
    input wire clk,          // Clock do sistema (50 MHz)
    input wire reset,        // Sinal de reset assíncrono
    input wire baud_clk_en,  // Sinal de enable do clock de baud rate
    input wire rx_in,        // Entrada de dados seriais
    output reg [7:0] data_out,   // Saída de dados paralelos de 8 bits
    output reg rx_done       // Sinal de "dados recebidos"
);

// Definição dos estados da máquina de estados
localparam [2:0] IDLE         = 3'b000;
localparam [2:0] START_DETECT = 3'b001;
localparam [2:0] RECEIVING    = 3'b010;
localparam [2:0] STOP_BIT     = 3'b011;

// Variáveis internas
reg [2:0] current_state, next_state; // Registradores para a máquina de estados
reg [7:0] data_buffer;               // Buffer temporário para armazenar os bits recebidos
reg [3:0] bit_counter;               // Contador para os 8 bits de dados
reg rx_in_sync;                      // Registrador para sincronizar a entrada rx_in
reg rx_in_d;                         // Segundo registrador para detectar a borda de descida

// Sincronização da entrada rx_in para evitar metestabilidade
always @(posedge clk or posedge reset) begin
    if (reset) begin
        rx_in_sync <= 1'b1;
        rx_in_d <= 1'b1;
    end else begin
        rx_in_sync <= rx_in;
        rx_in_d <= rx_in_sync;
    end
end

// Máquina de estados
always @(posedge clk or posedge reset) begin
    if (reset) begin
        current_state <= IDLE;
        data_out <= 8'h00;
        rx_done <= 1'b0;
        bit_counter <= 0;
    end else begin
        rx_done <= 1'b0; // Reseta o sinal rx_done a cada ciclo

        current_state <= next_state;

        case (current_state)
            IDLE: begin
                if (rx_in_d && !rx_in_sync) begin // Detecta a borda de descida do start bit
                    next_state = START_DETECT;
                end else begin
                    next_state = IDLE;
                end
            end

            START_DETECT: begin
                if (baud_clk_en) begin // Espera por meio bit para amostrar o start bit
                    next_state = RECEIVING;
                    bit_counter <= 0;
                end
            end

            RECEIVING: begin
                if (baud_clk_en) begin
                    data_buffer <= {rx_in_sync, data_buffer[7:1]}; // Desloca os bits recebidos
                    if (bit_counter == 7) begin
                        next_state = STOP_BIT;
                    end else begin
                        bit_counter <= bit_counter + 1;
                    end
                end
            end

            STOP_BIT: begin
                if (baud_clk_en) begin
                    if (rx_in_sync) begin // Verifica o bit de stop (nível alto)
                        data_out <= data_buffer; // Salva o dado recebido
                        rx_done <= 1'b1;          // Sinaliza que a recepção foi um sucesso
                    end
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end
end

endmodule
