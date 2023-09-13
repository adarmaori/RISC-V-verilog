module WRT_BCK(
    input clk, en, resetn,
    input [31:0] rd_data,
    input [31:0] mem_out,
    input [31:0] jmp_addr,
    output [31:0] data_bus,
    output [31:0] addr_bus
);
endmodule : WRT_BCK