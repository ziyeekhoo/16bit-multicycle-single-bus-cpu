/*
Monash University ECE2072: Assignment
Task 4: DE10-Lite top-level using proc_memory wrapper

Student: Khoo Zi Yee
Student ID: 34598928
*/

module proc_extension_task4_top_level(
    input         CLOCK_50,
    input  [9:0]  SW,         // SW[9] = enable
    input  [1:0]  KEY,        // ~KEY[0] = reset
    output [9:0]  LEDR,       // lower 10 bits of bus
    output [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, // display value
    output [6:0]  HEX5        // tick
);

    // -------- Reset / Enable --------
    wire rst    = ~KEY[0];
    wire enable = SW[9];
    assign LEDR[9] = enable;
	 assign clk = ~KEY[1];

    // -------- Slow clock (≈10 Hz) for the CPU --------
    reg [22:0] counter = 23'd0;
    reg        CLOCK_10 = 1'b0;
    localparam integer TARGET = 2_500_000 - 1; // 50 MHz / (2*2.5M) = 10 Hz

    always @(posedge CLOCK_50 or posedge rst) begin
        if (rst) begin
            counter  <= 23'd0;
            CLOCK_10 <= 1'b0;
        end else if (counter == TARGET) begin
            counter  <= 23'd0;
            CLOCK_10 <= ~CLOCK_10;
        end else begin
            counter  <= counter + 1'd1;
        end
    end

    // -------- Wrap: PC + ROM + your core --------
    wire [15:0] bus;
    wire [3:0]  tick;
    wire [15:0] display;
    wire [14:0] PC;

    proc_memory U_MEM (
        .clk    (clk),
        .rst    (rst),
        .enable (enable),
        .bus    (bus),
        .tick   (tick),
        .display(),
        .PC     (display)
    );

    // -------- LEDs show bus[9:0] --------
    assign LEDR[8:0] = bus[8:0];

    // -------- Tick on HEX5 --------
    reg [6:0] tick_display;
    always @(*) begin
        case (tick)
            4'b0001: tick_display = 7'b1111001; // 1
            4'b0010: tick_display = 7'b0100100; // 2
            4'b0100: tick_display = 7'b0110000; // 3
            4'b1000: tick_display = 7'b0011001; // 4
            default: tick_display = 7'b1111111; // blank
        endcase
    end
    assign HEX5 = tick_display;

    // -------- Display value (unsigned decimal) on HEX4..HEX0 --------
    wire [3:0] ones, tens, hundreds, thousands, tenthousands;
    wire [6:0] s0, s1, s2, s3, s4;

    assign ones         =  display % 10;
    assign tens         = (display / 10) % 10;
    assign hundreds     = (display / 100) % 10;
    assign thousands    = (display / 1000) % 10;
    assign tenthousands = (display / 10000) % 10;

    segment_display_pos u0(.bcd(ones),         .seg(s0));
    segment_display_pos u1(.bcd(tens),         .seg(s1));
    segment_display_pos u2(.bcd(hundreds),     .seg(s2));
    segment_display_pos u3(.bcd(thousands),    .seg(s3));
    segment_display_pos u4(.bcd(tenthousands), .seg(s4));

    assign HEX0 = s0;
    assign HEX1 = s1;
    assign HEX2 = s2;
    assign HEX3 = s3;
    assign HEX4 = s4;

endmodule


// Simple 7-seg (positive) decoder: 0–9, blank otherwise
module segment_display_pos(
    input  [3:0] bcd,
    output reg [6:0] seg
);
    always @(*) begin
        case (bcd)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111; // blank
        endcase
    end
endmodule