`timescale 1ns / 1ps

module riscv_tb_large;

    // =========================================================================
    // 1. GLOBAL TESTBENCH SIGNALS
    // =========================================================================
    reg clk;
    reg rst;
    integer cycle_count;

    // =========================================================================
    // 2. UNIT UNDER TEST (UUT) INSTANTIATION
    // =========================================================================
    riscv_top #(
        .DATA_WIDTH(32)
    ) uut (
        .clk(clk),
        .rst(rst)
    );

    // =========================================================================
    // 3. 100MHz CLOCK GENERATION SYSTEM
    // =========================================================================
    always begin
        #5 clk = ~clk;
    end

    // =========================================================================
    // 4. MAIN STIMULUS CONTROLLER
    // =========================================================================
    initial begin
        // Console Greeting Panel
        $display("==============================================================");
        $display("    LAUNCHING CORE VERIFICATION HARNESS (30 INSTRUCTIONS)     ");
        $display("==============================================================");
        
        // System Cold Start
        clk = 0;
        rst = 1;
        cycle_count = 0;
        
        // Hold reset for 2 full clock cycles (20ns) to initialize register arrays
        #20;
        
        // Release reset to launch execution loop
        @(posedge clk);
        #1 rst = 0;
        $display("[SYS_STATUS] Hardware reset de-asserted. Core execution tracking live.\n");
        $display(" CYCLE |    PC    | INSTRUCTION | ALUSrc | RegWrite | MemWrite | ALU_OUT ");
        $display("-------+----------+-------------+--------+----------+----------+----------");

        // Run simulation for 320ns (32 clock cycles total to cover all 30 instructions)
        #320;

        // Terminal Readout: Peak inside specific structural registers to confirm math accuracy
        $display("-------+----------+-------------+--------+----------+----------+----------");
        $display("\n==============================================================");
        $display("                FINAL REGISTER FILE STATE CHECK               ");
        $display("==============================================================");
        $display(" Register x1  (Expected: 5)   -> Hex: 32'h%h | Dec: %d", uut.Register_Bank.registers[1], uut.Register_Bank.registers[1]);
        $display(" Register x2  (Expected: 15)  -> Hex: 32'h%h | Dec: %d", uut.Register_Bank.registers[2], uut.Register_Bank.registers[2]);
        $display(" Register x3  (Expected: -15) -> Hex: 32'h%h | Dec: %d", uut.Register_Bank.registers[3], uut.Register_Bank.registers[3]);
        $display(" Register x4  (Expected: 5)   -> Hex: 32'h%h | Dec: %d", uut.Register_Bank.registers[4], uut.Register_Bank.registers[4]);
        $display(" Register x5  (Expected: 15)  -> Hex: 32'h%h | Dec: %d", uut.Register_Bank.registers[5], uut.Register_Bank.registers[5]);
        $display(" Register x6  (Expected: 10)  -> Hex: 32'h%h | Dec: %d", uut.Register_Bank.registers[6], uut.Register_Bank.registers[6]);
        $display("==============================================================");
        
        $finish;
    end

    // =========================================================================
    // 5. REAL-TIME HARDWARE MONITORING TRACKER
    // =========================================================================
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count = cycle_count + 1;
            
            // Print out internal module data values across the structural paths
            $display("  %2d   | 0x%h |  0x%h   |   %b    |    %b     |    %b     | 0x%h", 
                cycle_count,
                uut.pc_out, 
                uut.instruction, 
                uut.alu_src, 
                uut.reg_write, 
                uut.mem_write, 
                uut.alu_out
            );
        end
    end

endmodule