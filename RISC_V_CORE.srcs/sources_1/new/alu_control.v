`timescale 1ns / 1ps

module alu_control(
    input [1:0] ALUop,
    input func7,
    input [2:0] func3,
    output reg [2:0] ALU_sel
    );
    
    always @(*) begin
        case(ALUop)
            2'b00 : ALU_sel = 3'b000; //LOAD OR STORE
            2'b01 : ALU_sel = 3'b001;
            2'b10 : begin   
                        case(func3)
                            3'b000 : begin
                                ALU_sel = func7 ? 3'b001:3'b000;
                             end
                             3'b111: ALU_sel = 3'b010; // Bitwise AND
                    3'b110: ALU_sel = 3'b011; // Bitwise OR
                    
                    default: ALU_sel = 3'b000; // Safe fallback
                endcase
            end
           default: begin
                ALU_sel = 3'b000;
            end
        endcase
    end
                             
endmodule
