# UART full‐duplex com verificação de CRC - Transmissão e recebimento de mensagens com
detecção de erro e exibição de resultados em display. Implementado em uma FPGA DE2



## clock_divider.v 

* Este módulo é responsável por gerar um clock de baixa frequência a partir do clock principal da placa FPGA. Sua principal função é adaptar a alta frequência de operação da FPGA (50 MHz) para a taxa de transmissão mais lenta exigida pela comunicação serial UART (por exemplo, 9600 bps).
* O módulo utiliza um contador síncrono para dividir a frequência do clock de entrada. A lógica é baseada na relação entre a frequência do clock da FPGA (CLK_FREQ) e a taxa de transmissão desejada (BAUD_RATE).
* A constante CLK_PER_BIT é calculada para determinar o número de ciclos do clock de alta frequência que correspondem a um único bit na taxa de BAUD_RATE.
* O contador (counter) é incrementado a cada borda de subida do clock principal. Quando o contador atinge o valor de CLK_PER_BIT - 1, o sinal do novo clock (baud_clk) é invertido, e o contador é zerado. Esse processo se repete, gerando uma onda quadrada com uma frequência precisa, que é utilizada para sincronizar a transmissão e o recebimento de dados pela UART.

## uart_tx.v e uart_rx.v 

### uart_tx.v
O Transmissor UART (UART_TX) é um módulo fundamental para a comunicação serial. Sua função é converter um byte de dados paralelo (8 bits) em um fluxo de dados serial, adicionando os bits de controle necessários para a transmissão, como o bit de start e o bit de stop.

O módulo opera como uma Máquina de Estados Finitos (FSM). Ele aguarda por um comando de início de transmissão e, então, percorre uma sequência de estados para enviar cada bit no momento certo. O sincronismo é garantido pelo clock de baixa frequência (baud_clk), gerado pelo divisor de clock.

A sequência de transmissão de um byte segue os seguintes passos:

* Estado IDLE: O transmissor fica em estado de espera, com o pino de saída (tx_out) em nível lógico alto.

* Estado START_BIT: Ao receber um sinal para iniciar a transmissão, o módulo transiciona para este estado e coloca o pino tx_out em nível lógico baixo por um período de tempo equivalente a um bit.

* Estado DATA_BITS: Os 8 bits de dados são enviados um a um. Um contador de bits (bit_counter) é usado para controlar a posição de cada bit a ser transmitido, do bit menos significativo (LSB) para o mais significativo (MSB).

* Estado STOP_BIT: Após enviar todos os 8 bits de dados, o transmissor coloca o pino tx_out em nível lógico alto por um período de tempo, finalizando a transmissão do byte.

Após o envio do bit de stop, o módulo retorna ao estado IDLE, pronto para a próxima transmissão.

### uart_rx.v

O Receptor UART (UART_RX) é um módulo que converte um fluxo de dados serial de entrada (rx_in) de volta para um byte de dados paralelo (8 bits). Ele opera de forma assíncrona, pois não recebe um sinal de clock junto com os dados, dependendo de um clock interno de alta precisão (baud_clk_en) para sincronização.

O módulo usa uma Máquina de Estados Finitos (FSM) para gerenciar o processo de recepção. O fluxo de operação é o seguinte:

* Estado IDLE: O receptor fica monitorando a linha de entrada (rx_in), que permanece em nível lógico alto quando ociosa.

* Detecção de Bit de Start: O início de uma transmissão é detectado por uma transição de alto para baixo na linha rx_in. Ao detectar essa borda de descida, o módulo muda de estado.

* Sincronização e Amostragem: Para garantir a correta amostragem dos bits, o receptor espera por um período de meio bit após a detecção do bit de start. Isso permite que a amostragem dos dados ocorra no meio de cada período de bit, onde o sinal é mais estável.

* Recepção dos Bits de Dados: Um contador (bit_counter) é usado para receber os 8 bits de dados, um a um. Os bits são lidos em cada ciclo de baud_clk_en e armazenados em um registrador de deslocamento. A ordem de recebimento é do bit menos significativo (LSB) para o mais significativo (MSB).

* Verificação do Bit de Stop: Após receber os 8 bits de dados, o receptor verifica se o próximo bit é um bit de stop (nível lógico alto).

* Disponibilização dos Dados: Se a recepção for bem-sucedida, o byte de dados completo é transferido para a saída (data_out) e um sinal de rx_done é ativado por um ciclo de clock, indicando que um novo dado está disponível.

Após a verificação do bit de stop, o módulo retorna ao estado IDLE, pronto para uma nova recepção.

## crc8.v e display_decoder.v 

### crc8.v

Este módulo é um componente de lógica digital assíncrona, projetado para calcular e verificar a integridade de dados através do algoritmo CRC-8. Sua função é implementar a divisão polinomial para gerar um valor de 8 bits (o CRC) que serve como um código de detecção de erros.

A implementação é baseada no polinômio gerador padrão x^8 + x^2 + x + 1.

* No Transmissor: O módulo calcula o CRC dos dados a serem transmitidos. O valor resultante é então anexado ao pacote de dados.

* No Receptor: O módulo recalcula o CRC sobre o pacote de dados recebido (incluindo o CRC transmitido). O valor final do cálculo deve ser zero em uma transmissão sem erros.

A utilização do CRC-8 assegura a detecção de erros em bit-flips únicos e em rajadas de erro, garantindo a confiabilidade da comunicação serial.

### display_decoder.v

Este módulo atua como uma interface de saída, convertendo um código de status binário em um padrão de bits adequado para controlar um display de 7 segmentos. A sua arquitetura é puramente combinacional, pois a saída é uma função direta e imediata da entrada.

A lógica interna utiliza uma estrutura case para mapear os códigos de status fornecidos pelo módulo de controle (controller_fsm) para os padrões de ativação dos segmentos. Na placa DE2, que utiliza displays de ânodo comum, um nível lógico 0 é requerido para acender um segmento.

* O módulo recebe um código de status (ex: 01 para sucesso, 00 para erro).

* Ele traduz esse código para os caracteres "OK" ou "ER", que são então exibidos nos displays de 7 segmentos.

O decodificador é essencial para fornecer feedback visual em tempo real sobre o status da verificação do CRC, servindo como a interface primária entre o sistema de lógica digital e o usuário.

## controller_fsm.v 

Este módulo atua como a unidade de controle central do sistema. Ele é uma máquina de estados finitos que gerencia o fluxo de trabalho completo da comunicação UART, incluindo a inicialização, o cálculo e a verificação do CRC, e o controle dos módulos de transmissão e recepção. Ele também gerencia a exibição dos resultados no display de 7 segmentos.

Funcionamento
A FSM segue uma sequência de estados para cada ciclo de transmissão e recepção:

* IDLE: Espera um botão ser pressionado para iniciar.

* CALC_CRC: Envia cada byte da mensagem para o crc8.v para calcular o CRC.

* TX_MSG: Transmite a mensagem, byte a byte, usando o uart_tx.v.

* TX_CRC: Transmite o valor final do CRC.

* WAIT_RX: Espera o início da recepção do outro lado.

* RX_MSG: Recebe os bytes da mensagem e os envia para o crc8.v para a verificação.

* RX_CRC: Recebe o byte do CRC enviado pelo outro lado.

* VERIFY_CRC: Compara o CRC calculado com o recebido para determinar o resultado.

* UPDATE_DISPLAY: Ativa a saída que controla o display_decoder.v para mostrar "OK" ou "ERRO".

* DONE: Mantém o estado final até o próximo reset.

## top_level.v 

Este módulo é a camada superior da hierarquia do projeto. Ele não contém lógica de processamento complexa, mas sim a arquitetura que define as conexões entre os submódulos e a interface com o mundo exterior (os pinos da placa DE2). Sua função é instanciar cada um dos módulos criados anteriormente (clock_divider, uart_tx, uart_rx, etc.) e ligar suas portas de entrada e saída.

Funcionamento
* Definição dos Pinos: As portas de entrada e saída do módulo top_level correspondem diretamente aos pinos físicos da placa FPGA (como o clock de 50 MHz, os botões e os displays de 7 segmentos).

* Declaração de Fios (Wires): Vários fios internos são declarados para servir como "pontes" entre os diferentes módulos, permitindo que os sinais de controle e dados fluam entre eles.

* Instanciação dos Módulos: Cada submódulo é instanciado e conectado usando seus nomes de porta e os fios internos definidos.

# Implementação

A atribuição de pinos é a fase em que as portas de entrada e saída lógicas definidas no módulo top_level.v são mapeadas para os pinos físicos do circuito integrado FPGA. Este procedimento é realizado por meio de uma ferramenta de síntese, como o Quartus Prime Pin Planner, utilizando a documentação de layout da placa (no caso, a DE2).

Depois, ocorre a compilação e envio para a FPGA.

A demonstração da funcionalidade full-duplex é a prova final da capacidade de comunicação bidirecional e simultânea do sistema. Esta característica é fundamental para aplicações que exigem troca de dados em tempo real.


* Teste de Loopback: Utilizando uma única placa, o pino UART_TXD é fisicamente conectado ao UART_RXD. O projeto é configurado para enviar um pacote de dados com CRC e, em seguida, receber e verificar o mesmo pacote. A funcionalidade é validada quando o sistema realiza ambas as operações com sucesso e exibe um resultado positivo na verificação de CRC, indicando que a arquitetura do transmissor e do receptor operam de forma independente e correta.

