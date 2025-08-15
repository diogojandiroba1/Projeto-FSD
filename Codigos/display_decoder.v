module display_decoder (
    input wire [1:0] status_in,     // Entrada de status do CRC (00 = Erro, 01 = OK)
    output reg [6:0] hex0_out,       // Saída para o display mais à direita (HEX0)
    output reg [6:0] hex1_out        // Saída para o display ao lado (HEX1)
);

// Padrões de 7 segmentos para o ânodo comum (0=ligado, 1=desligado)
// O padrão é {a,b,c,d,e,f,g}
localparam OKAY_O = 7'b0000001; // O
localparam OKAY_K = 7'b0000001; // Para simplificar, o 'K' pode ser representado por algo simples
localparam ERR_E  = 7'b0000110; // E
localparam ERR_R  = 7'b0101111; // R

// Para um display de 7 segmentos de ânodo comum
localparam ZERO  = 7'b0000001; // 0
localparam UM    = 7'b1001111; // 1
localparam DOIS  = 7'b0010010; // 2
localparam TRES  = 7'b0000110; // 3
localparam QUATRO = 7'b1001100; // 4
localparam CINCO = 7'b0100100; // 5
localparam SEIS  = 7'b0100000; // 6
localparam SETE  = 7'b0001111; // 7
localparam OITO  = 7'b0000000; // 8
localparam NOVE  = 7'b0000100; // 9
localparam A_HEX = 7'b0001000; // A
localparam B_HEX = 7'b1100000; // B
localparam C_HEX = 7'b0110001; // C
localparam D_HEX = 7'b1000010; // D
localparam E_HEX = 7'b0000110; // E
localparam F_HEX = 7'b0001110; // F
localparam OFF   = 7'b1111111; // Display desligado

// Lógica combinacional
always @(*) begin
    case (status_in)
        2'b01: begin // CRC OK
            hex1_out = OKAY_O;
            hex0_out = OKAY_K;
        end
        2'b00: begin // CRC ERRO
            hex1_out = ERR_E;
            hex0_out = ERR_R;
        end
        default: begin // Estado padrão (displays apagados)
            hex1_out = OFF;
            hex0_out = OFF;
        end
    endcase
end

endmodule