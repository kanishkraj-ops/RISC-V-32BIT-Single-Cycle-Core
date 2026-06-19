`timescale 1ns / 1ps

module imm_gen (
    input      [31:0] instr,    // 32-bit instruction fetched from memory
    output reg [31:0] imm_ext   // Fully sign-extended 32-bit immediate output
);

    always @(*) begin
        case(instr[6:0]) // Read the fixed 7-bit opcode
            
            // =================================================================
            // 1. I-Type Instructions (Arithmetic Immediates & Loads)
            // Examples: addi, andi, lw, jalr
            // =================================================================
            7'b0010011, 
            7'b0000011, 
            7'b1100111: begin
                imm_ext = {{20{instr[31]}}, instr[31:20]};
            end
            
            // =================================================================
            // 2. S-Type Instructions (Stores)
            // Examples: sw, sb, sh
            // The immediate is split between the lower and upper halves of the instruction.
            // =================================================================
            7'b0100110: begin
                imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
            
            // =================================================================
            // 3. B-Type Instructions (Conditional Branches)
            // Examples: beq, bne, blt, bge
            // Note: Bit 0 is always implicitly 0 because branches are half-word aligned!
            // =================================================================
            7'b1100110: begin
                imm_ext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            end

            // =================================================================
            // 4. J-Type Instructions (Unconditional Long Jump)
            // Example: jal
            // Note: Scrambled layout maximizes shared wiring with other formats.
            // =================================================================
            7'b1101111: begin
                imm_ext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            end
            
            // =================================================================
            // 5. R-Type Instructions (Register-to-Register Operations)
            // Examples: add, sub, and, or
            // R-type operations use ONLY registers, so their immediate output is 0.
            // =================================================================
            7'b0110011: begin
                imm_ext = 32'h00000000;
            end

            // Default safe-guard clear
            default: begin
                imm_ext = 32'h00000000;
            end
        endcase
    end

endmodule