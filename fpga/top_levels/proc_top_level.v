/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement the individual CPU.

Student: Khoo Zi Yee
Student ID: 34598928
*/

module proc_top_level (CLOCK_50, SW, KEY, LEDR, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

	input CLOCK_50;
	input [8:0] SW;
	input [1:0] KEY;
	output [9:0] LEDR;
	output [7:0] HEX0;
	output [7:0] HEX1;
	output [7:0] HEX2;
	output [7:0] HEX3;
	output [7:0] HEX4;
	output [6:0] HEX5;
	
	wire [15:0] bus;
   wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7;
	wire [3:0] tick;
	wire [15:0] display_value;
	
	reg [3:0] tick_no; 	// changes one-hot coding to show ticks 1 to 4
	
	always @* begin
		case (tick)
			4'b0001: tick_no = 4'd1;
			4'b0010: tick_no = 4'd2;
			4'b0100: tick_no = 4'd3;
			4'b1000: tick_no = 4'd4;
			default: tick_no = 4'd0;   
		endcase
	end
	
	proc_extension inst_proc(.clk(~KEY[1]), .rst(~KEY[0]), .din(SW[8:0]), .bus(bus), .R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7), .tick(tick), .display(display_value));
	bcd inst_bcd(.data(tick_no), .X(HEX5));
	five_digit_bcd five_digit(display_value, HEX0[6:0], HEX1[6:0], HEX2[6:0], HEX3[6:0], HEX4[6:0]);
	
	wire msb = display_value[15];          // if sign bit is 1, it indicates it is negative
   
   assign HEX0[7] = ~msb;
   assign HEX1[7] = ~msb;
   assign HEX2[7] = ~msb;
   assign HEX3[7] = ~msb;
   assign HEX4[7] = ~msb;
	

   assign LEDR[9:0] = bus[9:0];
endmodule