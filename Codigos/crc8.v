module crc8 (
    input wire clk,
    input wire reset,       // Reset assíncrono
    input wire [7:0] data_in,
    input wire data_valid,  // Enable para atualizar o CRC
    input wire crc_init,    // Inicialização síncrona
    output reg [7:0] crc_out 
);

    // Polinômio do CRC-8 (x^8 + x^2 + x + 1 -> 0x07)
    localparam [7:0] CRC_POLY = 8'h07;

    // Variáveis internas
    reg [7:0] next_crc;
    integer i;

    // Bloco SEQUENCIAL: flip-flop com reset assíncrono e inicialização síncrona
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset assíncrono
            crc_out <= 8'h00;
        end 
        else if (crc_init) begin
            // Inicialização síncrona
            crc_out <= 8'h00;
        end 
        else if (data_valid) begin
            // Atualiza o CRC quando há dado válido
            crc_out <= next_crc;
        end
    end

    // Bloco COMBINACIONAL: calcula o próximo valor do CRC
    always @(*) begin
        next_crc = crc_out ^ data_in;
        for (i = 0; i < 8; i = i + 1) begin
            if (next_crc[7]) begin
                next_crc = {next_crc[6:0], 1'b0} ^ CRC_POLY;
            end else begin
                next_crc = {next_crc[6:0], 1'b0};
            end
        end
    end

endmodule
