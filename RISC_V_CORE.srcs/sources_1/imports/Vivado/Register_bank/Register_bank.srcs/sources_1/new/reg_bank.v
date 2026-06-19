`timescale 1ns / 1ps

module reg_bank #(
    parameter DATA_WIDTH = 32,  // Number of bits per register
    parameter ADDR_WIDTH = 5    // Number of address bits (Total registers = 2^ADDR_WIDTH)
)(
    input  [ADDR_WIDTH-1:0] sr1,       // Source Register 1 Address
    input  [ADDR_WIDTH-1:0] sr2,       // Source Register 2 Address
    input  [ADDR_WIDTH-1:0] dr,        // Destination Register Address
    input  [DATA_WIDTH-1:0] wr_data,   // Data vector to be written
    input                   write,     // Write Enable control signal
    input                   clk,       // System Clock
    input                   rst,       // System Reset (Prevents uninitialized simulation states)
    output [DATA_WIDTH-1:0] rd_data1,  // Asynchronous Read Output 1
    output [DATA_WIDTH-1:0] rd_data2   // Asynchronous Read Output 2
);

    // Localparam automatically calculates total registers based on address width
    localparam NUM_REGS = 1 << ADDR_WIDTH; // Equivalent to 2^ADDR_WIDTH

    // Parameterized 2D array memory block: [NUM_REGS] elements, each [DATA_WIDTH] bits wide
    reg [DATA_WIDTH-1:0] registers [NUM_REGS-1:0];

    // Asynchronous Combinational Reads
    assign rd_data1 = registers[sr1];
    assign rd_data2 = registers[sr2];

    // Synchronous Sequential Writes with initialization loop
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            // Scales dynamically to clear every single register inside the array on reset
            for (i = 0; i < NUM_REGS; i = i + 1) begin
                registers[i] <= {DATA_WIDTH{1'b0}}; // Fills the entire width with zeros
            end
        end else if (write) begin
            registers[dr] <= wr_data;
        end
    end

endmodule