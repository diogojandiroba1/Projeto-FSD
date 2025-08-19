`timescale 1ns/1ps

module uart_crc_system_tb;

    // Parâmetros de simulação
    parameter CLK_PERIOD = 20;      // 50 MHz (20 ns)
    parameter BAUD_RATE = 115200;
    parameter BIT_PERIOD = 8680;    // 1/115200 ≈ 8680 ns
    
    // Sinais de entrada/saída
    reg clk;
    reg reset;
    reg rx;
    reg btn_send;
    reg [7:0] user_data;
    wire tx;
    wire [7:0] display_data;
    wire [3:0] display_select;
    wire display_enable;
    wire led_rx, led_tx, led_crc;

    // Variáveis de teste
    reg [7:0] received_data;
    integer i;
    integer test_case;
    integer error_count;

    // Instância do DUT
    uart_crc_system dut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .btn_send(btn_send),
        .user_data(user_data),
        .tx(tx),
        .display_data(display_data),
        .display_select(display_select),
        .display_enable(display_enable),
        .led_rx(led_rx),
        .led_tx(led_tx),
        .led_crc(led_crc)
    );

    // Gerador de clock - FORMA CORRIGIDA
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    // Tarefa para enviar um byte via UART
    task uart_send_byte;
        input [7:0] data;
        integer i;
        begin
            // Start bit
            rx = 1'b0;
            #BIT_PERIOD;
            
            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #BIT_PERIOD;
            end
            
            // Stop bit
            rx = 1'b1;
            #BIT_PERIOD;
            
            $display("[TB] TX Byte: 0x%h (%s)", data, byte_to_ascii(data));
        end
    endtask
    
    // Tarefa para receber um byte via UART
    task uart_receive_byte;
        output [7:0] data;
        integer i;
        reg [7:0] buffer;
        begin
            // Wait for start bit
            @(negedge tx);
            #(BIT_PERIOD * 1.5); // Sample in middle of bit
            
            // Sample data bits
            for (i = 0; i < 8; i = i + 1) begin
                #BIT_PERIOD;
                buffer[i] = tx;
            end
            
            // Wait for stop bit
            #BIT_PERIOD;
            data = buffer;
            $display("[TB] RX Byte: 0x%h (%s)", data, byte_to_ascii(data));
        end
    endtask
    
    // Função para converter byte em ASCII (para display)
    function string byte_to_ascii;
        input [7:0] data;
        begin
            if (data >= 8'h20 && data <= 8'h7E)
                byte_to_ascii = $sformatf("%c", data);
            else
                byte_to_ascii = " ";
        end
    endfunction
    
    // Função para calcular CRC esperado
    function [7:0] calculate_expected_crc;
        input [7:0] data0, data1, data2, data3;
        reg [7:0] crc;
        integer i;
        begin
            crc = 8'hFF; // Initial value
            
            // Process each byte
            crc = crc ^ data0;
            for (i = 0; i < 8; i = i + 1) begin
                if (crc[0]) crc = (crc >> 1) ^ 8'h8C;
                else crc = crc >> 1;
            end
            
            crc = crc ^ data1;
            for (i = 0; i < 8; i = i + 1) begin
                if (crc[0]) crc = (crc >> 1) ^ 8'h8C;
                else crc = crc >> 1;
            end
            
            crc = crc ^ data2;
            for (i = 0; i < 8; i = i + 1) begin
                if (crc[0]) crc = (crc >> 1) ^ 8'h8C;
                else crc = crc >> 1;
            end
            
            crc = crc ^ data3;
            for (i = 0; i < 8; i = i + 1) begin
                if (crc[0]) crc = (crc >> 1) ^ 8'h8C;
                else crc = crc >> 1;
            end
            
            calculate_expected_crc = crc;
        end
    endfunction
    
    // Monitor de display
    task monitor_display;
        begin
            forever begin
                @(posedge clk);
                if (display_enable) begin
                    case (display_select)
                        4'b1110: $display("[DISPLAY] Digit 0: 0x%h (%s)", display_data, byte_to_ascii(display_data));
                        4'b1101: $display("[DISPLAY] Digit 1: 0x%h (%s)", display_data, byte_to_ascii(display_data));
                        4'b1011: $display("[DISPLAY] Digit 2: 0x%h (%s)", display_data, byte_to_ascii(display_data));
                        4'b0111: $display("[DISPLAY] Digit 3: 0x%h (%s)", display_data, byte_to_ascii(display_data));
                    endcase
                end
            end
        end
    endtask
    
    // Inicialização e sequência de teste
    initial begin
        // Inicialização
        clk = 0;
        reset = 1;
        rx = 1;
        btn_send = 0;
        user_data = 8'h00;
        error_count = 0;
        test_case = 0;
        
        // Criar arquivo de waveform
        $dumpfile("uart_crc_system.vcd");
        $dumpvars(0, uart_crc_system_tb);
        
        // Iniciar monitor de display
        fork
            monitor_display();
        join_none
        
        // Sequência de reset
        #100;
        reset = 0;
        #100;
        
        $display("\n=== Iniciando Testes do Sistema UART Full-Duplex com CRC ===\n");
        
        // Teste 1: Envio 'TEST' e verificação de CRC
        test_case = 1;
        $display("\n=== TESTE %0d: Envio 'TEST' e verificação de CRC ===", test_case);
        
        uart_send_byte("T");
        uart_send_byte("E");
        uart_send_byte("S");
        uart_send_byte("T");
        
        #(BIT_PERIOD * 20);
        uart_receive_byte(received_data);
        
        if (received_data == calculate_expected_crc("T", "E", "S", "T")) begin
            $display("[TESTE %0d] SUCESSO! CRC correto: 0x%h", test_case, received_data);
        end else begin
            $display("[TESTE %0d] FALHA! CRC esperado: 0x%h, recebido: 0x%h", 
                     test_case, calculate_expected_crc("T", "E", "S", "T"), received_data);
            error_count = error_count + 1;
        end
        
        // Teste 3: Teste de full-duplex - FORMA CORRIGIDA
        test_case = 3;
        $display("\n=== TESTE %0d: Teste Full-Duplex ===", test_case);
        
        fork
            begin
                uart_send_byte("F");
                uart_send_byte("P");
                uart_send_byte("G");
                uart_send_byte("A");
            end
            begin
                #(BIT_PERIOD * 5);
                user_data = "X";
                btn_send = 1;
                #(CLK_PERIOD*2);
                btn_send = 0;
                $display("[TESTE %0d] Enviado dado do usuário: 0x%h (X)", test_case, "X");
                
                uart_receive_byte(received_data);
                if (received_data == "X") begin
                    $display("[TESTE %0d] SUCESSO! Dado do usuário recebido corretamente", test_case);
                end else begin
                    $display("[TESTE %0d] FALHA! Dado esperado: X, recebido: %h", test_case, received_data);
                    error_count = error_count + 1;
                end
            end
        join;  // PONTO E VÍRGULA ADICIONADO AQUI
        
        #(BIT_PERIOD * 20);
        uart_receive_byte(received_data);
        
        if (received_data == calculate_expected_crc("F", "P", "G", "A")) begin
            $display("[TESTE %0d] SUCESSO! CRC correto para 'FPGA': 0x%h", test_case, received_data);
        end else begin
            $display("[TESTE %0d] FALHA! CRC esperado: 0x%h, recebido: 0x%h", 
                     test_case, calculate_expected_crc("F", "P", "G", "A"), received_data);
            error_count = error_count + 1;
        end
        
        // Finalização
        #100;
        $display("\n=== Resumo dos Testes ===");
        $display("Total de testes executados: %0d", test_case);
        $display("Erros encontrados: %0d", error_count);
        
        if (error_count == 0) begin
            $display("SUCESSO! Todos os testes passaram.");
        end else begin
            $display("FALHA! Alguns testes não passaram.");
        end
        
        $finish;
    end
endmodule