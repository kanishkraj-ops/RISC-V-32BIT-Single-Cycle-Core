`timescale 1ns / 1ps


module instruction_mem(
    input [31:0]    ADDRESS,  //Address to ROM
    output [31:0]   INSTR     // Instruction stored at that particular instruction
    );
    
    reg [31:0] mem [0:1023];
    //initialize the memory using memory file
    initial begin
        $readmemh("initialize.mem",mem);
     end
     assign INSTR = mem[ADDRESS >> 2];
     
endmodule
