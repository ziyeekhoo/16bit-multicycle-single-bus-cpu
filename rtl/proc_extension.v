/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement individual the CPU.

Student: Khoo Zi Yee
Student ID: 34598928
*/
module proc_extension(clk, rst, din, enable, bus, R0, R1, R2, R3, R4, R5, R6, R7, tick, display);

    // Note: The skeleton you are provided with includes output ports to output the values of the internal registers R0 - R7, for the purpose of test benching. When instantiating the processor to program your DE10-lite, you can leave these ports unused.

    // TODO: Declare inputs and outputs:
	 input clk, rst, enable;
	 input [8:0] din; 	// instructions for the CU
	 output [15:0] bus, R0, R1, R2, R3, R4, R5, R6, R7;
	 output [3:0] tick;
	 output [15:0] display;


    // TODO: declare wires:
	 wire [8:0] ir_out; 	// 9 bit output from IR
	 wire [15:0] ir_extended; 	// Sign extended from sign ext
	 wire [15:0] bus_wires; 	// Bus from multiplexer
	 wire [15:0] a_out, g_out;
	 wire [15:0] alu_out;
	 wire [15:0] R0_out, R1_out, R2_out, R3_out, R4_out, R5_out, R6_out, R7_out; 		// outputs from registers R0 - R7
	 wire [15:0] display_value;
	 
	 wire [2:0] opcode = ir_out[8:6];
	 wire [2:0] rx = ir_out[5:3];
	 wire [2:0] ry = ir_out[2:0];
	 
	 wire [3:0] sel_rx = 4'b0001 + {1'b0, rx};
	 wire [3:0] sel_ry = 4'b0001 + {1'b0, ry};
	 
	 // enables
	 reg R0_in, R1_in, R2_in, R3_in, R4_in, R5_in, R6_in, R7_in;
	 reg ir_in, a_in, g_in, display_in;
	 reg [2:0] alu_op;
	 reg [3:0] bus_control; 	// Select inputs to show on bus
	 
	 wire R0_in_g = enable & R0_in;   // gated enable for all registers
	 wire R1_in_g = enable & R1_in;
	 wire R2_in_g = enable & R2_in;
	 wire R3_in_g = enable & R3_in;
	 wire R4_in_g = enable & R4_in;
	 wire R5_in_g = enable & R5_in;
	 wire R6_in_g = enable & R6_in;
	 wire R7_in_g = enable & R7_in;
	 wire ir_in_g = enable & ir_in;
	 wire a_in_g = enable & a_in;  
	 wire g_in_g = enable & g_in;
	 wire display_in_g = enable & display_in; // H/display write gated
	 
	 assign bus = bus_wires;
	 assign R0 = R0_out; assign R1 = R1_out; assign R2 = R2_out; assign R3 = R3_out;
	 assign R4 = R4_out; assign R5 = R5_out; assign R6 = R6_out; assign R7 = R7_out;
	 assign display = display_value;
	 
	 // selects for the instructions on mux
	 parameter [3:0] BUS_IMM = 4'b0000, BUS_R0 = 4'b0001, BUS_R1 = 4'b0010, BUS_R2 = 4'b0011,
                 BUS_R3 = 4'b0100, BUS_R4 = 4'b0101, BUS_R5 = 4'b0110, BUS_R6 = 4'b0111,
                 BUS_R7 = 4'b1000, BUS_G = 4'b1001;
	 
	 // opcodes
	 parameter [2:0] OP_ADD = 3'b001, OP_ADDI = 3'b010, OP_MOVI = 3'b111, OP_SUB = 3'b011, OP_DISP = 3'b000,
							OP_SSI = 3'b101, OP_MUL = 3'b100;
	 
    // TODO: instantiate registers:
    register_n #(.N(9))ir(.data_in(din), .r_in(ir_in_g), .clk(clk), .Q(ir_out), .rst(rst));
	 register_n A_reg(.data_in(bus_wires), .r_in(a_in_g), .clk(clk), .Q(a_out), .rst(rst));
	 register_n G_reg(.data_in(alu_out), .r_in(g_in_g), .clk(clk), .Q(g_out), .rst(rst));
	 register_n R0_reg(.data_in(bus_wires), .r_in(R0_in_g), .clk(clk), .Q(R0_out), .rst(rst));
	 register_n R1_reg(.data_in(bus_wires), .r_in(R1_in_g), .clk(clk), .Q(R1_out), .rst(rst));
	 register_n R2_reg(.data_in(bus_wires), .r_in(R2_in_g), .clk(clk), .Q(R2_out), .rst(rst));
	 register_n R3_reg(.data_in(bus_wires), .r_in(R3_in_g), .clk(clk), .Q(R3_out), .rst(rst));
	 register_n R4_reg(.data_in(bus_wires), .r_in(R4_in_g), .clk(clk), .Q(R4_out), .rst(rst));
	 register_n R5_reg(.data_in(bus_wires), .r_in(R5_in_g), .clk(clk), .Q(R5_out), .rst(rst));
	 register_n R6_reg(.data_in(bus_wires), .r_in(R6_in_g), .clk(clk), .Q(R6_out), .rst(rst));
	 register_n R7_reg(.data_in(bus_wires), .r_in(R7_in_g), .clk(clk), .Q(R7_out), .rst(rst));
	 register_n H_reg(.data_in(bus_wires), .r_in(display_in_g), .clk(clk), .Q(display_value), .rst(rst)); 		// new display port
	 
    
    // TODO: instantiate Multiplexer:
	 sign_extend inst_sign_ext(.in(din), .ext(ir_extended));
    multiplexer inst_mux(.SignExtDin(ir_extended), .R0(R0_out), .R1(R1_out), .R2(R2_out), .R3(R3_out), .R4(R4_out), .R5(R5_out), .R6(R6_out), .R7(R7_out), .G(g_out), .sel(bus_control), .Bus(bus_wires));
    
    // TODO: instantiate ALU:
    ALU inst_alu(.input_a(a_out), .input_b(bus_wires), .alu_op(alu_op), .result(alu_out));
    
    // TODO: instantiate tick counter:
    tick_FSM inst_tick_FSM(.rst(rst), .clk(clk), .enable(enable), .tick(tick));
    
    // TODO: define control unit:
    always @(*) begin
        // TODO: Turn off all control signals:
		  R0_in = 0; R1_in = 0; R2_in = 0; R3_in = 0; R4_in = 0;
		  R5_in = 0; R6_in = 0; R7_in = 0; 
		  ir_in = 0; a_in = 0; g_in = 0;
		  display_in = 0;
		  alu_op = 3'b001;
		  bus_control = 4'b0000;

        // TODO: Turn on specific control signals based on current tick:
        case (tick)
            4'b0001: 	// tick 1: read instructions
                begin
						 ir_in = 1'b1; 	// to read Din into ir
						 bus_control = BUS_IMM;
                end
            
            4'b0010: 	//tick 2: select
                begin
						 case(opcode)
								OP_ADD, OP_SUB, OP_MUL: begin
									bus_control = sel_rx; 	// select rx registers
									a_in = 1'b1; 		// load to A register
								end
								OP_ADDI, OP_SSI: begin
									bus_control = BUS_IMM;
									a_in = 1'b1;
								end
								OP_MOVI: begin
									bus_control = BUS_IMM;
									case(rx) 	// write Imm directly into Rx
										3'd0: R0_in = 1; 		// write the computed values to respective registers
										3'd1: R1_in = 1;
										3'd2: R2_in = 1;
										3'd3: R3_in = 1;
										3'd4: R4_in = 1;
										3'd5: R5_in = 1;
										3'd6: R6_in = 1;
										3'd7: R7_in = 1;
									endcase
								end
								OP_DISP: begin
									bus_control = sel_rx;
									display_in = 1'b1;
								end
						 endcase
					 end
            
            4'b0100: 	// tick 3: execute
                begin
                    case(opcode)
								OP_ADD: 
									begin
										alu_op = 3'b001;
										bus_control = sel_ry; 	// input b for ALU
										g_in = 1'b1; 	// execute rx + ry
									end
								OP_ADDI:
									begin
										alu_op = 3'b001;
										bus_control = sel_rx; 		// get rx
										g_in = 1'b1;
									end
								OP_MOVI: ; 		// idle
								OP_DISP: ;
								OP_SUB: 
									begin
										alu_op = 3'b010;
										bus_control = sel_ry;
										g_in = 1'b1;
									end
								OP_MUL: 
									begin
										alu_op = 3'b000;
										bus_control = sel_ry; 	// input b for ALU
										g_in = 1'b1; 	// execute rx * ry
									end
								OP_SSI:
									begin
										alu_op = 3'b011;   // SIGNED SHIFT immediate
										bus_control = sel_rx;
										g_in = 1'b1;
									end
								default: begin
									  g_in = 1'b0; // Ensure G is not written
									  end
							endcase
                end
            
            4'b1000: 	// tick 4: read back to bus
                begin
						  case (opcode)
						  OP_ADD, OP_ADDI, OP_SUB, OP_MUL, OP_SSI: 
						  begin
						  bus_control = BUS_G; 		// read data from G register back to main bus
							  case(rx)
										3'd0: R0_in = 1; 		// write the computed values to respective registers
										3'd1: R1_in = 1;
										3'd2: R2_in = 1;
										3'd3: R3_in = 1;
										3'd4: R4_in = 1;
										3'd5: R5_in = 1;
										3'd6: R6_in = 1;
										3'd7: R7_in = 1;
							  endcase
						  end
						  OP_MOVI: ;
						  OP_DISP: ;
						  endcase
                end
            default: ;
        endcase

    end

endmodule