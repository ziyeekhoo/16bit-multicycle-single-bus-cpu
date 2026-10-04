/*
Monash University ECE2072
BCD to 7-Segment Decoder
Author: Khoo Zi Yee (34598928)
*/

module bcd (
    input [3:0] data,
    output reg [6:0] X
);
    // Common anode: segment ON = 0, OFF = 1
    always @(*) begin
        case (data)
            4'd0: X = 7'b1000000; // 0
            4'd1: X = 7'b1111001; // 1
            4'd2: X = 7'b0100100; // 2
            4'd3: X = 7'b0110000; // 3
            4'd4: X = 7'b0011001; // 4
            4'd5: X = 7'b0010010; // 5
            4'd6: X = 7'b0000010; // 6
            4'd7: X = 7'b1111000; // 7
            4'd8: X = 7'b0000000; // 8
            4'd9: X = 7'b0010000; // 9
            default: X = 7'b1111111; // blank/off
        endcase
    end
endmodule
