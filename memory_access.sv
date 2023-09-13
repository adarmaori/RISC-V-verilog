module MEM_ACC(
    input clk, en, resetn,
    input [31:0] addr,
    input [31:0] data_bus,
    output reg [31:0] addr_bus,
    output reg        mem_oe,
    output reg [31:0] mem_data
);
    always @ (posedge clk, negedge resetn) begin
        if (!resetn) begin
            addr_bus <= 0;
            mem_data <= 0;
        end else begin
            if (en) begin
                case (opcode)
                    7'b0000011: begin
                        addr_bus <= addr;
                        mem_oe <= 1'b1;
                        mem_data <= data_bus;
                    end
                   default: begin
                       addr_bus <= 0;
                       mem_data <= 0;
                   end
                endcase
                addr_bus <= addr;
                mem_data <= data_bus;
                // TODO: add delay
            end
        end
    end
endmodule : MEM_ACC