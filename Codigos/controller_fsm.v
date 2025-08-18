module controller_fsm (
    // Entradas do sistema
    input wire clk,
    input wire reset,
    input wire start_btn,
    
    // --- Interface com TX e seu CRC ---
    input  wire        tx_busy,
    output reg         tx_start,
    output reg [7:0]   tx_data,
    output reg         crc_init_tx,
    output reg         crc_data_valid_tx,
    output reg [7:0]   crc_data_in_tx,
    input  wire [7:0]  crc_out_tx,

    // --- Interface com RX e seu CRC ---
    input  wire        rx_done,
    input  wire [7:0]  rx_data,
    output reg         crc_init_rx,
    output reg         crc_data_valid_rx,
    output reg [7:0]   crc_data_in_rx,
    input  wire [7:0]  crc_out_rx,

    // Saída para o display
    output reg [1:0] display_status
);

localparam MSG_LEN = 3;

// =============================================================================
// 1. LÓGICA DE TRANSMISSÃO (TX FSM)
// =============================================================================
localparam [2:0] TX_IDLE = 3'b000, TX_CALC_CRC = 3'b001, TX_MSG_START = 3'b010,
                 TX_MSG_WAIT = 3'b011, TX_CRC_START = 3'b100, TX_CRC_WAIT = 3'b101,
                 TX_DONE = 3'b110;

reg [2:0] tx_state, tx_next_state;
reg [1:0] tx_msg_counter, tx_msg_counter_next;
reg [7:0] tx_crc_val, tx_crc_val_next;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        tx_state       <= TX_IDLE;
        tx_msg_counter <= 0;
        tx_crc_val     <= 0;
    end else begin
        tx_state       <= tx_next_state;
        tx_msg_counter <= tx_msg_counter_next;
        tx_crc_val     <= tx_crc_val_next;
    end
end

always @(*) begin
    tx_next_state       = tx_state;
    tx_msg_counter_next = tx_msg_counter;
    tx_crc_val_next     = tx_crc_val;
    tx_start            = 1'b0;
    tx_data             = 8'h00;
    crc_init_tx         = 1'b0;
    crc_data_valid_tx   = 1'b0;
    crc_data_in_tx      = 8'h00;

    case (tx_state)
        TX_IDLE: begin
            if (start_btn) begin
                tx_next_state = TX_CALC_CRC;
                tx_msg_counter_next = 0;
                crc_init_tx = 1'b1;
            end
        end
        TX_CALC_CRC: begin
            case (tx_msg_counter) 0: crc_data_in_tx = "O"; 1: crc_data_in_tx = "L"; 2: crc_data_in_tx = "A"; default: crc_data_in_tx = 8'hXX; endcase
            crc_data_valid_tx = 1'b1;
            if (tx_msg_counter == MSG_LEN - 1) begin
                tx_crc_val_next = crc_out_tx;
                tx_next_state = TX_MSG_START;
                tx_msg_counter_next = 0;
            end else begin
                tx_msg_counter_next = tx_msg_counter + 1;
            end
        end
        TX_MSG_START: begin
            case (tx_msg_counter) 0: tx_data = "O"; 1: tx_data = "L"; 2: tx_data = "A"; default: tx_data = 8'hXX; endcase
            tx_start = 1'b1;
            tx_next_state = TX_MSG_WAIT;
        end
        TX_MSG_WAIT: begin
            if (!tx_busy) begin
                if (tx_msg_counter == MSG_LEN - 1) begin
                    tx_next_state = TX_CRC_START;
                end else begin
                    tx_msg_counter_next = tx_msg_counter + 1;
                    tx_next_state = TX_MSG_START;
                end
            end
        end
        TX_CRC_START: begin
            tx_data = tx_crc_val;
            tx_start = 1'b1;
            tx_next_state = TX_CRC_WAIT;
        end
        TX_CRC_WAIT: if (!tx_busy) tx_next_state = TX_DONE;
        TX_DONE:     tx_next_state = TX_DONE;
    endcase
end

// =============================================================================
// 2. LÓGICA DE RECEPÇÃO (RX FSM)
// =============================================================================
localparam [1:0] RX_IDLE = 2'b00, RX_RECEIVING = 2'b01, RX_VERIFY = 2'b10, RX_DONE = 2'b11;

reg [1:0] rx_state, rx_next_state;
reg [1:0] rx_msg_counter, rx_msg_counter_next;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        rx_state       <= RX_IDLE;
        rx_msg_counter <= 0;
        display_status <= 2'b11;
    end else begin
        rx_state       <= rx_next_state;
        rx_msg_counter <= rx_msg_counter_next;
        if (rx_next_state == RX_DONE) begin
            if (crc_out_rx == 8'h00) display_status <= 2'b01; else display_status <= 2'b00;
        end else if (rx_next_state == RX_IDLE) begin
            display_status <= 2'b11;
        end
    end
end

always @(*) begin
    rx_next_state       = rx_state;
    rx_msg_counter_next = rx_msg_counter;
    crc_init_rx         = 1'b0;
    crc_data_valid_rx   = 1'b0;
    crc_data_in_rx      = 8'h00;

    case (rx_state)
        RX_IDLE: begin
            crc_init_rx = 1'b1;
            if (rx_done) begin
                rx_next_state = RX_RECEIVING;
                rx_msg_counter_next = 0;
            end
        end
        RX_RECEIVING: begin
            if (rx_done) begin
                crc_data_in_rx = rx_data;
                crc_data_valid_rx = 1'b1;
                if (rx_msg_counter == MSG_LEN) begin
                    rx_next_state = RX_VERIFY;
                end else begin
                    rx_msg_counter_next = rx_msg_counter + 1;
                end
            end
        end
        RX_VERIFY: rx_next_state = RX_DONE;
        RX_DONE:   rx_next_state = RX_DONE;
    endcase
end

endmodule