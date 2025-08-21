module crc8 (
    input        clk,
    input        reset,
    input  [7:0] data,
    input        data_valid,
    output reg [7:0] crc,
    output reg       crc_ready
);
    // Polinômio 0x07
    function [7:0] crc8_byte;
        input [7:0] din;
        integer i;
        reg [7:0] c;
        begin
            c = 8'h00;
            for (i = 0; i < 8; i = i + 1) begin
                if ((c[7] ^ din[7-i]) == 1'b1)
                    c = {c[6:0], 1'b0} ^ 8'h07;
                else
                    c = {c[6:0], 1'b0};
            end
            crc8_byte = c;
        end
    endfunction

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            crc       <= 8'h00;
            crc_ready <= 1'b0;
        end else begin
            crc_ready <= 1'b0;
            if (data_valid) begin
                crc       <= crc8_byte(data);
                crc_ready <= 1'b1;
            end
        end
    end
endmodule