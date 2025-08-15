module controller_fsm (
    // Entradas do sistema
    input wire clk,              // Clock principal (50 MHz)
    input wire reset,            // Botão de reset
    input wire start_btn,        // Botão para iniciar a transmissão
    
    // Sinais de comunicação com a UART
    input wire tx_busy,          // Sinais de controle do uart_tx
    output reg tx_start,
    output reg [7:0] tx_data,
    
    input wire rx_done,          // Sinais de controle do uart_rx
    input wire [7:0] rx_data,
    
    // Sinais de comunicação com o CRC
    output reg crc_init,
    output reg crc_data_valid,
    output reg [7:0] crc_data_in,
    input wire [7:0] crc_out,
    
    // Saída para o display_decoder
    output reg [1:0] display_status
);

// Define a mensagem a ser enviada
localparam [7:0] MESSAGE [0:2] = {"O", "L", "A"};
localparam MSG_LEN = 3;

// Estados da máquina
localparam [3:0] IDLE           = 4'b0000;
localparam [3:0] CALC_CRC_MSG   = 4'b0001;
localparam [3:0] TX_MSG_START   = 4'b0010;
localparam [3:0] TX_MSG_WAIT    = 4'b0011;
localparam [3:0] TX_CRC_START   = 4'b0100;
localparam [3:0] TX_CRC_WAIT    = 4'b0101;
localparam [3:0] WAIT_RX        = 4'b0110;
localparam [3:0] RX_MSG_WAIT    = 4'b0111;
localparam [3:0] RX_CRC_WAIT    = 4'b1000;
localparam [3:0] VERIFY_CRC     = 4'b1001;
localparam [3:0] DONE           = 4'b1010;

// Registradores de estado e contadores
reg [3:0] current_state, next_state;
reg [3:0] msg_counter;
reg [7:0] tx_crc_val;
reg [7:0] rx_crc_val;
reg [3:0] rx_msg_counter;

// FSM: Transição de estado
always @(posedge clk or posedge reset) begin
    if (reset) begin
        current_state <= IDLE;
        msg_counter <= 0;
        rx_msg_counter <= 0;
        crc_init <= 1'b1;
        display_status <= 2'b11; // Status "desligado"
    end else begin
        current_state <= next_state;
        crc_init <= 1'b0;
    end
end

// FSM: Lógica de saída e transição de estado
always @(*) begin
    // Valores padrão
    next_state = current_state;
    tx_start = 1'b0;
    crc_data_valid = 1'b0;
    tx_data = 8'h00;
    
    case (current_state)
        IDLE: begin
            if (start_btn) begin
                next_state = CALC_CRC_MSG;
                msg_counter = 0;
                crc_init = 1'b1;
            end
        end

        CALC_CRC_MSG: begin
            crc_data_in = MESSAGE[msg_counter];
            crc_data_valid = 1'b1;
            if (msg_counter == MSG_LEN - 1) begin
                tx_crc_val = crc_out; // Armazena o CRC final
                next_state = TX_MSG_START;
                msg_counter = 0;
            end else begin
                msg_counter = msg_counter + 1;
            end
        end
        
        TX_MSG_START: begin
            tx_data = MESSAGE[msg_counter];
            tx_start = 1'b1;
            next_state = TX_MSG_WAIT;
        end
        
        TX_MSG_WAIT: begin
            if (!tx_busy) begin
                if (msg_counter == MSG_LEN - 1) begin
                    next_state = TX_CRC_START;
                end else begin
                    msg_counter = msg_counter + 1;
                    next_state = TX_MSG_START;
                end
            end
        end
        
        TX_CRC_START: begin
            tx_data = tx_crc_val;
            tx_start = 1'b1;
            next_state = TX_CRC_WAIT;
        end
        
        TX_CRC_WAIT: begin
            if (!tx_busy) begin
                next_state = WAIT_RX;
                rx_msg_counter = 0;
                crc_init = 1'b1; // Reinicia o CRC para a verificação
            end
        end
        
        WAIT_RX: begin
            if (rx_done) begin
                next_state = RX_MSG_WAIT;
                crc_data_in = rx_data; // Envia o primeiro byte recebido para o CRC
                crc_data_valid = 1'b1;
                rx_msg_counter = 0;
            end
        end
        
        RX_MSG_WAIT: begin
            if (rx_done) begin
                rx_msg_counter = rx_msg_counter + 1;
                crc_data_in = rx_data;
                crc_data_valid = 1'b1;
                if (rx_msg_counter == MSG_LEN - 1) begin
                    next_state = RX_CRC_WAIT;
                end
            end
        end
        
        RX_CRC_WAIT: begin
            if (rx_done) begin
                rx_crc_val = rx_data;
                next_state = VERIFY_CRC;
            end
        end
        
        VERIFY_CRC: begin
            // Se o CRC calculado com todos os bytes (incluindo o recebido) for zero, está ok.
            if (crc_out == 8'h00) begin
                display_status = 2'b01; // Sinal para o decodificador mostrar "OK"
            end else begin
                display_status = 2'b00; // Sinal para o decodificador mostrar "ERRO"
            end
            next_state = DONE;
        end
        
        DONE: begin
            // Fica aqui, esperando um reset para recomeçar
            if (reset) begin
                next_state = IDLE;
            end
        end

        default: next_state = IDLE;
    endcase
end

endmodule