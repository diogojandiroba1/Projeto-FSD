module top_level (
    // Entradas e saídas da placa DE2
    input  wire CLOCK_50,
    input  wire [1:0] KEY,
    output wire UART_TXD,
    input  wire UART_RXD,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1
);

// Pinos de controle internos
wire reset_n;
wire start_btn;
assign reset_n = KEY[0];
assign start_btn = KEY[1];

// Fios para conectar os módulos
wire baud_clk_en;
wire [1:0] display_status;
wire [6:0] hex0_seg;
wire [6:0] hex1_seg;

// --- Sinais do Transmissor (TX) ---
wire        tx_busy;
wire        tx_start;
wire [7:0]  tx_data;
wire        crc_init_tx;
wire        crc_data_valid_tx;
wire [7:0]  crc_data_in_tx;
wire [7:0]  crc_out_tx;

// --- Sinais do Receptor (RX) ---
wire        rx_done;
wire [7:0]  rx_data;
wire        crc_init_rx;
wire        crc_data_valid_rx;
wire [7:0]  crc_data_in_rx;
wire [7:0]  crc_out_rx;

// Instância do divisor de clock
clock_divider clock_divider_inst (
    .clk(CLOCK_50),
    .baud_clk_en(baud_clk_en)
);

// Instância do controlador FSM (com portas para as duas FSMs)
controller_fsm controller_fsm_inst (
    .clk(CLOCK_50),
    .reset(!reset_n),
    .start_btn(start_btn),
    
    // Conexões TX
    .tx_busy(tx_busy),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .crc_init_tx(crc_init_tx),
    .crc_data_valid_tx(crc_data_valid_tx),
    .crc_data_in_tx(crc_data_in_tx),
    .crc_out_tx(crc_out_tx),
    
    // Conexões RX
    .rx_done(rx_done),
    .rx_data(rx_data),
    .crc_init_rx(crc_init_rx),
    .crc_data_valid_rx(crc_data_valid_rx),
    .crc_data_in_rx(crc_data_in_rx),
    .crc_out_rx(crc_out_rx),
    
    .display_status(display_status)
);

// Instância do transmissor UART
uart_tx uart_tx_inst (
    .clk(CLOCK_50),
    .reset(!reset_n),
    .baud_clk_en(baud_clk_en),
    .data_in(tx_data),
    .start_tx(tx_start),
    .tx_out(UART_TXD),
    .tx_busy(tx_busy)
);

// Instância do receptor UART
uart_rx uart_rx_inst (
    .clk(CLOCK_50),
    .reset(!reset_n),
    .baud_clk_en(baud_clk_en),
    .rx_in(UART_RXD),
    .data_out(rx_data),
    .rx_done(rx_done)
);

// --- DUAS INSTÂNCIAS DO CRC-8 ---

// Instância 1: Para a lógica de transmissão
crc8 crc8_tx_inst (
    .clk(CLOCK_50),
    .reset(!reset_n),
    .data_in(crc_data_in_tx),
    .data_valid(crc_data_valid_tx),
    .crc_init(crc_init_tx),
    .crc_out(crc_out_tx)
);

// Instância 2: Para a lógica de recepção
crc8 crc8_rx_inst (
    .clk(CLOCK_50),
    .reset(!reset_n),
    .data_in(crc_data_in_rx),
    .data_valid(crc_data_valid_rx),
    .crc_init(crc_init_rx),
    .crc_out(crc_out_rx)
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