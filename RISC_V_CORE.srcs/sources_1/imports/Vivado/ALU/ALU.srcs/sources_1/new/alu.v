`timescale 1ns / 1ps

module alu #(
    parameter DATA_WIDTH = 32
 )(
    input [DATA_WIDTH-1:0]       A,B, //INPUTS TO ALU WHICH ARE PARAMWTERIZED
    input [2:0]                  alu_sel, //selects ehich operation to perform
    output reg [DATA_WIDTH-1:0]  ALU_OUT,  //output of alu
    output                       ZERO    // zero flag high if output of alu is zero
    );
    
    assign ZERO = (ALU_OUT == {DATA_WIDTH{1'b0}});
    always@(*) begin   
        case(alu_sel)
            3'b000: ALU_OUT = A + B;        // Addition
            3'b001: ALU_OUT = A - B;        // Subtraction
            3'b010: ALU_OUT = A & B;        // Bitwise AND
            3'b011: ALU_OUT = A | B;        // Bitwise OR
            3'b100: ALU_OUT = A ^ B;        // Bitwise XOR
            3'b101: ALU_OUT = A << 1;       // Logical Left Shift (by 1)
            3'b110: ALU_OUT = A >> 1;       // Logical Right Shift (by 1)
            3'b111: ALU_OUT = (A < B) ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : {DATA_WIDTH{1'b0}}; // Set Less Than (SLT)
            default: ALU_OUT = {DATA_WIDTH{1'b0}}; // Default case avoids hardware latches
        endcase
    end

endmodule
