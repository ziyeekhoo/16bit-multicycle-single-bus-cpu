`timescale 1ns/1ns
/*
Monash University ECE2072: Assignment 
This file contains a Verilog test bench to test the correctness of the processor.

Student: Khoo Zi Yee
Student ID: 34598928
*/

module proc_tb;

    // declare regs and wires
    reg clk, rst;
    reg signed [8:0] din;
    wire signed [15:0] bus, R0, R1, R2, R3, R4, R5, R6, R7;
    wire [3:0] tick;
	 reg signed [15:0] RX[0:7]; 		// keep track of the values in register
	 
	 simple_proc dut_proc(.clk(clk), .rst(rst), .din(din), .bus(bus), .R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7), .tick(tick));

    // generate clock signals
    initial clk = 0;
    always #5 clk = ~clk;

    // initialize variables
    parameter [2:0] OP_ADD  = 3'b001, OP_ADDI = 3'b010, OP_SUB  = 3'b011, OP_MOVI = 3'b111;

    integer total_tests, total_errors;
    integer pass_movi, pass_addi, pass_add, pass_sub;
    integer fail_movi, fail_addi, fail_add, fail_sub;
	 reg [2:0] rx, ry;
	 reg signed [8:0]imm;    // -256 .. +255
	 reg signed [8:0] prev;
	 
    // timing task
    task wait_for_tick1;
    begin
        wait (tick === 4'b1000);
        @(posedge clk);
        #1;
        din = 9'b0;
    end
    endtask

	 // task for type 1 instructions (rx, ry)
    task issue_rr(input [2:0] op, input [2:0] rx, input [2:0] ry);
    begin
        wait (tick === 4'b0001);
		     din = {op, rx, ry};
        repeat (4) @(posedge clk);
           #1 din = 9'b0;
    end
    endtask
	 
	 // task for type 2 instructions (immediate)
    task issue_ri(input [2:0] op, input [2:0] rx, input signed [8:0] imm);
    begin
        wait (tick === 4'b0001);
           din = {op, rx, 3'b000}; 		// tick 1, give instruction
        wait (tick === 4'b0010);
           din = imm; 		// tick 2, put immediate
        repeat (3) @(posedge clk); 		// wait for tick 3 and 4
        #1 din = 9'b0;
    end
    endtask

    task issue_movi(input [2:0] rx, input signed [8:0] imm);
    begin
        wait (tick === 4'b0001);
        din = {OP_MOVI, rx, 3'b000};
        wait (tick === 4'b0010);
        din = imm;
        repeat (3) @(posedge clk);
        #1 din = 9'b0;
    end
    endtask


    
	 // start testing
    initial begin
		total_tests = 0;
		total_errors = 0;
		pass_movi = 0; pass_addi = 0; pass_add = 0; pass_sub = 0;
		fail_movi = 0; fail_addi = 0; fail_add = 0; fail_sub = 0;
		
		// reset whole processor
      rst = 1; din = 9'b0;
      repeat (3) @(posedge clk);
      rst = 0;
      @(posedge clk); #1;
		  
		// everything starts with 0
      RX[0]=0; RX[1]=0; RX[2]=0; RX[3]=0;
      RX[4]=0; RX[5]=0; RX[6]=0; RX[7]=0;
		
		// MOVI test
		$display("Starting MOVI test");
			
		rx = 3'd0;
		imm = -9'sd256;
		
		// +4 every step up
		repeat (8*128) begin
			wait_for_tick1();
			issue_movi(rx, imm);
			RX[rx] = imm;
			
			if (reg_val(rx) !== RX[rx]) begin
				fail_movi = fail_movi + 1;
            $display("FAILED: MOVI R%0d expected %0d, got %0d", rx, RX[rx], reg_val(rx));
			end else pass_movi = pass_movi + 1;

			// check if surpass 255
			prev = imm;
			imm  = imm + 9'sd4;
			if (imm < prev) begin       // +252 to -256
				imm = -9'sd256;
				rx = rx + 3'd1;
			end
		end
		$display("MOVI: %0d passed, %0d fail", pass_movi, fail_movi);
		
		
		// ADDI test
		$display("Starting ADDI test");
		rx = 3'd0;
		imm = -9'sd256;
		
		// test edge cases separately
		wait_for_tick1(); issue_movi(3'd4, 9'sd0); RX[4] = 0;
		wait_for_tick1(); issue_movi(3'd5, -9'sd1); RX[5] = -1;
		wait_for_tick1(); issue_movi(3'd6, 9'sd1); RX[6] = 1;
		
		// add negative imm
		wait_for_tick1(); 
		issue_ri(OP_ADDI, 3'd6, -9'sd6); 
		RX[6] = RX[6] - 16'sd6;
		if (reg_val(3'd6) !== RX[6]) 
			fail_addi = fail_addi + 1; 
		else pass_addi = pass_addi + 1;
		
		// 0 + Rx
		wait_for_tick1(); 
		issue_ri(OP_ADDI, 3'd4, 9'sd1);
		RX[4] = RX[4] + 16'sd1;
		if (reg_val(3'd4) !== RX[4]) 
			fail_addi = fail_addi + 1; 
		else pass_addi = pass_addi + 1;
		
		// check if surpass 255
		repeat (8*128) begin
			wait_for_tick1();
			issue_ri(OP_ADDI, rx, imm);
			RX[rx] = RX[rx] + imm;
			
			if (reg_val(rx) !== RX[rx]) begin
				fail_addi = fail_addi + 1;
			end else pass_addi = pass_addi + 1;

			// check if surpass 255
			prev = imm;
			imm  = imm + 9'sd4;
			if (imm < prev) begin       // +252 to -256
				imm = -9'sd256;
				rx = rx + 3'd1;
			end
		end	
		$display("ADDI: %0d passed, %0d fail", pass_addi, fail_addi);
		
		// ADD tests
		$display("Starting ADD test");
		rx = 3'd0; ry = 3'd0;
		
		// test edge cases separately
		wait_for_tick1(); issue_movi(3'd4, 9'sd0); RX[4] = 0;
		wait_for_tick1(); issue_movi(3'd5,-9'sd1); RX[5] = -1;
		wait_for_tick1(); issue_movi(3'd6, 9'sd1); RX[6] = 1;
		
		// Rx + Rx
		wait_for_tick1(); 
		issue_rr(OP_ADD, 3'd6, 3'd6); 
		RX[6] = RX[6] + RX[6];
		if (reg_val(3'd6) !== RX[6]) 
			fail_add = fail_add + 1; 
		else pass_add = pass_add + 1;
		
		// 0 + Rx
		wait_for_tick1(); 
		issue_rr(OP_ADD, 3'd4, 3'd5);
		RX[4] = RX[4] + RX[5];
		if (reg_val(3'd4) !== RX[4]) 
			fail_add = fail_add + 1; 
		else pass_add = pass_add + 1;

		repeat (64) begin
			wait_for_tick1();
			issue_rr(OP_ADD, rx, ry);
			RX[rx] = RX[rx] + RX[ry];
			
			if (reg_val(rx) !== RX[rx]) begin
				fail_add = fail_add + 1;
			end else pass_add = pass_add + 1;
			
			ry = ry + 3'd1;
			if (ry == 3'd0) rx = rx + 3'd1;
		end

		$display("ADD: %0d passed, %0d fail", pass_add, fail_add);
		
		// SUB test
		$display("Starting SUB test");
		
		rx = 3'd0; ry = 3'd0;
		
		// test edge cases separately
		wait_for_tick1(); issue_movi(3'd4, 9'sd0); RX[4] = 0;
		wait_for_tick1(); issue_movi(3'd5,-9'sd1); RX[5] = -1;
		wait_for_tick1(); issue_movi(3'd6, 9'sd1); RX[6] = 1;
		
		// Rx - Rx
		wait_for_tick1(); 
		issue_rr(OP_SUB, 3'd6, 3'd6); 
		RX[6] = RX[6] - RX[6];
		if (reg_val(3'd6) !== RX[6]) 
			fail_sub = fail_sub + 1;
		else pass_sub = pass_sub + 1;
		
		// subtract negatives
		wait_for_tick1();
		issue_rr(OP_SUB, 3'd4, 3'd5);
		RX[4] = RX[4] - RX[5];
		if (reg_val(3'd4) !== RX[4])
			fail_sub = fail_sub + 1;
		else pass_sub = pass_sub + 1;
		
		repeat (64) begin
			wait_for_tick1();
			issue_rr(OP_SUB, rx, ry);
			RX[rx] = RX[rx] - RX[ry];
			
			if (reg_val(rx) !== RX[rx]) begin
				fail_sub = fail_sub + 1;
			end else pass_sub = pass_sub + 1;
			
			ry = ry + 3'd1;
			if (ry == 3'd0) rx = rx + 3'd1;
		end
		
		$display("SUB: %0d passed, %0d fail", pass_sub, fail_sub);
		
		total_tests = pass_movi + pass_addi + pass_add + pass_sub;
		total_errors = fail_movi + fail_addi + fail_add + fail_sub;
		
		$display("All tests complete.");
		$display("Total tests run: %0d", total_tests);
		$display("Total errors: %0d", total_errors);
		if (total_errors == 0)
			$display("All tests passed successfully.");
		else
			$display("%0d tests failed.", total_errors);
			$stop;
	end
	

	 
    // function to read registers by index
    function signed [15:0] reg_val;
        input [2:0] idx;
        begin
            case (idx)
                3'd0: reg_val = R0;
                3'd1: reg_val = R1;
                3'd2: reg_val = R2;
                3'd3: reg_val = R3;
                3'd4: reg_val = R4;
                3'd5: reg_val = R5;
                3'd6: reg_val = R6;
                3'd7: reg_val = R7;
                default: reg_val = 16'sd0;
            endcase
        end
    endfunction

endmodule