module EXECUTE(
    input clk, en, resetn,
    input [31:0] pc,
    input [6:0] opcode,
    input [4:0] rs1, rs2, rd,
    input [31:0] imm,
    input [31:0] rs1_data, rs2_data,
    output reg [31:0] pc_out,
    output reg [31:0] rd_data,
    output reg [31:0] jmp_addr,
    output reg [31:0] mem_out,
    output reg [31:0] mem_addr
);
    always @ (posedge clk, negedge resetn) begin
        if (!resetn) begin
            pc_out <= 0;
            rd_data <= 0;
            jmp_addr <= 0;
            mem_out <= 0;
            mem_addr <= 0;
        end else begin
            if (en) begin
                case (opcode)
                    7'b0110111: rd_data <= imm; // LUI
                    7'b0010111: rd_data <= imm + pc; // AUIPC
                    7'b1101111: begin // JAL
                        jmp_addr <= pc + imm;
                        rd_data <= pc + 4;
                    end
                    7'b1100111: begin // JALR
                        jmp_addr <= rs1_data + imm;
                        jmp_addr[0] <= 1'b0;
                        rd_data <= pc + 4;
                    end
                    7'b1100011: begin // BRANCH
                        jmp_addr <= pc + 4; // If not jumping, return to next instruction
                        case (funct3)
                            3'b000: begin // BEQ
                                if (rs1_data == rs2_data) begin
                                    jmp_addr <= pc + imm;
                                    jmp_addr[0] <= 1'b0;
                                end
                            end
                            3'b001: begin // BNE
                                if (rs1_data != rs2_data) begin
                                    jmp_addr <= pc + imm;
                                    jmp_addr[0] <= 1'b0;
                                end
                            end
                            3'b100: begin // BLT
                                if (rs1_data < rs2_data) begin
                                    jmp_addr <= pc + imm;
                                    jmp_addr[0] <= 1'b0;
                                end
                            end
                            3'b101: begin // BGE
                                if (rs1_data >= rs2_data) begin
                                    jmp_addr <= pc + imm;
                                    jmp_addr[0] <= 1'b0;
                                end
                            end
                            3'b110: begin // BLTU
                                if (rs1_data < rs2_data) begin
                                    jmp_addr <= pc + imm;
                                    jmp_addr[0] <= 1'b0;
                                end
                            end
                            3'b111: begin // BGEU
                                if (rs1_data >= rs2_data) begin
                                    jmp_addr <= pc + imm;
                                    jmp_addr[0] <= 1'b0;
                                end
                            end
                        endcase
                    end
                    7'b0000011: begin
                        mem_addr <= rs1_data + imm;
                    end
                    7'b0100011: begin
                        mem_addr <= rs1_data + imm;
                        case (funct3)
                            3'b000: mem_out <= rs2_data[7:0]; // SB
                            3'b001: mem_out <= rs2_data[15:0]; // SH
                            3'b010: mem_out <= rs2_data[31:0]; // SW
                        endcase
                    end
                    7'b0010011: begin
                        case (funct3)
                            3'b000: rd_data <= rs1_data + imm; // ADDI
                            3'b010: rd_data <= rs1_data < imm; // SLTI
                            3'b011: rd_data <= rs1_data < imm; // SLTIU
                            3'b100: rd_data <= rs1_data ^ imm; // XORI
                            3'b110: rd_data <= rs1_data | imm; // ORI
                            3'b111: rd_data <= rs1_data & imm; // ANDI
                            3'b001: rd_data <= rs1_data << imm[4:0]; // SLLI
                            3'b101: begin // SRLI/SRAI
                                if (funct7[5] == 1'b0) begin
                                    rd_data <= rs1_data >> imm[4:0]; // SRLI
                                end else begin
                                    // TODO: rd_data <= {imm[4:0], reg_file[rs1][31:imm[4:0]]}; // SRAI
                                end
                            end
                        endcase
                    end
                    7'b0110011: begin
                        case (funct3)
                            3'b000: begin // ADD/SUB
                                if (funct7 == 7'b0000000) begin
                                    rd_data <= rs1_data + rs2_data; // ADD
                                end else begin
                                    rd_data <= rs1_data - rs2_data; // SUB
                                end
                            end
                            3'b001: rd_data <= rs1_data << rs2_data; // SLL
                            3'b010: rd_data <= rs1_data < rs2_data; // SLT
                            3'b011: rd_data <= rs1_data < rs2_data; // SLTU
                            3'b100: rd_data <= rs1_data ^ rs2_data; // XOR
                            3'b101: begin // SRL/SRA
                                if (funct7 == 7'b0000000) begin
                                    rd_data <= rs1_data >> rs2_data; // SRL
                                end else begin
                                    //TODO: rd_data <= {reg_file[rs1][31:0], reg_file[rs1][31:reg_file[rs2]]}; // SRA
                                end
                            end
                            3'b110: rd_data <= rs1_data | rs2_data; // OR
                            3'b111: rd_data <= rs1_data & rs2_data; // AND
                        endcase
                    end
                    default: begin end
                endcase
            end
        end
    end
endmodule : EXECUTE