module crc8 (
    input wire clk,          // Clock do sistema (50 MHz)
    input wire reset,        // Sinal de reset assíncrono
    input wire [7:0] data_in,    // Entrada de dados de 8 bits
    input wire data_valid,   // Sinal para indicar que um novo byte de dados está disponível
    input wire crc_init,     // Sinal para resetar o CRC para o valor inicial
    output reg [7:0] crc_out // Saída com o valor do CRC de 8 bits
);

// Parâmetro para o polinômio de CRC-8 (x^8 + x^2 + x + 1)
localparam [7:0] CRC_POLY = 8'h07;

// Registrador para o valor atual do CRC
reg [7:0] crc_reg;
reg [7:0] new_crc_val;
reg msb_bit;
integer i;

// Lógica para inicializar ou atualizar o CRC
always @(posedge clk or posedge reset) begin
    if (reset || crc_init) begin
        crc_reg <= 8'h00; // Valor inicial do CRC
    end else if (data_valid) begin
        // A lógica abaixo calcula o novo valor do CRC para o byte inteiro em um ciclo
        // O loop 'for' é usado aqui para descrever a lógica combinacional
        // que processa o byte de entrada, e é sintetizável.
        
        new_crc_val = crc_reg ^ data_in;
        
        for (i = 0; i < 8; i = i + 1) begin
            msb_bit = new_crc_val[7];
            new_crc_val <= {new_crc_val[6:0], 1'b0};
            if (msb_bit) begin
                new_crc_val <= new_crc_val ^ CRC_POLY;
            end
        end
        
        crc_reg <= new_crc_val;
    end
end

// Atribuição da saída
assign crc_out = crc_reg;

endmodule