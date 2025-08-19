module display_controller (
    input clk,
    input reset,
    input [7:0] rx_data,
    input rx_valid,
    input rx_error,
    input [7:0] tx_data,
    input tx_start,
    input [7:0] crc_value,
    input crc_ready,
    output reg [7:0] display_data,
    output reg [3:0] display_select,
    output reg display_enable
);
    
    parameter CLK_FREQ = 50_000_000;
    parameter REFRESH_RATE = 1000; // 1kHz refresh rate
    
    reg [31:0] message_reg;    // Armazena últimos 4 bytes recebidos
    reg [7:0] last_tx_data;    // Último dado transmitido
    reg [7:0] last_crc;        // Último CRC calculado
    reg [1:0] state;           // Estado do multiplexador
    reg [19:0] counter;        // Contador para refresh
    reg error_flag;            // Flag de erro
    
    localparam DISPLAY_RX0 = 0;
    localparam DISPLAY_RX1 = 1;
    localparam DISPLAY_TX  = 2;
    localparam DISPLAY_CRC = 3;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            message_reg <= 32'h20202020; // Inicializa com espaços
            last_tx_data <= 8'h00;
            last_crc <= 8'h00;
            state <= 0;
            counter <= 0;
            error_flag <= 1'b0;
            display_enable <= 1'b0;
            display_data <= 8'h00;
            display_select <= 4'b1111;
        end else begin
            // Captura dados recebidos
            if (rx_valid && !rx_error) begin
                message_reg <= {message_reg[23:0], rx_data};
                error_flag <= 1'b0;
                display_enable <= 1'b1;
            end else if (rx_error) begin
                error_flag <= 1'b1;
                display_enable <= 1'b1;
            end
            
            // Captura dados transmitidos
            if (tx_start) begin
                last_tx_data <= tx_data;
            end
            
            // Captura CRC calculado
            if (crc_ready) begin
                last_crc <= crc_value;
            end
            
            // Multiplexação do display (refresh rate ~1ms)
            if (counter >= (CLK_FREQ/REFRESH_RATE)) begin
                counter <= 0;
                state <= state + 1;
                if (state == 3) state <= 0;
            end else begin
                counter <= counter + 1;
            end
            
            // Seleção do display
            case (state)
                DISPLAY_RX0: begin
                    display_select <= 4'b1110;
                    display_data <= error_flag ? 8'h45 : message_reg[7:0]; // 'E' para erro
                end
                DISPLAY_RX1: begin
                    display_select <= 4'b1101;
                    display_data <= message_reg[15:8];
                end
                DISPLAY_TX: begin
                    display_select <= 4'b1011;
                    display_data <= last_tx_data;
                end
                DISPLAY_CRC: begin
                    display_select <= 4'b0111;
                    display_data <= last_crc;
                end
            endcase
        end
    end
endmodule