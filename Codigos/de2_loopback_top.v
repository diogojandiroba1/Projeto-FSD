module de2_loopback_top (
    input         CLOCK_50,
    input  [3:0]  KEY,
    input  [17:0] SW,
    output [17:0] LEDR,
    output [7:0]  LEDG,
    output [6:0]  HEX0,
    output [6:0]  HEX1,
    output [6:0]  HEX2,
    output [6:0]  HEX3,
    output [6:0]  HEX4,
    output [6:0]  HEX5,
	 output [6:0]  HEX6,
    output [6:0]  HEX7
);



  
    wire clk   = CLOCK_50;
    wire reset = ~KEY[0]; // ativo-baixo

    
    reg btn_ff1, btn_ff2;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            btn_ff1 <= 1'b0;
            btn_ff2 <= 1'b0;
        end else begin
            btn_ff1 <= ~KEY[1];
            btn_ff2 <= btn_ff1;
        end
    end
    wire btn_rise = btn_ff1 & ~btn_ff2;

    // Byte do usuário
    wire [7:0] user_data = SW[7:0];

    // UART TX
    wire tx, tx_busy;
    reg [7:0] tx_data;
    wire tx_start = btn_rise & ~tx_busy; 

    always @(posedge clk or posedge reset) begin
        if (reset) tx_data <= 8'h00;
        else       tx_data <= user_data;
    end

    uart_tx #(.CLK_FREQ(50_000_000), .BAUD_RATE(115200)) UTX (
        .clk(clk), .reset(reset),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx), .tx_busy(tx_busy)
    );

    // LOOPBACK interno
    wire rx = tx;

    // UART RX
    wire [7:0] rx_data;
    wire       rx_valid, rx_error;

    uart_rx #(.CLK_FREQ(50_000_000), .BAUD_RATE(115200)) URX (
        .clk(clk), .reset(reset),
        .rx(rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error)
    );

    // CRC do último byte recebido
    wire [7:0] crc_value;
    wire       crc_ready;
    crc8 UCRC (
        .clk(clk), .reset(reset),
        .data(rx_data),
        .data_valid(rx_valid),
        .crc(crc_value), .crc_ready(crc_ready)
    );

    // Latches para manter valores na tela até próximo envio
    reg [7:0] last_rx;
    reg [7:0] last_crc;
    reg       ok_latch;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            last_rx  <= 8'h00;
            last_crc <= 8'h00;
            ok_latch <= 1'b0;
        end else begin
            if (tx_start) ok_latch <= 1'b0; 
            if (rx_valid) begin
                last_rx <= rx_data;
                last_crc<= crc_value; // crc_ready costuma alinhar com rx_valid
                if (!rx_error) ok_latch <= 1'b1;
            end
        end
    end

    // ----------------------------
    // LEDs
    // ----------------------------
    assign LEDR[7:0]  = last_rx;
    assign LEDR[17:8] = 10'b0;
    assign LEDG[0] = rx_valid;
    assign LEDG[1] = tx_busy;
    assign LEDG[2] = rx_error;
    assign LEDG[7:3] = 5'b0;

    // ----------------------------
    // 7-seg decoder (hex)
    // ----------------------------
    function [6:0] hex7;
        input [3:0] x;
        case (x)
            4'h0: hex7 = 7'b1000000;
            4'h1: hex7 = 7'b1111001;
            4'h2: hex7 = 7'b0100100;
            4'h3: hex7 = 7'b0110000;
            4'h4: hex7 = 7'b0011001;
            4'h5: hex7 = 7'b0010010;
            4'h6: hex7 = 7'b0000010;
            4'h7: hex7 = 7'b1111000;
            4'h8: hex7 = 7'b0000000;
            4'h9: hex7 = 7'b0010000;
            4'hA: hex7 = 7'b0001000;
            4'hB: hex7 = 7'b0000011;
            4'hC: hex7 = 7'b1000110;
            4'hD: hex7 = 7'b0100001;
            4'hE: hex7 = 7'b0000110;
            4'hF: hex7 = 7'b0001110;
        endcase
    endfunction

    // Aproximações de letras em 7-seg (ordem [a b c d e f g], 1 = OFF)
    function [6:0] glyph7;
        input [7:0] ch;
        case (ch)
            "O": glyph7 = 7'b1000000; // zero
            // 'k' minúsculo aproximado: liga c, d, f, g (a,b,e off) => 1 1 0 0 1 0 0 = 1100100
            "k": glyph7 = 7'b1001000;
            default: glyph7 = 7'b1111111; // apagado
        endcase
    endfunction

    // ----------------------------
    // HEX displays
    // ----------------------------
    // Após recepção: HEX3..HEX0 = RX[7:4] RX[3:0] CRC[7:4] CRC[3:0]
    //assign HEX0 = hex7(last_crc[3:0]);
    //assign HEX1 = hex7(last_crc[7:4]);
    assign HEX2 = hex7(last_rx[3:0]);
    //assign HEX3 = hex7(last_rx[7:4]);
assign HEX6 = 7'b1111111;
assign HEX7 = 7'b1111111;
assign HEX0 = 7'b1111111;
assign HEX1 = 7'b1111111;
assign HEX3 = 7'b1111111;
    // Exibir "0k" em HEX5/HEX4 quando recepção ok (latched)
    assign HEX5 = ok_latch ? glyph7("O") : 7'b1111111; // 'O' como '0'
    assign HEX4 = ok_latch ? glyph7("k") : 7'b1111111; // 'k' aproximado

endmodule
