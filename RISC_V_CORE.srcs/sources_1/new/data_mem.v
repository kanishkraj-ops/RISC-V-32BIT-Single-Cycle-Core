`timescale 1ns / 1ps

module data_mem #(
    parameter DATA_WIDTH = 32
    )( 
    input       clk,
    input       mem_write,
    input       mem_read,
    input [DATA_WIDTH-1:0] address,
    input [DATA_WIDTH-1:0] write_data,
    output [DATA_WIDTH-1:0] read_data
    );
    reg [DATA_WIDTH-1:0] ram [0:255];
    always @(posedge clk) begin
        if(mem_write)
            ram[address >>2] <= write_data;
         end
    assign read_data = mem_read ? ram[address >> 2] : {DATA_WIDTH{1'b0}};
endmodule
