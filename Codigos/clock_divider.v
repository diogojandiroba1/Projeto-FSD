module clock_divider (
    input wire clk,
    output reg baud_clk_en
);

parameter CLK_FREQ = 50_000_000;
parameter BAUD_RATE = 9600;
parameter CLK_PER_BIT = CLK_FREQ / BAUD_RATE; // Aprox. 5208

reg [15:0] counter = 0;

always @(posedge clk) begin
    baud_clk_en <= 1'b0; // O padrão é zero
    if (counter == CLK_PER_BIT - 1) begin
        counter <= 0;
        baud_clk_en <= 1'b1; // Gera um pulso quando o contador atinge o valor máximo
    end else begin
        counter <= counter + 1;
    end
end

endmodule