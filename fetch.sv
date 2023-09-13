module FETCH(
    input clk, en, resetn,
    input [31:0] pc,
    input [31:0] data_bus,
    output reg [31:0] addr_bus,
    output reg [31:0] inst,
    output reg [31:0] pcNext
);
    always @ (posedge clk, negedge resetn) begin
        if (!resetn) begin
            addr_bus <= 0;
            inst <= 0;
        end else begin
            if (en) begin
                addr_bus <= pc;
                inst <= data_bus;
                pcNext <= pc + 4;
            end else begin
                addr_bus <= 0;
                pcNext <= pc;
            end
        end
    end
endmodule : FETCH