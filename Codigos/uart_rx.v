module uart_rx (
    input clk,
    input reset,
    input rx,
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg rx_error
);

    parameter CLK_FREQ = 50_000_000;
    parameter BAUD_RATE = 115200;
    localparam BIT_TIME = CLK_FREQ / BAUD_RATE;
    localparam HALF_BIT = BIT_TIME / 2;
    
    reg [2:0] state;
    reg [15:0] counter;
    reg [7:0] shift_reg;
    reg [3:0] bit_counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 0;
            rx_data <= 8'h00;
            rx_valid <= 1'b0;
            rx_error <= 1'b0;
            counter <= 0;
            bit_counter <= 0;
            shift_reg <= 8'h00;
        end else begin
            rx_valid <= 1'b0;
            rx_error <= 1'b0;
            
            case (state)
                0: begin // Wait for start bit
                    if (rx == 1'b0) begin
                        state <= 1;
                        counter <= 0;
                    end
                end
                
                1: begin // Verify start bit
                    if (counter == HALF_BIT - 1) begin
                        if (rx == 1'b0) begin
                            state <= 2;
                            counter <= 0;
                            bit_counter <= 0;
                        end else begin
                            state <= 0;
                            rx_error <= 1'b1;
                        end
                    end else begin
                        counter <= counter + 1;
                    end
                end
                
                2: begin // Receive data bits
                    if (counter == BIT_TIME - 1) begin
                        counter <= 0;
                        if (bit_counter < 8) begin
                            shift_reg <= {rx, shift_reg[7:1]};
                            bit_counter <= bit_counter + 1;
                        end else begin
                            if (rx == 1'b1) begin
                                rx_data <= shift_reg;
                                rx_valid <= 1'b1;
                            end else begin
                                rx_error <= 1'b1;
                            end
                            state <= 0;
                        end
                    end else begin
                        counter <= counter + 1;
                    end
                end

                default: state <= 0;
            endcase
        end
    end
endmodule