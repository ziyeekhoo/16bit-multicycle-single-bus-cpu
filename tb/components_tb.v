`timescale 1ns/1ps
/*
Monash University ECE2072: Assignment 
This file contains a Verilog test bench to test the correctness of the individual 
components used in the processor.

Student: Khoo Zi Yee
Student ID: 34598928
*/

module components_tb;
   parameter N = 16;

   // instantiate clock signals
   reg clk;
	initial clk = 0;
   always #5 clk = ~clk;

   // sign extend
   reg [8:0] in;
   wire [15:0] ext;
   sign_extend dut_sign_ext(.in(in), .ext(ext));

   // tick FSM
   reg rst_fsm, enable;
   wire [3:0] tick;
   tick_FSM dut_tick_FSM(.rst(rst_fsm), .clk(clk), .enable(enable), .tick(tick));

   // multiplexer
   reg [15:0] R0,R1,R2,R3,R4,R5,R6,R7,G;
   reg [3:0] sel;
   wire [15:0] Bus;
   multiplexer dut_mux(.SignExtDin(ext), .R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7), .G(G), .sel(sel), .Bus(Bus));

   // ALU
   reg signed [15:0] input_a,input_b;
   reg [2:0] alu_op;
   wire signed [15:0] result;
   ALU dut_alu(.input_a(input_a), .input_b(input_b), .alu_op(alu_op), .result(result));

   // register_n
   reg [(N-1):0] data_in;
   reg r_in, rst_reg;
   wire [(N-1):0] Q;
   register_n dut_reg_n(.data_in(data_in), .r_in(r_in), .clk(clk), .Q(Q), .rst(rst_reg));

   // initialize variables 
   integer count_ext, count_tick, count_mul, count_alu, count_reg;
   integer errors_ext, errors_tick, errors_mul, errors_alu, errors_reg;
   reg [15:0] expected_ext;
   reg [3:0] expected_tick;
   reg [3:0] held_tick;
   reg signed [31:0] expected_alu;

   // start testing
   initial begin
      count_ext = 0; errors_ext = 0;
      count_tick = 0; errors_tick = 0;
      count_mul = 0; errors_mul = 0;
      count_alu = 0; errors_alu = 0;
      count_reg = 0; errors_reg = 0;

      test_sign_extend();
      test_tick_FSM();
      test_multiplexer();
      test_ALU();
      test_register_n();

      $display("All tests done.");
      if (errors_ext==0)  $display("sign extender done. %0d tests run, and 0 errors.", count_ext);
      else                $display("sign extender done. %0d tests with %0d errors.", count_ext, errors_ext);

      if (errors_tick==0) $display("tick_FSM done. %0d checks run, 0 errors.", count_tick);
      else                $display("tick_FSM done. %0d checks with %0d errors.", count_tick, errors_tick);

      if (errors_mul==0)  $display("Multiplexer done, %0d tests run, 0 errors.", count_mul);
      else                $display("Multiplexer done, %0d tests with %0d errors.", count_mul, errors_mul);

      if (errors_alu==0)  $display("ALU done, %0d tests run, 0 errors.", count_alu);
      else                $display("ALU done, %0d tests with %0d errors.", count_alu, errors_alu);

      if (errors_reg==0)  $display("Shift register done, %0d checks run, 0 errors.", count_reg);
      else                $display("Shift register done, %0d checks with %0d errors.", count_reg, errors_reg);

      $stop;
   end

   // Sign extender
   task test_sign_extend;
   begin
      $display("Starting sign extender tests");
      in = 9'b000000000;
      repeat(512) begin
         #1; expected_ext = {{7{in[8]}}, in};
         if (ext !== expected_ext) begin
            $display("FAIL: in=%b expected=%0d got=%0d", in, expected_ext, ext);
            errors_ext = errors_ext + 1;
         end
         count_ext = count_ext + 1;
         in = in + 1;
      end
   end
   endtask

   // tick FSM
   task test_tick_FSM;
   begin
      $display(" Starting tick FSM tests");
      rst_fsm = 1; enable = 0;
      @(posedge clk); #1;
		
      if(tick!==4'b0001) begin
			errors_tick = errors_tick + 1;
		end else count_tick = count_tick + 1;
			
		rst_fsm=0; enable=1;
		expected_tick = {tick[2:0],tick[3]};
		
      repeat(8) begin
         @(posedge clk); #1;
         if(tick!==expected_tick) begin
				errors_tick=errors_tick+1;
			end else begin 
				count_tick = count_tick + 1;
			end
			expected_tick={tick[2:0],tick[3]};
      end
		
      enable=0; held_tick=tick;
      @(posedge clk); #1;
      if(tick!==held_tick) begin errors_tick = errors_tick + 1;
      end else count_tick = count_tick + 1;
		
      rst_fsm = 1; @(posedge clk); #1;
      if(tick!==4'b0001) begin errors_tick = errors_tick + 1;
      end else count_tick = count_tick + 1;
   end
   endtask

   // multiplexer tests
   task test_multiplexer;
   begin
      $display("Starting multiplexer tests");
      R0 = 16'd1; R1 = 16'd2; R2 = 16'd3; R3 = 16'd4;
      R4 = 16'd5; R5 = 16'd6; R6 = 16'd7; R7 = 16'd8; G = 16'd9;
      in = 16'b000001010;
      for(sel = 0; sel < 10; sel = sel+1) begin
         #5;
         case(sel)
           4'd0: if(Bus!==ext) errors_mul=errors_mul+1;
           4'd1: if(Bus!==R0) errors_mul=errors_mul+1;
           4'd2: if(Bus!==R1) errors_mul=errors_mul+1;
           4'd3: if(Bus!==R2) errors_mul=errors_mul+1;
           4'd4: if(Bus!==R3) errors_mul=errors_mul+1;
           4'd5: if(Bus!==R4) errors_mul=errors_mul+1;
           4'd6: if(Bus!==R5) errors_mul=errors_mul+1;
           4'd7: if(Bus!==R6) errors_mul=errors_mul+1;
           4'd8: if(Bus!==R7) errors_mul=errors_mul+1;
           4'd9: if(Bus!==G)  errors_mul=errors_mul+1;
         endcase
         count_mul = count_mul + 1;
      end
   end
   endtask

   // ALU test
   task test_ALU;
      integer manual_count, manual_errors;
      integer auto_count, auto_errors;
      integer i;
   begin
      manual_count=0; manual_errors=0;
      auto_count=0; auto_errors=0;

      // manually input values
      input_a = 16'd3; input_b = 16'd4; alu_op = 3'b000; #2; 		// multiply
      if (result !== 16'd12) manual_errors = manual_errors + 1;
      manual_count = manual_count + 1;

      input_a = 16'd10; input_b = 16'd5; alu_op = 3'b001; #2; 		// add
      if (result !== 16'd15) manual_errors = manual_errors + 1;
      manual_count = manual_count + 1;

      input_a = 16'd20; input_b = 16'd8; alu_op = 3'b010; #2;		// subtraction
      if (result !== 16'd12) manual_errors = manual_errors + 1;
      manual_count = manual_count + 1;

      input_a = 16'sd2; input_b = 16'sd8; alu_op = 3'b011; #2; 	// positive shift left
      if (result !== (input_b <<< input_a)) manual_errors = manual_errors + 1;
      manual_count = manual_count + 1;

      input_a = -16'sd3; input_b = 16'sd64; alu_op = 3'b011; #2;		// negative shift right
      if (result !== (input_b >>> $unsigned(-input_a))) manual_errors = manual_errors + 1;
      manual_count = manual_count + 1;

      $display("manual tests: success, %0d tests run, %0d errors.", manual_count, manual_errors);
      count_alu = count_alu + manual_count;
      errors_alu = errors_alu + manual_errors;

      // auto tests
      for(i=0;i<20;i=i+1) begin
         input_a = i; input_b = i*2; alu_op = 3'b001; #1;
         if (result !== input_a + input_b) auto_errors = auto_errors + 1;
         auto_count = auto_count + 1;
      end
      for(i=0;i<20;i=i+1) begin
         input_a = i*3; input_b = i; alu_op = 3'b010; #1;
         if (result !== input_a - input_b) auto_errors = auto_errors + 1;
         auto_count = auto_count + 1;
      end

      $display("auto tests: success, %0d tests run, %0d errors.", auto_count, auto_errors);
      count_alu = count_alu + auto_count;
      errors_alu = errors_alu + auto_errors;
   end
   endtask

   // Shift register
   task test_register_n;
   begin
      $display("Starting shift register tests");
      rst_reg = 1; @(posedge clk); rst_reg=0; 		// enable 1, reset 0, testing load
      data_in = 16'd14; r_in = 1; #2; @(posedge clk); #1;
      if(Q!==data_in) errors_reg = errors_reg + 1; count_reg = count_reg + 1;

      r_in = 0; rst_reg = 1; @(posedge clk); #1; 		// enable 0, reset 1, testing reset
      if(Q!==16'd0) errors_reg = errors_reg + 1; count_reg = count_reg + 1;

      rst_reg = 0; r_in = 0; data_in = 16'd5; @(posedge clk); #1; 		// enable 0, reset 0, testing hold
      if(Q===16'd5) errors_reg = errors_reg + 1; count_reg = count_reg + 1;
   end
   endtask

endmodule