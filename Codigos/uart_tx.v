module uart_tx (
    input wire clk,
    input wire reset,
    input wire baud_clk_en,
    input wire [7:0] data_in,
    input wire start_tx,
    output reg tx_out,
    output reg tx_busy
);

// Definição dos estados da máquina de estados
localparam [1:0] IDLE      = 2'b00;
localparam [1:0] START_BIT = 2'b01;
localparam [1:0] DATA_BITS = 2'b10;
localparam [1:0] STOP_BIT  = 2'b11;

// Registradores de estado e dados
reg [1:0] current_state, next_state;
reg [7:0] data_buffer;
reg [2:0] bit_counter; // Contador para os 8 bits de dados (0 a 7)

// Bloco SEQUENCIAL: Atualiza os registradores na borda do clock
always @(posedge clk or posedge reset) begin
    if (reset) begin
        current_state <= IDLE;
        bit_counter   <= 0;
        data_buffer   <= 0;
    end else begin
        current_state <= next_state;
        if (next_state == IDLE) begin
            // Reseta contadores e buffers ao voltar para IDLE
            bit_counter <= 0;
        end else if (current_state == IDLE && next_state == START_BIT) begin
            // Captura o dado de entrada ao iniciar a transmissão
            data_buffer <= data_in;
        end else if (baud_clk_en && current_state == DATA_BITS && next_state == DATA_BITS) begin
            // Incrementa o contador de bits durante a transmissão
            bit_counter <= bit_counter + 1;
        end
    end
end

// Bloco COMBINACIONAL: Decide os próximos estados e as saídas
always @(*) begin
    // Valores padrão
    next_state = current_state;
    tx_out = 1'b1; // Linha fica em alta por padrão
    tx_busy = 1'b0;

    case (current_state)
        IDLE: begin
            tx_out = 1'b1;
            tx_busy = 1'b0;
            if (start_tx) begin
                next_state = START_BIT;
            end
        end

        START_BIT: begin
            tx_busy = 1'b1;
            tx_out = 1'b0; // Envia o bit de start
            if (baud_clk_en) begin
                next_state = DATA_BITS;
            end
        end

        DATA_BITS: begin
            tx_busy = 1'b1;
            tx_out = data_buffer[bit_counter]; // Envia o bit atual
            if (baud_clk_en) begin
                if (bit_counter == 7) begin
                    next_state = STOP_BIT;
                end else begin
                    next_state = DATA_BITS; // Permanece no estado para enviar o próximo bit
                end
            end
        end

        STOP_BIT: begin
            tx_busy = 1'b1;
            tx_out = 1'b1; // Envia o bit de stop
            if (baud_clk_en) begin
                next_state = IDLE;
            end
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end

endmodule