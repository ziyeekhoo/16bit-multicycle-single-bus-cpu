`timescale 1ns/1ns
/*
Monash University ECE2072: Assignment 
This file contains a Verilog test bench to test the correctness of the processor.

Student ID: 35491256
*/

module proc_extension_tb;

    // declare regs and wires
    reg clk, rst;
    reg signed [8:0] din;
    wire signed [15:0] bus, R0, R1, R2, R3, R4, R5, R6, R7;
    wire [3:0] tick;
    wire enable = 1'b1;
    wire [15:0] display;
    reg  signed [15:0] expected_disp;

    // shadow copy of registers for scoreboard
    reg  signed [15:0] RX[0:7];

    proc_extension dut_proc(
        .clk(clk), .rst(rst), .din(din), .enable(enable),
        .bus(bus),
        .R0(R0), .R1(R1), .R2(R2), .R3(R3),
        .R4(R4), .R5(R5), .R6(R6), .R7(R7),
        .tick(tick), .display(display)
    );

    // generate clock signals
    initial clk = 0;
    always #5 clk = ~clk;

    // opcodes
    parameter [2:0] OP_ADD  = 3'b001,
                    OP_ADDI = 3'b010,
                    OP_SUB  = 3'b011,
                    OP_MOVI = 3'b111,
                    OP_MUL  = 3'b100,
                    OP_DISP = 3'b000,
                    OP_SSI  = 3'b101;

    integer total_tests, total_errors;
    integer pass_movi, pass_addi, pass_add, pass_sub, pass_mul, pass_disp, pass_ssi;
    integer fail_movi, fail_addi, fail_add, fail_sub, fail_mul, fail_disp, fail_ssi;

    reg [2:0] rx, ry;
    reg signed [8:0] prev;
    reg signed [8:0] imm;

    // -------- timing helper --------
    task wait_for_tick1;
    begin
        wait (tick === 4'b1000);
        @(posedge clk);
        #1 din = 9'b0;
    end
    endtask

    // -------- type RR instruction --------
    task issue_rr(input [2:0] op, input [2:0] rx_i, input [2:0] ry_i);
    begin
        wait (tick === 4'b0001);
        din = {op, rx_i, ry_i};
        repeat (4) @(posedge clk);
        #1 din = 9'b0;
    end
    endtask

    // -------- type RI instruction --------
    task issue_ri(input [2:0] op, input [2:0] rx_i, input signed [8:0] imm_i);
    begin
        wait (tick === 4'b0001);
        din = {op, rx_i, 3'b000};
        wait (tick === 4'b0010);
        din = imm_i;
        repeat (3) @(posedge clk);
        #1 din = 9'b0;
    end
    endtask

    // -------- wrappers --------
    task issue_movi(input [2:0] rx_i, input signed [8:0] imm_i);
    begin
        issue_ri(OP_MOVI, rx_i, imm_i);
    end
    endtask

    task issue_disp(input [2:0] rx_i);
    begin
        wait (tick === 4'b0001);
        din = {OP_DISP, rx_i, 3'b000};
        wait (tick === 4'b0010);
        repeat (3) @(posedge clk);
        #1 din = 9'b0;
    end
    endtask

    // ---------- SSI test helper ----------
    task ssi_check_fixed;
        input [2:0] rx_i;
        input signed [8:0] imm_i;
        reg signed [15:0] exp;
        integer sh;
    begin
        wait_for_tick1();
        if (imm_i >= 0) begin
            sh  = imm_i;
            exp = RX[rx_i] <<< sh;   // positive = left shift
        end else begin
            sh  = -imm_i;
            exp = RX[rx_i] >>> sh;   // negative = right shift
        end

        issue_ri(OP_SSI, rx_i, imm_i);

        RX[rx_i] = exp;
        if (reg_val(rx_i) !== RX[rx_i]) begin
            fail_ssi = fail_ssi + 1;
            $display("SSI FAIL: R%0d imm=%0d  exp=%0d  got=%0d",
                     rx_i, imm_i, exp, reg_val(rx_i));
        end else begin
            pass_ssi = pass_ssi + 1;
        end
    end
    endtask

    // ---------- main testing ----------
    initial begin
        total_tests = 0;
        total_errors = 0;
        pass_movi = 0; pass_addi = 0; pass_add = 0; pass_sub = 0; pass_mul = 0; pass_disp = 0; pass_ssi = 0;
        fail_movi = 0; fail_addi = 0; fail_add = 0; fail_sub = 0; fail_mul = 0; fail_disp = 0; fail_ssi = 0;

        rst = 1; din = 9'b0;
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk); #1;

        RX[0]=0; RX[1]=0; RX[2]=0; RX[3]=0;
        RX[4]=0; RX[5]=0; RX[6]=0; RX[7]=0;

        // ===================== MOVI =====================
        $display("Starting MOVI test");
        rx = 3'd0; imm = -9'sd256;
        repeat (8*128) begin
            wait_for_tick1(); issue_movi(rx, imm);
            RX[rx] = imm;
            if (reg_val(rx) !== RX[rx]) fail_movi = fail_movi + 1; else pass_movi = pass_movi + 1;
            prev = imm; imm = imm + 9'sd4;
            if (imm < prev) begin imm = -9'sd256; rx = rx + 3'd1; end
        end
        $display("MOVI: %0d passed, %0d fail", pass_movi, fail_movi);

        // ===================== ADDI =====================
        $display("Starting ADDI test");
        rx = 3'd0; imm = -9'sd256;
        wait_for_tick1(); issue_movi(3'd4, 9'sd0); RX[4] = 0;
        wait_for_tick1(); issue_movi(3'd5,-9'sd1); RX[5] = -1;
        wait_for_tick1(); issue_movi(3'd6, 9'sd1); RX[6] = 1;

        wait_for_tick1(); issue_ri(OP_ADDI, 3'd6, -9'sd6); RX[6] = RX[6] - 16'sd6;
        if (reg_val(3'd6) !== RX[6]) fail_addi = fail_addi + 1; else pass_addi = pass_addi + 1;
        wait_for_tick1(); issue_ri(OP_ADDI, 3'd4, 9'sd1); RX[4] = RX[4] + 16'sd1;
        if (reg_val(3'd4) !== RX[4]) fail_addi = fail_addi + 1; else pass_addi = pass_addi + 1;

        repeat (8*128) begin
            wait_for_tick1(); issue_ri(OP_ADDI, rx, imm);
            RX[rx] = RX[rx] + imm;
            if (reg_val(rx) !== RX[rx]) fail_addi = fail_addi + 1; else pass_addi = pass_addi + 1;
            prev = imm; imm = imm + 9'sd4;
            if (imm < prev) begin imm = -9'sd256; rx = rx + 3'd1; end
        end
        $display("ADDI: %0d passed, %0d fail", pass_addi, fail_addi);

        // ===================== ADD =====================
        $display("Starting ADD test");
        rx = 3'd0; ry = 3'd0;
        wait_for_tick1(); issue_movi(3'd4, 9'sd0); RX[4] = 0;
        wait_for_tick1(); issue_movi(3'd5,-9'sd1); RX[5] = -1;
        wait_for_tick1(); issue_movi(3'd6, 9'sd1); RX[6] = 1;

        wait_for_tick1(); issue_rr(OP_ADD, 3'd6, 3'd6); RX[6] = RX[6] + RX[6];
        if (reg_val(3'd6) !== RX[6]) fail_add = fail_add + 1; else pass_add = pass_add + 1;
        wait_for_tick1(); issue_rr(OP_ADD, 3'd4, 3'd5); RX[4] = RX[4] + RX[5];
        if (reg_val(3'd4) !== RX[4]) fail_add = fail_add + 1; else pass_add = pass_add + 1;

        repeat (64) begin
            wait_for_tick1(); issue_rr(OP_ADD, rx, ry);
            RX[rx] = RX[rx] + RX[ry];
            if (reg_val(rx) !== RX[rx]) fail_add = fail_add + 1; else pass_add = pass_add + 1;
            ry = ry + 3'd1; if (ry == 3'd0) rx = rx + 3'd1;
        end
        $display("ADD: %0d passed, %0d fail", pass_add, fail_add);

        // ===================== SUB =====================
        $display("Starting SUB test");
        rx = 3'd0; ry = 3'd0;
        wait_for_tick1(); issue_movi(3'd4, 9'sd0); RX[4] = 0;
        wait_for_tick1(); issue_movi(3'd5,-9'sd1); RX[5] = -1;
        wait_for_tick1(); issue_movi(3'd6, 9'sd1); RX[6] = 1;

        wait_for_tick1(); issue_rr(OP_SUB, 3'd6, 3'd6); RX[6] = RX[6] - RX[6];
        if (reg_val(3'd6) !== RX[6]) fail_sub = fail_sub + 1; else pass_sub = pass_sub + 1;
        wait_for_tick1(); issue_rr(OP_SUB, 3'd4, 3'd5); RX[4] = RX[4] - RX[5];
        if (reg_val(3'd4) !== RX[4]) fail_sub = fail_sub + 1; else pass_sub = pass_sub + 1;

        repeat (64) begin
            wait_for_tick1(); issue_rr(OP_SUB, rx, ry);
            RX[rx] = RX[rx] - RX[ry];
            if (reg_val(rx) !== RX[rx]) fail_sub = fail_sub + 1; else pass_sub = pass_sub + 1;
            ry = ry + 3'd1; if (ry == 3'd0) rx = rx + 3'd1;
        end
        $display("SUB: %0d passed, %0d fail", pass_sub, fail_sub);

        // ===================== MUL =====================
        $display("Starting MUL test");
        rx = 3'd0; ry = 3'd0;
        wait_for_tick1(); issue_movi(3'd4, 9'sd0); RX[4] = 0;
        wait_for_tick1(); issue_movi(3'd5,-9'sd5); RX[5] = -5;
        wait_for_tick1(); issue_movi(3'd6, 9'sd3); RX[6] = 3;

        wait_for_tick1(); issue_rr(OP_MUL, 3'd5, 3'd5); RX[5] = RX[5] * RX[5];
        if (reg_val(3'd5) !== RX[5]) fail_mul = fail_mul + 1; else pass_mul = pass_mul + 1;
        wait_for_tick1(); issue_rr(OP_MUL, 3'd6, 3'd4); RX[6] = 0;
        if (reg_val(3'd6) !== RX[6]) fail_mul = fail_mul + 1; else pass_mul = pass_mul + 1;

        repeat (64) begin
            wait_for_tick1(); issue_rr(OP_MUL, rx, ry);
            RX[rx] = RX[rx] * RX[ry];
            if (reg_val(rx) !== RX[rx]) fail_mul = fail_mul + 1; else pass_mul = pass_mul + 1;
            ry = ry + 3'd1; if (ry == 3'd0) rx = rx + 3'd1;
        end
        $display("MUL: %0d passed, %0d fail", pass_mul, fail_mul);

        // ===================== SSI (FIXED DIRECTION) =====================
        $display("Starting SSI tests");
        pass_ssi = 0; fail_ssi = 0;
        wait_for_tick1(); issue_movi(3'd0, 9'sd16); RX[0] = 16'sd16;
        wait_for_tick1(); issue_movi(3'd1,-9'sd8);  RX[1] = -16'sd8;
        wait_for_tick1(); issue_movi(3'd2, 9'sd3);  RX[2] = 16'sd3;
        wait_for_tick1(); issue_movi(3'd3,-9'sd1);  RX[3] = -16'sd1;
        wait_for_tick1(); issue_movi(3'd4, 9'sd0);  RX[4] = 16'sd0;
        wait_for_tick1(); issue_movi(3'd5, 9'sd1);  RX[5] = 16'sd1;

        ssi_check_fixed(3'd0,  9'sd0);
        ssi_check_fixed(3'd0,  9'sd2);
        ssi_check_fixed(3'd1, -9'sd3);
        ssi_check_fixed(3'd1,  9'sd1);
        ssi_check_fixed(3'd2,  9'sd1);
        ssi_check_fixed(3'd2, -9'sd1);
        ssi_check_fixed(3'd3, -9'sd4);
        ssi_check_fixed(3'd3,  9'sd3);
        ssi_check_fixed(3'd4, -9'sd8);
        ssi_check_fixed(3'd5,  9'sd4);
        ssi_check_fixed(3'd5, -9'sd15);
        ssi_check_fixed(3'd5,  9'sd15);
        $display("SSI: %0d tests run, %0d errors.", pass_ssi + fail_ssi, fail_ssi);

        // ===================== DISP =====================
        $display("Starting DISP tests");
        rx = 3'd0;
        repeat(8) begin
            wait_for_tick1(); issue_disp(rx);
            expected_disp = reg_val(rx);
            if (display !== expected_disp) fail_disp = fail_disp + 1; else pass_disp = pass_disp + 1;
            rx = rx + 3'd1;
        end
        $display("DISP: %0d tests run, %0d errors.", pass_disp + fail_disp, fail_disp);

        // ===================== Summary =====================
        total_tests  = pass_movi + pass_addi + pass_add + pass_sub + pass_mul + pass_disp + pass_ssi;
        total_errors = fail_movi + fail_addi + fail_add + fail_sub + fail_mul + fail_disp + fail_ssi;

        $display("========================================");
        $display("All tests complete.");
        $display("Total tests run: %0d", total_tests);
        $display("Total errors: %0d", total_errors);
        if (total_errors == 0)
            $display("✅ All tests passed successfully.");
        else
            $display("❌ %0d tests failed.", total_errors);
        $display("========================================");
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
