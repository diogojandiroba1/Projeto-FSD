module uart_tx (
    input wire clk,          // Clock do sistema (geralmente 50 MHz)
    input wire reset,        // Sinal de reset assíncrono
    input wire baud_clk_en,  // Sinal de enable do clock de baud rate (do clock divider)
    input wire [7:0] data_in,   // Entrada de dados de 8 bits
    input wire start_tx,     // Sinal para iniciar a transmissão (borda de subida)
    output reg tx_out,       // Saída de dados seriais
    output reg tx_busy       // Sinal que indica que o transmissor está ocupado
);

// Definição dos estados da máquina de estados
localparam [2:0] IDLE       = 3'b000;
localparam [2:0] START_BIT  = 3'b001;
localparam [2:0] DATA_BITS  = 3'b010;
localparam [2:0] STOP_BIT   = 3'b011;

// Variáveis internas
reg [2:0] current_state, next_state; // Registradores para a máquina de estados
reg [7:0] data_buffer;               // Buffer para armazenar o byte a ser transmitido
reg [3:0] bit_counter;               // Contador para os 8 bits de dados
reg tx_reg;                          // Registrador temporário para a saída serial

// Lógica para a máquina de estados (transição)
always @(posedge clk or posedge reset) begin
    if (reset) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// Lógica de saída e transição de estados
always @(*) begin
    // Valores padrão
    next_state = current_state;
    tx_busy = 1'b0;
    tx_reg = tx_out;

    case (current_state)
        IDLE: begin
            tx_out = 1'b1; // Pino de saída em nível alto quando ocioso
            if (start_tx) begin
                data_buffer = data_in; // Salva o dado na entrada
                next_state = START_BIT; // Inicia a transmissão
            end
        end

        START_BIT: begin
            tx_busy = 1'b1;
            tx_out = 1'b0; // Envia o bit de start (nível baixo)
            if (baud_clk_en) begin
                bit_counter = 0;
                next_state = DATA_BITS;
            end
        end

        DATA_BITS: begin
            tx_busy = 1'b1;
            tx_out = data_buffer[bit_counter]; // Envia o bit atual (do LSB para o MSB)
            if (baud_clk_en) begin
                if (bit_counter == 7) begin // Se todos os 8 bits foram enviados
                    next_state = STOP_BIT;
                end else begin
                    bit_counter = bit_counter + 1; // Próximo bit
                end
            end
        end

        STOP_BIT: begin
            tx_busy = 1'b1;
            tx_out = 1'b1; // Envia o bit de stop (nível alto)
            if (baud_clk_en) begin
                next_state = IDLE; // Fim da transmissão, volta para o estado ocioso
            end
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end

endmodule