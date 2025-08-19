module uart_tx (
    input clk,
    input reset,
    input tx_start,
    input [7:0] tx_data,
    output reg tx,
    output reg tx_busy
);
    
    parameter CLK_FREQ = 50_000_000;
    parameter BAUD_RATE = 115200;
    localparam BIT_TIME = CLK_FREQ / BAUD_RATE;
    
    reg [3:0] state;
    reg [15:0] counter;
    reg [7:0] shift_reg;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 0;
            tx <= 1'b1;
            tx_busy <= 1'b0;
        end else begin
            case (state)
                0: begin // Idle
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        state <= 1;
                        counter <= 0;
                        tx_busy <= 1'b1;
                        tx <= 1'b0; // Start bit
                    end
                end
                
                1: begin // Data bits
                    if (counter == BIT_TIME-1) begin
                        counter <= 0;
                        if (state < 9) begin
                            tx <= shift_reg[0];
                            shift_reg <= {1'b0, shift_reg[7:1]};
                            state <= state + 1;
                        end else begin
                            tx <= 1'b1; // Stop bit
                            state <= 10;
                        end
                    end else begin
                        counter <= counter + 1;
                    end
                end
                
                10: begin // Stop bit
                    if (counter == BIT_TIME-1) begin
                        tx_busy <= 1'b0;
                        state <= 0;
                    end else begin
                        counter <= counter + 1;
                    end
                end
            endcase
        end
    end
endmodule