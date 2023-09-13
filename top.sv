module top (
    input clk
);

    // TODO: Setup to be dealt with later
    parameter S_FETCH   = 3'b000;
    parameter S_DECODE  = 3'b001;
    parameter S_EXECUTE = 3'b010;
    parameter S_MEMACC  = 3'b011;
    parameter S_WRTBCK  = 3'b100;

    reg [2:0] state = S_FETCH;

    reg [31:0] mem [0:1023];
    // TODO: THIS CANNOT BE A REG, IT MUST BE CONNECTED THROUGH AN ADDRESS BUS

    // Main registers
    reg [31:0] reg_file [0:31];
    reg [31:0] pc;

    // ----------- Pipeline registers -----------
    // FETCH
    reg [31:0] instruction;

    // DECODE
    reg [6:0] opcode;
    reg [4:0] rs1;
    reg [4:0] rs2;
    reg [4:0] rd;
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg [31:0] imm;

    // EXECUTE
    reg [31:0] rd_data;

    // MEMACC
    reg [31:0] mem_addr;

    // WRTBCK
    reg [31:0] mem_out;
    reg [31:0] jmp_addr;

    initial begin
        pc <= 0;
        for (int i = 0; i < 32; i = i + 1) reg_file[i] <= 0;
        mem[0]  <= 32'b00000000000100000000000010010011; // ADDI R1, R0, 1
        mem[4]  <= 32'b00000000000100000000000100010011; // ADDI R2, R0, 1
        mem[8]  <= 32'b00000110010000000000000110010011; // ADDI R3, R0, 100
        mem[12] <= 32'b00000000000100010000000010110011; // ADD R1, R1, R2
        mem[16] <= 32'b00000000000100011010000000100011; // SW R1, 0(R3)
        mem[20] <= 32'b00000000000100010000000100110011; // ADD R2, R1, R2
        mem[24] <= 32'b00000000001000011010000010100011; // SW R2, 0(R3)
        mem[28] <= 32'b00000000001000011000000110010011; // ADDI R3, R3, 1
        mem[32] <= 32'b00000000110000000000000001100111; // JALR, R0, R0, 8
    end

    // ----------- Pipeline Logic -----------
    always @ (posedge clk) begin
        // dump info
        case (state)
            S_FETCH: begin
                instruction <= mem[pc];
                pc <= pc + 4;
                state <= S_DECODE;
            end
            S_DECODE: begin
                opcode <= instruction[6:0];
                rs1    <= instruction[19:15];
                rs2    <= instruction[24:20];
                rd     <= instruction[11:7];
                funct3 <= instruction[14:12];
                funct7 <= instruction[31:25];
                case (instruction[6:0])
                    7'b0110111, 7'b0010111: imm <= {instruction[31:12], 12'b0}; // U-type
                    7'b1101111: imm <= {{13{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // J-type
                    7'b1100111, 7'b0000011, 7'b0010011: imm <= {{20{instruction[31]}}, instruction[31:20]}; // I-type
                    7'b1100011: imm <= {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type
                    7'b0100011: imm <= {instruction[31:25], instruction[11:7]}; // S-type
                endcase
                state <= S_EXECUTE;
            end
            S_EXECUTE: begin
                case (opcode)
                    7'b0110111: rd_data <= imm; // LUI
                    7'b0010111: rd_data <= imm + pc; // AUIPC
                    7'b1101111: begin // JAL
                        jmp_addr <= pc + imm;
                        rd_data <= pc + 4;
                    end
                    7'b1100111: begin // JALR
                        jmp_addr <= reg_file[rs1] + imm;
                        jmp_addr[0] <= 1'b0;
                        rd_data <= pc + 4;
                    end
                    7'b1100011: begin // BRANCH
                        jmp_addr <= pc + 4; // If not jumping, return to next instruction
                        case (funct3)
                            3'b000: begin // BEQ
                                if (reg_file[rs1] == reg_file[rs2]) begin
                                    jmp_addr <= pc + imm;
                                    jmp_addr[0] <= 1'b0;
                                end
                            end
                            3'b001: begin // BNE
                                if (reg_file[rs1] != reg_file[rs2]) begin
                                    jmp_addr <= pc + imm;
                                    jmp_addr[0] <= 1'b0;
                                end
                            end
                            3'b100: begin // BLT
                                if (reg_file[rs1] < reg_file[rs2]) begin
                                    jmp_addr <= pc + imm;
                                    jmp_addr[0] <= 1'b0;
                                end
                            end
                            3'b101: begin // BGE
                                if (reg_file[rs1] >= reg_file[rs2]) begin
                                    jmp_addr <= pc + imm;
                                    jmp_addr[0] <= 1'b0;
                                end
                            end
                            3'b110: begin // BLTU
                                if (reg_file[rs1] < reg_file[rs2]) begin
                                    jmp_addr <= pc + imm;
                                    jmp_addr[0] <= 1'b0;
                                end
                            end
                            3'b111: begin // BGEU
                                if (reg_file[rs1] >= reg_file[rs2]) begin
                                    jmp_addr <= pc + imm;
                                    jmp_addr[0] <= 1'b0;
                                end
                            end
                        endcase
                    end
                    7'b0000011: begin
                        case (funct3)
                            3'b000: mem_addr <= reg_file[rs1] + imm; // LB
                            3'b001: mem_addr <= reg_file[rs1] + imm; // LH
                            3'b010: mem_addr <= reg_file[rs1] + imm; // LW
                            3'b100: mem_addr <= reg_file[rs1] + imm; // LBU
                            3'b101: mem_addr <= reg_file[rs1] + imm; // LHU
                        endcase
                    end
                    7'b0100011: begin
                        mem_addr <= reg_file[rs1] + imm;
                        case (funct3)
                            3'b000: mem_out <= reg_file[rs2][7:0]; // SB
                            3'b001: mem_out <= reg_file[rs2][15:0]; // SH
                            3'b010: mem_out <= reg_file[rs2][31:0]; // SW
                        endcase
                    end
                    7'b0010011: begin
                        case (funct3)
                            3'b000: rd_data <= reg_file[rs1] + imm; // ADDI
                            3'b010: rd_data <= reg_file[rs1] < imm; // SLTI
                            3'b011: rd_data <= reg_file[rs1] < imm; // SLTIU
                            3'b100: rd_data <= reg_file[rs1] ^ imm; // XORI
                            3'b110: rd_data <= reg_file[rs1] | imm; // ORI
                            3'b111: rd_data <= reg_file[rs1] & imm; // ANDI
                            3'b001: rd_data <= reg_file[rs1] << imm[4:0]; // SLLI
                            3'b101: begin // SRLI/SRAI
                                if (funct7[5] == 1'b0) begin
                                    rd_data <= reg_file[rs1] >> imm[4:0]; // SRLI
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
                                    rd_data <= reg_file[rs1] + reg_file[rs2]; // ADD
                                end else begin
                                    rd_data <= reg_file[rs1] - reg_file[rs2]; // SUB
                                end
                            end
                            3'b001: rd_data <= reg_file[rs1] << reg_file[rs2]; // SLL
                            3'b010: rd_data <= reg_file[rs1] < reg_file[rs2]; // SLT
                            3'b011: rd_data <= reg_file[rs1] < reg_file[rs2]; // SLTU
                            3'b100: rd_data <= reg_file[rs1] ^ reg_file[rs2]; // XOR
                            3'b101: begin // SRL/SRA
                                if (funct7 == 7'b0000000) begin
                                    rd_data <= reg_file[rs1] >> reg_file[rs2]; // SRL
                                end else begin
                                    //TODO: rd_data <= {reg_file[rs1][31:0], reg_file[rs1][31:reg_file[rs2]]}; // SRA
                                end
                            end
                            3'b110: rd_data <= reg_file[rs1] | reg_file[rs2]; // OR
                            3'b111: rd_data <= reg_file[rs1] & reg_file[rs2]; // AND
                        endcase
                    end
                    default: begin end
                endcase
                state <= S_MEMACC;
            end
            S_MEMACC: begin
                // TODO: For now this is empty
                state <= S_WRTBCK;
            end
            S_WRTBCK: begin
                $display("Arrived at WRTBCK");
                case (opcode)
                    7'b0110111, 7'b0010111, 7'b0000011, 7'b0010011, 7'b0110011: begin
                        $display("Writing %h to register %d", rd_data, rd);
                        if (rd != 0) reg_file[rd] <= rd_data;
                    end
                    7'b1100011, 7'b0000011, 7'b0100011: begin
                        $display("Writing %h to memory address %d", mem_out, mem_addr);
                        mem[mem_addr] <= mem_out;
                    end
                    7'b1101111, 7'b1100111, 7'b1100011: begin
                        $display("JUMPIIIIIIIIIIIIIIIIIIING");
                        pc <= jmp_addr; // TODO: Check if this is correct, maybe move this part to the execute stage to save some time
                    end
                    default: begin end
                endcase
                state <= S_FETCH;
                $display("Jump Address: %b", jmp_addr);
                $display("State: %b", state);
                $display("PC: %d", pc);
                $display("Instruction: %b", instruction);
                $display("Opcode: %b", opcode);
                $display("RS1: %b", rs1);
                $display("RS2: %b", rs2);
                $display("RD: %b", rd);
                $display("Funct3: %b", funct3);
                $display("Funct7: %b", funct7);
                $display("Imm: %b", imm);
                $display("R1: %h", reg_file[1]);
                $display("R2: %h", reg_file[2]);
                $display("R3: %h", reg_file[3]);
                $display("R4: %h", reg_file[4]);
                $display("R5: %h", reg_file[5]);
                $display("R6: %h", reg_file[6]);
                $display("R7: %h", reg_file[7]);
                $display("R8: %h", reg_file[8]);
                $display("R9: %h", reg_file[9]);
                $display("ADDR-100: %h", mem[100]);
                $display("ADDR-101: %h", mem[101]);
                $display("ADDR-102: %h", mem[102]);
                $display("ADDR-103: %h", mem[103]);
                $display("ADDR-104: %h", mem[104]);
                $display("----------------------------------------------------");
            end
        endcase
    end

endmodule : top