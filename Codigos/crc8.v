module crc8 (
    input clk,
    input reset,
    input [7:0] data,
    input data_valid,
    output reg [7:0] crc,
    output reg crc_ready
);
    
    reg [7:0] crc_reg;
    reg [3:0] bit_count;
    reg calculating;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            crc_reg <= 8'hFF;       // Valor inicial CRC-8
            crc_ready <= 1'b0;
            bit_count <= 0;
            calculating <= 1'b0;
        end else begin
            crc_ready <= 1'b0;      // Reset do sinal ready
            
            if (data_valid && !calculating) begin
                // Novo dado recebido - inicia cálculo
                crc_reg <= crc_reg ^ data;
                bit_count <= 0;
                calculating <= 1'b1;
            end
            
            if (calculating) begin
                if (bit_count < 8) begin
                    // Processa um bit por ciclo de clock
                    if (crc_reg[0]) begin
                        crc_reg <= {1'b0, crc_reg[7:1]} ^ 8'h8C;
                    end else begin
                        crc_reg <= {1'b0, crc_reg[7:1]};
                    end
                    bit_count <= bit_count + 1;
                end else begin
                    // Cálculo completo
                    calculating <= 1'b0;
                    crc_ready <= 1'b1;
                    crc <= crc_reg;
                end
            end
        end
    end
endmodule