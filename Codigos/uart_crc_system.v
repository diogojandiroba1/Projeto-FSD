module uart_crc_system (
    input clk,
    input reset,
    input rx,
    input btn_send,          // Botão para enviar dados
    input [7:0] user_data,   // Dados do usuário para enviar
    output tx,
    output [7:0] display_data,
    output [3:0] display_select,
    output display_enable,
    output reg led_rx,       // LED indicador RX
    output reg led_tx,       // LED indicador TX
    output reg led_crc       // LED indicador CRC
);

    // Sinais internos
    wire [7:0] tx_data;
    wire tx_start;
    wire tx_busy;
    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_error;
    wire [7:0] crc_value;
    wire crc_ready;
    
    // Registros para controle
    reg [7:0] message_0, message_1, message_2, message_3;
    reg [1:0] msg_ptr;
    reg msg_ready;
    reg user_send_req;
    
    // Máquina de Estados
    parameter [2:0] 
        IDLE = 3'd0,
        RECEIVING = 3'd1,
        CALC_CRC = 3'd2,
        SEND_CRC = 3'd3,
        USER_SEND = 3'd4;
    
    reg [2:0] state;

    // Instâncias dos módulos
    uart_tx transmitter (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    uart_rx receiver (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error)
    );

    crc8 crc_calculator (
        .clk(clk),
        .reset(reset),
        .data(rx_data),
        .data_valid(rx_valid && (state == RECEIVING)),
        .crc(crc_value),
        .crc_ready(crc_ready)
    );

    display_controller display (
        .clk(clk),
        .reset(reset),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .crc_value(crc_value),
        .crc_ready(crc_ready),
        .display_data(display_data),
        .display_select(display_select),
        .display_enable(display_enable)
    );

    // Lógica de controle
    assign tx_start = (state == SEND_CRC) || (state == USER_SEND);
    assign tx_data = (state == SEND_CRC) ? crc_value : user_data;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            msg_ptr <= 0;
            msg_ready <= 0;
            user_send_req <= 0;
            message_0 <= 8'h00;
            message_1 <= 8'h00;
            message_2 <= 8'h00;
            message_3 <= 8'h00;
            led_rx <= 0;
            led_tx <= 0;
            led_crc <= 0;
        end else begin
            // LEDs indicadores
            led_rx <= rx_valid;
            led_tx <= tx_start;
            led_crc <= crc_ready;
            
            // Lógica de envio pelo usuário
            if (btn_send && !tx_busy) begin
                user_send_req <= 1;
            end
            
            case (state)
                IDLE: begin
                    if (rx_valid) begin
                        // Recepção de dados
                        case (msg_ptr)
                            2'd0: message_0 <= rx_data;
                            2'd1: message_1 <= rx_data;
                            2'd2: message_2 <= rx_data;
                            2'd3: message_3 <= rx_data;
                        endcase
                        msg_ptr <= msg_ptr + 1;
                        state <= RECEIVING;
                    end else if (user_send_req) begin
                        // Envio iniciado pelo usuário
                        user_send_req <= 0;
                        state <= USER_SEND;
                    end
                end
                
                RECEIVING: begin
                    if (rx_valid) begin
                        case (msg_ptr)
                            2'd0: message_0 <= rx_data;
                            2'd1: message_1 <= rx_data;
                            2'd2: message_2 <= rx_data;
                            2'd3: message_3 <= rx_data;
                        endcase
                        if (msg_ptr == 2'd3) begin
                            msg_ptr <= 0;
                            msg_ready <= 1;
                            state <= CALC_CRC;
                        end else begin
                            msg_ptr <= msg_ptr + 1;
                        end
                    end
                end
                
                CALC_CRC: begin
                    if (crc_ready) begin
                        state <= SEND_CRC;
                    end
                end
                
                SEND_CRC: begin
                    if (!tx_busy) begin
                        state <= IDLE;
                    end
                end
                
                USER_SEND: begin
                    if (!tx_busy) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule