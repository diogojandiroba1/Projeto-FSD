module top_level (
    // Entradas e saídas da placa DE2
    input  wire CLOCK_50,        // Pino do clock de 50 MHz
    input  wire [1:0] KEY,         // Botões (KEY[0] = reset, KEY[1] = start)
    inout  wire UART_TXD,        // Pino de transmissão UART
    inout  wire UART_RXD,        // Pino de recepção UART
    output wire [6:0] HEX0,        // Display de 7 segmentos (da direita)
    output wire [6:0] HEX1         // Display de 7 segmentos (da esquerda)
);

// Pinos de controle internos
wire reset_n;
wire start_btn;
assign reset_n = KEY[0];
assign start_btn = KEY[1];

// Fios para conectar os módulos
wire baud_clk_en;
wire tx_busy;
wire tx_start;
wire [7:0] tx_data;
wire rx_done;
wire [7:0] rx_data;
wire crc_init;
wire crc_data_valid;
wire [7:0] crc_data_in;
wire [7:0] crc_out;
wire [1:0] display_status;
wire [6:0] hex0_seg;
wire [6:0] hex1_seg;

// Sinais para loopback de teste (se quiser conectar TX com RX)
wire rx_in_wire;
wire tx_out_wire;

// Conecta os pinos UART físicos a fios internos para o loopback
assign UART_TXD = tx_out_wire;
assign rx_in_wire = UART_RXD;

// Instância do divisor de clock
clock_divider clock_divider_inst (
    .clk(CLOCK_50),
    .baud_clk_en(baud_clk_en)
);

// Instância do controlador FSM
controller_fsm controller_fsm_inst (
    .clk(CLOCK_50),
    .reset(!reset_n), // Reset ativo em nível baixo
    .start_btn(start_btn),
    .tx_busy(tx_busy),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .rx_done(rx_done),
    .rx_data(rx_data),
    .crc_init(crc_init),
    .crc_data_valid(crc_data_valid),
    .crc_data_in(crc_data_in),
    .crc_out(crc_out),
    .display_status(display_status)
);

// Instância do transmissor UART
uart_tx uart_tx_inst (
    .clk(CLOCK_50),
    .reset(!reset_n), // Reset ativo em nível baixo
    .baud_clk_en(baud_clk_en),
    .data_in(tx_data),
    .start_tx(tx_start),
    .tx_out(tx_out_wire),
    .tx_busy(tx_busy)
);

// Instância do receptor UART
uart_rx uart_rx_inst (
    .clk(CLOCK_50),
    .reset(!reset_n), // Reset ativo em nível baixo
    .baud_clk_en(baud_clk_en),
    .rx_in(rx_in_wire),
    .data_out(rx_data),
    .rx_done(rx_done)
);

// Instância do módulo CRC-8
crc8 crc8_inst (
    .clk(CLOCK_50),
    .reset(!reset_n), // Reset ativo em nível baixo
    .data_in(crc_data_in),
    .data_valid(crc_data_valid),
    .crc_init(crc_init),
    .crc_out(crc_out)
);

// Instância do decodificador de display
display_decoder display_decoder_inst (
    .status_in(display_status),
    .hex0_out(hex0_seg),
    .hex1_out(hex1_seg)
);

// Conexão dos segmentos dos displays à saída
assign HEX0 = hex0_seg;
assign HEX1 = hex1_seg;

endmodule