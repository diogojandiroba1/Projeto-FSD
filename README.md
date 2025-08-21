# UART Full-Duplex com Verificação de CRC em FPGA DE2

Este projeto implementa um sistema de comunicação serial UART full-duplex com cálculo de verificação de redundância cíclica (CRC). A funcionalidade é demonstrada e validada através de um **teste de loopback interno** em uma placa FPGA, onde o transmissor e o receptor são conectados para verificar a integridade da lógica de comunicação.

## Módulos do Projeto

O sistema é modularizado para clareza e reutilização. Os componentes principais são:

### `uart_tx.v`

[cite_start]O Transmissor UART (UART_TX) converte um byte de dados paralelo (8 bits) em um fluxo de dados serial[cite: 74].

-   [cite_start]**Funcionamento:** Opera como uma Máquina de Estados Finitos (FSM) com os estados `IDLE`, `START`, `DATA` e `STOP`[cite: 78].
-   [cite_start]**Controle de Fluxo:** A transmissão é iniciada por um pulso no sinal `tx_start`[cite: 74]. [cite_start]Enquanto transmite, o sinal `tx_busy` fica ativo para indicar que o módulo está ocupado[cite: 75, 83].
-   **Temporização:** A temporização dos bits é controlada internamente. [cite_start]O módulo usa as frequências de clock (`CLK_FREQ`) e a taxa de transmissão (`BAUD_RATE`) para calcular o número de ciclos de clock por bit (`BIT_TIME`)[cite: 76]. [cite_start]Um contador interno gerencia a duração de cada bit, eliminando a necessidade de um divisor de clock externo[cite: 77, 88].
-   [cite_start]**Formato de Envio:** Envia primeiro o bit menos significativo (LSB)[cite: 74, 87].

### `uart_rx.v`

[cite_start]O Receptor UART (UART_RX) executa a função inversa, convertendo o fluxo serial de volta para um byte de dados paralelo[cite: 1].

-   [cite_start]**Funcionamento:** Utiliza uma FSM para gerenciar o processo de recepção (`IDLE`, `START`, `DATA`, `STOP`)[cite: 5].
-   [cite_start]**Sincronização de Entrada:** Para evitar problemas de metaestabilidade, a entrada `rx` é passada por um sincronizador de dois flip-flops[cite: 6, 7, 8].
-   [cite_start]**Amostragem Robusta:** A principal característica para garantir a precisão da leitura é a amostragem no **meio de cada bit**[cite: 1]. [cite_start]Após detectar o bit de start, o módulo espera metade do tempo de um bit (`HALF_BIT`) para confirmar o início e, posteriormente, lê cada bit de dados em seu ponto central, onde o sinal é mais estável[cite: 3, 13].
-   [cite_start]**Saídas de Status:** Ao final da recepção, o módulo gera o sinal `rx_valid` se o quadro foi recebido com sucesso (incluindo a verificação do stop bit)[cite: 2, 21]. [cite_start]Caso o stop bit não seja detectado corretamente, o sinal `rx_error` é ativado[cite: 2, 22].

### `crc8.v`

[cite_start]Este módulo calcula o valor do CRC-8 para um byte de dados[cite: 63].

-   [cite_start]**Algoritmo:** Implementa a divisão polinomial para o polinômio padrão `x^8 + x^2 + x + 1` (representado como `8'h07`)[cite: 63, 65, 67].
-   [cite_start]**Operação:** O cálculo é realizado de forma combinacional dentro de uma função[cite: 65]. [cite_start]Quando o sinal `data_valid` é ativado, o módulo calcula o CRC para o `data` de entrada e ativa a saída `crc_ready` por um ciclo de clock[cite: 72, 73].
-   [cite_start]**Escopo:** Nesta implementação, o módulo calcula o CRC para um único byte por vez e não é acumulativo entre diferentes bytes[cite: 63].

### `de2_loopback_top.v`

[cite_start]Este é o módulo de topo que integra todos os outros componentes e faz a interface com os periféricos da placa DE2[cite: 28].

-   [cite_start]**Arquitetura:** Instancia os módulos `uart_tx`, `uart_rx` e `crc8`[cite: 38, 40, 42].
-   [cite_start]**Teste de Loopback:** A principal característica deste módulo é a conexão direta da saída do transmissor à entrada do receptor (`wire rx = tx;`)[cite: 39]. Isso permite que o sistema se autovalide sem a necessidade de um dispositivo externo.
-   **Interface com o Usuário:**
    -   [cite_start]`KEY[0]` funciona como um reset ativo-baixo para todo o sistema[cite: 29].
    -   [cite_start]`KEY[1]` é usado para iniciar a transmissão de dados[cite: 31]. [cite_start]Um detector de borda de subida garante que um único pulso `tx_start` seja gerado a cada vez que o botão é pressionado[cite: 33, 35].
    -   [cite_start]`SW[7:0]` fornecem o byte de dados a ser transmitido[cite: 34].
-   **Exibição de Resultados:**
    -   [cite_start]Para garantir uma visualização estável, os resultados da recepção são armazenados em registradores (latches)[cite: 43].
    -   [cite_start]`LEDR[7:0]` exibem o último byte recebido corretamente (`last_rx`)[cite: 48].
    -   [cite_start]`HEX2` exibe o nibble menos significativo do byte recebido[cite: 59].
    -   [cite_start]`HEX5` e `HEX4` exibem **"0k"** se a recepção foi bem-sucedida (`ok_latch` é ativado quando `!rx_error`)[cite: 47, 61, 62]. [cite_start]A lógica para renderizar os caracteres nos displays de 7 segmentos está implementada em funções internas (`hex7` e `glyph7`)[cite: 50, 55].
    -   [cite_start]`LEDG` exibe sinais de status como `rx_valid`, `tx_busy` e `rx_error`[cite: 49].

## Funcionamento e Demonstração

O fluxo de operação para o teste de loopback é o seguinte:

1.  [cite_start]**Entrada de Dados:** O usuário seleciona um byte de 8 bits utilizando as chaves `SW[7:0]`[cite: 34].
2.  [cite_start]**Início da Transmissão:** O usuário pressiona `KEY[1]`[cite: 31, 33]. [cite_start]O módulo de topo detecta a borda de subida e envia um pulso `tx_start` para o `uart_tx`[cite: 35].
3.  [cite_start]**Transmissão e Loopback:** O `uart_tx` serializa o byte e o envia através da sua saída `tx`[cite: 38]. [cite_start]Devido à conexão de loopback, este sinal é imediatamente recebido pela entrada `rx` do `uart_rx`[cite: 39].
4.  [cite_start]**Recepção e Validação:** O `uart_rx` processa o fluxo serial, reconstrói o byte e, ao final, verifica o stop bit[cite: 40]. [cite_start]Se tudo estiver correto, ele ativa `rx_valid`[cite: 21].
5.  [cite_start]**Cálculo do CRC:** A ativação de `rx_valid` serve como gatilho para o módulo `crc8`, que calcula o CRC do byte recém-chegado[cite: 42].
6.  [cite_start]**Exibição dos Resultados:** O byte recebido e o status de sucesso ("0k") são armazenados nos registradores e exibidos de forma contínua nos LEDs e displays de 7 segmentos até que uma nova transmissão seja iniciada[cite: 43, 46, 47, 48, 61, 62].

A funcionalidade full-duplex é inerente à arquitetura, pois os módulos `uart_tx` e `uart_rx` são completamente independentes, com suas próprias máquinas de estado, permitindo que operem simultaneamente. O teste de loopback valida com sucesso a lógica de ambos os módulos de uma só vez.