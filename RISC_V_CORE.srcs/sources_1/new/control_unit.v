`timescale 1ns / 1ps

module control_unit(
    input  [6:0] Opcode,
    output reg   RegWrite, // 1 to write to register bank, 0 to skip
    output reg   ALUSrc,   // 0 for Reg Bank source, 1 for Immediate Generator source
    output reg   MemRead,  // 1 to read from RAM (Loads)
    output reg   MemWrite, // 1 to write to RAM (Stores)
    output reg   MemToReg, // 0 for ALU result to Reg, 1 for RAM data to Reg
    output reg   Branch,   // 1 for conditional branch instructions
    output reg [1:0] ALUop // 2-bit operation mode code passed to ALU control unit
);
    
    always @(*) begin
        case(Opcode)
            // 1. R-Type Arithmetic (add, sub, etc.)
            7'b0110011: begin
                RegWrite = 1;
                ALUSrc   = 0;
                MemRead  = 0;
                MemWrite = 0;
                MemToReg = 0;
                Branch   = 0;
                ALUop    = 2'b10; // Use funct3/funct7 bits
            end

            // 2. I-Type Arithmetic (addi, andi, etc.)
            7'b0010011: begin
                RegWrite = 1;
                ALUSrc   = 1;
                MemRead  = 0;
                MemWrite = 0;
                MemToReg = 0;
                Branch   = 0;
                ALUop    = 2'b10; // Use funct3 bits
            end

            // 3. Load Word (lw)
            7'b0000011: begin
                RegWrite = 1;
                ALUSrc   = 1;
                MemRead  = 1;
                MemWrite = 0;
                MemToReg = 1;
                Branch   = 0;
                ALUop    = 2'b00; // Force Address Addition
            end

            // Default safe-state for unhandled opcodes
            default: begin
                RegWrite = 0;
                ALUSrc   = 0;
                MemRead  = 0;
                MemWrite = 0;
                MemToReg = 0;
                Branch   = 0;
                ALUop    = 2'b00;
            end
        endcase
    end
endmodule