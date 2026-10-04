/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement individual components to be used in 
    the CPU.

Student: Khoo Zi Yee
Student ID: 34598928
*/
module sign_extend(in, ext);
	/* 
	 * This module sign extends the 9-bit Din to a 16-bit output.
	 */
	input signed [8:0] in;
	output signed [15:0] ext;
	
	assign ext = {{7{in[8]}}, in};

endmodule

module tick_FSM(rst, clk, enable, tick);
	/* 
	 * This module implements a tick FSM that will be used to
	 * control the actions of the control unit
	 */

	// TODO: Declare inputs and outputs
	input rst, clk, enable;
	output [3:0]tick;
	
	reg [3:0]tick;
	
   // TODO: implement FSM
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			tick <= 4'b0001;
		end else begin
			if (enable) begin
				if (tick == 4'b0000)
					tick <= 4'b0001;
				else tick <= {tick[2:0], tick[3]};
			end
		end	
	end
endmodule

module multiplexer(SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G, sel, Bus);
	/* 
	 * This module takes 10 inputs and places the correct input onto the bus.
	 */
	// TODO: Declare inputs and outputs
	input signed [15:0]SignExtDin;
	input signed [15:0] R0, R1, R2, R3, R4, R5, R6, R7, G;
	input [3:0]sel;
	output reg signed [15:0] Bus;
	
	// TODO: implement logic
	always @(*) begin
		case (sel)
			4'b0000: Bus = SignExtDin;
			4'b0001: Bus = R0;
			4'b0010: Bus = R1;
			4'b0011: Bus = R2;
			4'b0100: Bus = R3;
			4'b0101: Bus = R4;
			4'b0110: Bus = R5;
			4'b0111: Bus = R6;
			4'b1000: Bus = R7;
			4'b1001: Bus = G;
			
			default: Bus = 16'b0;
		
		endcase
	end
endmodule

module ALU (input_a, input_b, alu_op, result);
	/* 
	 * This module implements the arithmetic logic unit of the processor.
	 */
	// TODO: declare inputs and outputs
	input signed [15:0] input_a;
   input signed [15:0] input_b;
   input [2:0] alu_op;
   output reg signed [15:0] result;
	
	reg [15:0] a_abs;
	
	// TODO: Implement ALU Logic
	always @(*) begin
		case(alu_op)
			3'b000:result = input_a * input_b;
			3'b001:result = input_a + input_b;
			3'b010:result = input_a - input_b;
			3'b011: begin
				if (input_a[15] == 1) begin
					a_abs = ~input_a + 16'd1; 		// get the absolute value of the immediate
					result = input_b >>> a_abs; 		// negative right shift
				end else begin
					result = input_b <<< input_a; 		// positive left shift
				end
				end
			default: result = 16'b0;
		endcase

	end

endmodule



module register_n(data_in, r_in, clk, Q, rst);

	// To set parameter N during instantiation, you can use:
	// register_n #(.N(num_bits)) reg_IR(.....), 
	// where num_bits is how many bits you want to set N to
	// and "..." is your usual input/output signals

	parameter N = 16;

	/* 
	 * This module implements registers that will be used in the processor.
	 */
	// TODO: Declare inputs, outputs, and parameter:
	input signed [(N-1):0] data_in;
	input r_in, clk, rst;
	output signed [(N-1):0] Q;
	
	reg signed [(N-1):0] Q;
	
	// TODO: Implement register logic:
	always @(posedge clk or posedge rst) begin
		if (rst) 
			Q <= {N{1'b0}};
		else if (r_in)
			Q <= data_in;
	end
endmodule