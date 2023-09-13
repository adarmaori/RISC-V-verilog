module DECODE (
    input clk, en, resetn,
    input      [31:0] instruction,
    input      [31:0] pc,
    output     [31:0] pcOut,
    input      [31:0] reg_file [0:31],
    output reg [31:0] rs1_val, rs2_val,
    output reg [6:0] opcode,
    output reg [4:0] rs1, rs2, rd,
    output reg [31:0] imm,
    output reg [2:0] funct3,
    output reg [6:0] funct7
);
    always @ (posedge clk, negedge resetn) begin
        if (!resetn) begin
            opcode <= 0;
            rs1 <= 0;
            rs2 <= 0;
            rd <= 0;
            imm <= 0;
            funct3 <= 0;
            funct7 <= 0;
            jumping <= 0;
            rs1_val <= 0;
            rs2_val <= 0;
        end else begin
            if (en) begin
                pcOut <= pc;
                opcode <= instruction[6:0];
                rs1    <= instruction[19:15];
                rs2    <= instruction[24:20];
                rd     <= instruction[11:7];
                funct3 <= instruction[14:12];
                funct7 <= instruction[31:25];
                case (instruction[6:0])
                    7'b0110111: imm <= {instruction[31:12], 12'b0}; // U-type
                    7'b0010111: imm <= {instruction[31:12], 12'b0}; // U-type
                    7'b1101111: imm <= {{13{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // J-type
                    7'b1100111, 7'b0000011, 7'b0010011: imm <= {{20{instruction[31]}}, instruction[31:20]}; // I-type
                    7'b1100011: imm <= {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type
                    7'b0100011: imm <= {instruction[31:25], instruction[11:7]}; // S-type
                endcase
            end
        end
    end
endmodule : DECODE