/*
Monash University ECE2072: Assignment
Task 4: Instruction Memory + PC wrapper for your proc_extension core

Student: Khoo Zi Yee
Student ID: 34598928
*/

module proc_memory (
    input         clk,         // slow 10 Hz clock is fine
    input         rst,         // active-high reset
    input         enable,      // SW[9] : run/pause
    output [15:0] bus,         // pass-through from core
    output [3:0]  tick,        // pass-through from core
    output [15:0] display,     // pass-through from core H register
    output [14:0] PC           // word-addressed program counter
);

    // === ROM (IP) ===
    wire [8:0]  rom_q;         // 9-bit ROM word
    reg  [14:0] rom_addr;      // address presented to ROM

    // Generate this IP in Quartus as "rom1", width=9, depth=32768, init with memory.mif
    rom1 instruction_memory (
        .address(rom_addr),
        .clock  (clk),
        .q      (rom_q)
    );

    // === Core (your proc_extension) ===
    wire [15:0] bus_w, display_w;
    wire [3:0]  tick_w;

    // expose regs so wrapper can evaluate BEZ
    wire signed [15:0] R0_w, R1_w, R2_w, R3_w, R4_w, R5_w, R6_w, R7_w;

    proc_extension u_core (
        .clk    (clk),
        .rst    (rst),
        .enable (enable),
        .din    (rom_q),
        .bus    (bus_w),
        .R0     (R0_w), .R1(R1_w), .R2(R2_w), .R3(R3_w),
        .R4     (R4_w), .R5(R5_w), .R6(R6_w), .R7(R7_w),
        .tick   (tick_w),
        .display(display_w)
    );

    assign bus     = bus_w;
    assign tick    = tick_w;
    assign display = display_w;

    // === OpCodes (match your core) ===
    localparam [2:0] OP_DISP = 3'b000,
                     OP_ADD  = 3'b001,
                     OP_ADDI = 3'b010,
                     OP_SUB  = 3'b011,
                     OP_MUL  = 3'b100,
                     OP_SSI  = 3'b101,
                     OP_BEZ  = 3'b110,   // Task 4 branch
                     OP_MOVI = 3'b111;

    // === PC and decode latches ===
    reg  [14:0] pc_reg;            // word address
    assign PC = pc_reg;

    // latch fields from the opcode word seen at tick1
    reg  [2:0] op_d1, rx_d1;

    // latch imm from tick2 (sign-extended)
    reg  signed [15:0] imm_d1;

    // select ROM address: tick1/3/4 -> PC, tick2 -> PC+1 (immediate)
    always @(*) begin
        if (tick_w == 4'b0010)
            rom_addr = pc_reg + 15'd1;    // fetch immediate word
        else
            rom_addr = pc_reg;            // fetch opcode word
    end

    // helper: read current Rx value from core
    function signed [15:0] reg_val;
        input [2:0] idx;
        begin
            case (idx)
                3'd0: reg_val = R0_w;
                3'd1: reg_val = R1_w;
                3'd2: reg_val = R2_w;
                3'd3: reg_val = R3_w;
                3'd4: reg_val = R4_w;
                3'd5: reg_val = R5_w;
                3'd6: reg_val = R6_w;
                3'd7: reg_val = R7_w;
                default: reg_val = 16'sd0;
            endcase
        end
    endfunction

    // Tick-based sequencing:
    // tick1: latch opcode and rx from opcode word (rom_q)
    // tick2: latch signed immediate from rom_q (the immediate word)
    // tick4: update PC
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_reg <= 15'd0;
            op_d1  <= 3'd0;
            rx_d1  <= 3'd0;
            imm_d1 <= 16'sd0;
        end else if (enable) begin
            case (tick_w)
                4'b0001: begin
                    op_d1 <= rom_q[8:6];
                    rx_d1 <= rom_q[5:3]+1;
						  pc_reg <= pc_reg + 15'd1;
                end
                4'b0010: begin
                    // sign-extend the 9-bit immediate
                    imm_d1 <= {{7{rom_q[8]}}, rom_q};   // 16-bit signed
                end
                4'b1000: begin
                    // default: advance to next instruction (2 words)
                    // BEZ: if Rx==0 then PC += 2 + (imm<<1), else PC += 2
                    if (op_d1 == OP_BEZ) begin
                        if (reg_val(rx_d1) == 16'sd0) begin
                            // imm is "number of instructions", so convert to words: (imm << 1)
                            // Add 2 to skip past this instruction pair, then add branch offset.
                            // Use signed arithmetic for backward branches too.
                            pc_reg <= (pc_reg + 15'd1) + $signed(imm_d1)*2;
                        end else begin
                            pc_reg <= pc_reg + 15'd1;
                        end
                    end else begin
                        pc_reg <= pc_reg + 15'd1;  // ALWAYS +2 for Task 4 ROM
                    end
                end
                default: ; // no PC change on tick3 etc.
            endcase
        end
    end

endmodule