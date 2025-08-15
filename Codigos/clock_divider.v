// Definição de constantes
parameter CLK_FREQ = 50_000_000;  // Frequência do clock principal em Hertz (50 MHz)
parameter BAUD_RATE = 9600;      // Taxa de transmissão da UART em bits por segundo (9600 bps)
parameter CLK_PER_BIT = CLK_FREQ / BAUD_RATE; // Calcula quantos pulsos do clock principal são necessários para um único bit da UART.
                                               // 50.000.000 / 9600 = ~5208 pulsos.

// Declaração de registradores
reg [15:0] counter = 0; // Um contador de 16 bits para contar os pulsos do clock.
                         // O tamanho de 16 bits é suficiente para o valor 5208.
reg baud_clk = 0;       // O registrador que irá gerar o novo clock de baixa frequência.

// Lógica síncrona
always @(posedge clk) begin // Este bloco de código é executado em cada borda de subida do clock principal.

  if (counter == CLK_PER_BIT - 1) begin // Se o contador atingir o valor 5207...
    counter <= 0;                    // ...ele é resetado para 0, pronto para a próxima contagem.
    baud_clk <= ~baud_clk;           // ...e o valor do novo clock é invertido. Isso cria a onda quadrada.
  end else begin                 // Se o contador ainda não atingiu o valor final...
    counter <= counter + 1;      // ...ele simplesmente continua a contar.
  end

end