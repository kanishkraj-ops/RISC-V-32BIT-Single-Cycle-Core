`timescale 1ns / 1ps
//Program counter is basically a reg that always points to addr of next instruction

module prog_counter(
    input       clk, // CLOCK
    input       rst, //RESET
    input [31:0] next_pc,
    output reg [31:0] pc
    );
    
    always@(posedge clk)
        begin
            if(rst)
                pc <= 32'h00000000;
             else
                pc <= next_pc;
         end
endmodule
