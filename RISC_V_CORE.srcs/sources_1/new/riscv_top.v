`timescale 1ns / 1ps

module riscv_top #(
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst
);

    // =========================================================================
    // 1. INTERNAL WIRE DECLARATIONS (The Global Wiring Harness)
    // =========================================================================
    wire [DATA_WIDTH-1:0] pc_out;
    wire [DATA_WIDTH-1:0] next_pc;
    wire [31:0]           instruction;
    
    // Control Unit Signals
    wire       reg_write;
    wire       alu_src;
    wire       mem_read;
    wire       mem_write;
    wire       mem_to_reg;
    wire       branch;
    wire [1:0] alu_op;
    wire [2:0] alu_sel;
    
    // Data Paths
    wire [DATA_WIDTH-1:0] rd_data1;
    wire [DATA_WIDTH-1:0] rd_data2;
    wire [DATA_WIDTH-1:0] imm_ext;
    wire [DATA_WIDTH-1:0] alu_operand_b;
    wire [DATA_WIDTH-1:0] alu_out;
    wire                  zero_flag;
    wire [DATA_WIDTH-1:0] ram_read_data;
    wire [DATA_WIDTH-1:0] wb_data;

    // Static Single-Cycle PC Calculation Loop
    assign next_pc = pc_out + 4;

    // =========================================================================
    // 2. MODULE INSTANTIATIONS & STRUCTURAL INTERCONNECTIONS
    // =========================================================================

    // --- PROGRAM COUNTER ---
    prog_counter PC_Unit (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc(pc_out)
    );

    // --- INSTRUCTION MEMORY (ROM) ---
    instruction_mem IMEM_Unit (
        .ADDRESS(pc_out),
        .INSTR(instruction)
    );

    // --- MAIN CONTROL UNIT (The Brain) ---
    control_unit Control_Unit (
        .Opcode(instruction[6:0]),
        .RegWrite(reg_write),
        .ALUSrc(alu_src),
        .MemRead(mem_read),
        .MemWrite(mem_write),
        .MemToReg(mem_to_reg),
        .Branch(branch),
        .ALUop(alu_op)
    );

    // --- REGISTER BANK (Configured with standard 5-bit address width) ---
    reg_bank #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(5)  // Forces 2^5 = 32 structural RISC-V registers
    ) Register_Bank (
        .clk(clk),
        .rst(rst),
        .sr1(instruction[19:15]), // rs1 field
        .sr2(instruction[24:20]), // rs2 field
        .dr(instruction[11:7]),   // rd field
        .write(reg_write),
        .wr_data(wb_data),         // Fed from final Writeback MUX
        .rd_data1(rd_data1),
        .rd_data2(rd_data2)
    );

    // --- IMMEDIATE GENERATOR ---
    imm_gen Imm_Gen_Unit (
        .instr(instruction),
        .imm_ext(imm_ext)
    );

    // --- ALU OPERAND B MULTIPLEXER ---
    assign alu_operand_b = (alu_src) ? imm_ext : rd_data2;

    // --- ALU CONTROL UNIT ---
    alu_control ALU_Control_Decoder (
        .ALUop(alu_op),
        .func3(instruction[14:12]),
        .func7(instruction[30]),
        .ALU_sel(alu_sel)
    );

    // --- ARITHMETIC LOGIC UNIT (ALU) ---
    alu #(
        .DATA_WIDTH(32)
    ) Central_ALU (
        .A(rd_data1),
        .B(alu_operand_b),
        .alu_sel(alu_sel),
        .ALU_OUT(alu_out),
        .ZERO(zero_flag)
    );

    // --- DATA MEMORY (RAM) ---
    data_mem #(
        .DATA_WIDTH(32)
    ) DM_Unit (
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .address(alu_out),
        .write_data(rd_data2),
        .read_data(ram_read_data)
    );

    // --- FINAL WRITEBACK MULTIPLEXER ---
    assign wb_data = (mem_to_reg) ? ram_read_data : alu_out;

endmodule