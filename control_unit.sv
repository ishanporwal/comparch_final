//-----------------------------------------------------------------------------
// Main Control Unit
//
// This module implements a finite state machine (FSM) that cycles through five
// stages: PC_UPDATE, MEMORY_PULL, FETCH, EXECUTE, and SECOND_EXECUTE. It 
// generates control signals for ALU operations, register writes, memory 
// accesses, program counter updates, and instruction register loading.
//
// PC_UPDATE updates the program counter. MEMORY_PULL sets the memory address 
// for fetching instructions. FETCH loads the instruction into the register. 
// EXECUTE decodes and processes instructions (R-type, I-type, load, store, 
// branch, JAL, JALR, LUI, AUIPC). SECOND_EXECUTE completes memory loads by 
// writing the fetched data to the register.
//
// The memory_funct3 signal is set to 3'b010 during instruction fetches and 
// to funct3 during memory accesses. The unit controls the processor’s datapath 
// based on opcode, funct3, and funct7.
//
// File Contributor(s): Ertug Umsur, Ishan Porwal
//-----------------------------------------------------------------------------

module control_unit (
    input logic clk,
    input  logic [6:0] opcode,       // Operation code
    input  logic [4:0] rd_address,           // Destination register
    input  logic [2:0] funct3,       // Function 3 bits
    input  logic [4:0] rs1_address,          // Source register 1
    input  logic [4:0] rs2_address,          // Source register 2
    input  logic [6:0] funct7,        // Function 7 bits (upper 7 bits)

    input  logic [31:0] alu_result,
    input  logic [31:0] rs1,
    input  logic [31:0] immediate,
    input  logic [31:0] pc,
    input  logic [31:0] rs2,
    input  logic [31:0] memory_read_value,

    input  logic branch_taken, // Input for Branch Logic

    output logic [3:0] pc_control, // Control Signal for Program Counter
    output logic [1:0] ir_control, // Control Signal for Instruction Register
    output logic [4:0] alu_control, // Control Signal for ALU

    output logic register_write_en, // Enable for Write in Register File
    output logic memory_write_en,

    output logic [31:0] memory_write,
    output logic [31:0] memory_write_address,
    output logic [31:0] memory_read_address,
    output logic [31:0] register_file_write,
    output logic [31:0] op2, // Second Input for the ALU
    output logic [2:0] memory_funct3
);

    typedef enum logic[2:0] {
        SECOND_EXECUTE,
        EXECUTE,
        FETCH,
        MEMORY_PULL,
        PC_UPDATE
    } fsm_state_t;

    fsm_state_t next_state_flag;
    fsm_state_t current_state = MEMORY_PULL;

    logic [6:0] imm1;
    logic [31:0] reg1, reg2, reg3, reg4, mem1, mem2;

    assign imm1 = immediate[11:5];
    assign reg1 = {{24{memory_read_value[7]}}, memory_read_value[7:0]};
    assign reg2 = {{16{memory_read_value[15]}}, memory_read_value[15:0]};
    assign reg3 = {24'b0, memory_read_value[7:0]};
    assign reg4 = {16'b0, memory_read_value[15:0]};
    assign mem1 = {{24{rs2[7]}}, rs2[7:0]};
    assign mem2 = {{16{rs2[15]}}, rs2[15:0]};

    always_comb begin
        // default assignments
        pc_control = 4'b0000;
        ir_control = 2'b00;
        memory_funct3 = 3'b010;
        alu_control = 5'b00000;
        register_write_en = 1'b0;
        memory_write_en = 1'b0;
        memory_write = 32'b0;
        memory_write_address = 32'b0;
        memory_read_address = 32'b0;
        register_file_write = 32'b0;
        op2 = 32'b0;
        next_state_flag = PC_UPDATE;

        case (current_state)
            PC_UPDATE: begin
                pc_control           = 4'b0100;
                ir_control           = 2'b00;
                alu_control          = 5'b00000;

                register_write_en    = 1'b0;
                memory_write_en      = 1'b0;

                memory_write         = 32'b0;
                memory_write_address = 32'b0;
                memory_read_address  = 32'b0;
                register_file_write  = 32'b0;
                op2                  = 32'b0;

                next_state_flag      = MEMORY_PULL;
            end

            MEMORY_PULL: begin
                pc_control           = 4'b0000;
                ir_control           = 2'b00;
                alu_control          = 5'b00000;

                register_write_en    = 1'b0;
                memory_write_en      = 1'b0;

                memory_write         = 32'b0;
                memory_write_address = 32'b0;
                memory_read_address  = pc;
                register_file_write  = 32'b0;
                op2                  = 32'b0;

                next_state_flag      = FETCH;
            end
            
            FETCH: begin
                pc_control = 4'b0000;
                ir_control = 2'b01;
                alu_control = 5'b00000;

                register_write_en = 1'b0;
                memory_write_en = 1'b0;

                memory_write = 32'b0;
                memory_write_address = 32'b0;
                memory_read_address = 32'b0;
                register_file_write = 32'b0;
                op2 = 32'b0;

                next_state_flag = EXECUTE;
            end

            EXECUTE: begin
                case(opcode) 

                    7'b0110011: begin // R-Type
                        memory_funct3 = funct3;
                        pc_control = 4'b0000;
                        ir_control = 2'b00;

                        register_write_en = 1'b1;
                        memory_write_en = 1'b0;

                        memory_write = 32'b0;
                        memory_write_address = 32'b0;
                        memory_read_address = 32'b0;
                        register_file_write = alu_result;
                        op2 = rs2;

                        if (funct7 == 7'b0000000) begin
                            case(funct3)
                                3'b000: alu_control = 5'b00000; // ADD
                                3'b100: alu_control = 5'b00100; // XOR
                                3'b110: alu_control = 5'b00011; // OR
                                3'b111: alu_control = 5'b00010; // AND
                                3'b001: alu_control = 5'b00111; // SLL
                                3'b101: alu_control = 5'b01000; // SRL
                                3'b010: alu_control = 5'b00101; // SLT
                                3'b011: alu_control = 5'b00110; // SLTU
                            endcase
                        end else if (funct7 == 7'b0100000) begin
                            case(funct3)
                                3'b000: alu_control = 5'b00001; // SUB
                                3'b101: alu_control = 5'b01001; // SRA
                            endcase
                        end
                        else if (funct7 == 7'b0000001) begin
                            case(funct3)
                                3'b000: alu_control = 5'b01011; // MUL
                                3'b001: alu_control = 5'b01100; // MULH
                                3'b010: alu_control = 5'b01101; // MULHSU
                                3'b011: alu_control = 5'b01110; // MULHU
                                3'b100: alu_control = 5'b01111; // DIV
                                3'b101: alu_control = 5'b10000; // DIVU
                                3'b110: alu_control = 5'b10001; // REM
                                3'b111: alu_control = 5'b10010; // REMU
                            endcase
                        end
                        next_state_flag = PC_UPDATE;
                    end

                    7'b0010011: begin // I-Type ALU Immediate
                        memory_funct3 = funct3;
                        pc_control = 4'b0000;
                        ir_control = 2'b00;

                        register_write_en = 1'b1;
                        memory_write_en = 1'b0;

                        memory_write = 32'b0;
                        memory_write_address = 32'b0;
                        memory_read_address = 32'b0;
                        register_file_write = alu_result;
                        op2 = immediate;

                        case(funct3)
                            3'b000: alu_control = 5'b00000; // ADDI
                            3'b100: alu_control = 5'b00100; // XORI
                            3'b110: alu_control = 5'b00011; // ORI
                            3'b111: alu_control = 5'b00010; // ANDI
                            3'b001: if(imm1 == 7'b0000000) begin alu_control = 5'b00111; end
                            3'b101: if(imm1 == 7'b0000000) begin alu_control = 5'b01000; end else if (imm1 == 7'b0100000) begin alu_control = 5'b01001; end
                            3'b010: alu_control = 5'b00101; // SLTI
                            3'b011: alu_control = 5'b00110; // SLTIU
                        endcase

                        next_state_flag = PC_UPDATE;
                    end

                    7'b0000011: begin // I-Type Load
                        memory_funct3 = funct3;
                        pc_control = 4'b0000;
                        ir_control = 2'b00;
                        alu_control = 5'b00000;

                        register_write_en = 1'b0;
                        memory_write_en = 1'b0;

                        memory_write = 32'b0;
                        memory_write_address = 32'b0;
                        memory_read_address = alu_result;
                        op2 = immediate;

                        next_state_flag = SECOND_EXECUTE;
                    end

                    7'b0100011: begin // S-Type Store
                        memory_funct3 = funct3;
                        pc_control = 4'b0000;
                        ir_control = 2'b00;
                        alu_control = 5'b00000;

                        register_write_en = 1'b0;
                        memory_write_en = 1'b1;

                        memory_write_address = alu_result;
                        memory_read_address = 32'b0;
                        register_file_write = 32'b0;
                        op2 = immediate;

                        case(funct3)
                            3'b000: memory_write = mem1; // SB
                            3'b001: memory_write = mem2; // SH
                            3'b010: memory_write = rs2; // SW
                        endcase

                        next_state_flag = PC_UPDATE;
                    end

                    7'b1100011: begin // B-Type Branch
                        if (branch_taken) begin
                            memory_funct3 = funct3;
                            pc_control = 4'b0110;
                            ir_control = 2'b10;
                            alu_control = 5'b00000;

                            register_write_en = 1'b0;
                            memory_write_en = 1'b0;

                            memory_write = 32'b0;
                            memory_write_address = 32'b0;
                            memory_read_address = 32'b0;
                            register_file_write = 32'b0;
                            op2 = 32'b0;

                            next_state_flag = MEMORY_PULL;
                        end else begin
                            memory_funct3 = funct3;
                            pc_control = 4'b0000;
                            ir_control = 2'b00;
                            alu_control = 5'b00000;

                            register_write_en = 1'b0;
                            memory_write_en = 1'b0;

                            memory_write = 32'b0;
                            memory_write_address = 32'b0;
                            memory_read_address = 32'b0;
                            register_file_write = 32'b0;
                            op2 = 32'b0;

                            next_state_flag = PC_UPDATE;
                        end
                    end

                    7'b1101111: begin // JAL
                        memory_funct3 = funct3;
                        pc_control = 4'b0110;
                        ir_control = 2'b00;
                        alu_control = 5'b00000;

                        register_write_en = 1'b1;
                        memory_write_en = 1'b0;

                        memory_write = 32'b0;
                        memory_write_address = 32'b0;
                        memory_read_address = 32'b0;
                        register_file_write = pc + 3'b100;
                        op2 = 32'b0;

                        next_state_flag = MEMORY_PULL;
                    end
                        
                    7'b1100111: begin // JALR
                        memory_funct3 = funct3;
                        pc_control = 4'b0101;
                        ir_control = 2'b00;
                        alu_control = 5'b00000;

                        register_write_en = 1'b1;
                        memory_write_en = 1'b0;

                        memory_write = 32'b0;
                        memory_write_address = 32'b0;
                        memory_read_address = 32'b0;
                        register_file_write = pc + 3'b100;
                        op2 = 32'b0;

                        next_state_flag = MEMORY_PULL;
                    end

                    7'b0110111: begin // LUI
                        memory_funct3 = funct3;
                        pc_control = 4'b0000;
                        ir_control = 2'b00;
                        alu_control = 5'b00000;

                        register_write_en = 1'b1;
                        memory_write_en = 1'b0;

                        memory_write = 32'b0;
                        memory_write_address = 32'b0;
                        memory_read_address = 32'b0;
                        register_file_write = immediate;
                        op2 = 32'b0;

                        next_state_flag = PC_UPDATE;
                    end

                    7'b0010111: begin // AUIPC
                        memory_funct3 = funct3;
                        pc_control = 4'b0000;
                        ir_control = 2'b00;
                        alu_control = 5'b00000;

                        register_write_en = 1'b1;
                        memory_write_en = 1'b0;

                        memory_write = 32'b0;
                        memory_write_address = 32'b0;
                        memory_read_address = 32'b0;
                        register_file_write = pc + immediate;
                        op2 = 32'b0;

                        next_state_flag = PC_UPDATE;
                    end
                endcase
            end

            SECOND_EXECUTE: begin
                memory_funct3 = funct3;
                pc_control = 4'b0000;
                ir_control = 2'b00;
                alu_control = 5'b00000;

                register_write_en = 1'b1;
                memory_write_en = 1'b0;

                memory_write = 32'b0;
                memory_write_address = 32'b0;
                memory_read_address = 32'b0;
                op2 = 32'b0;

                case(funct3)
                    3'b000: register_file_write = reg1; // LB
                    3'b001: register_file_write = reg2; // LH
                    3'b010: register_file_write = memory_read_value; // LW
                    3'b100: register_file_write = reg3; // LBU
                    3'b101: register_file_write = reg4; // LHU
                endcase

                next_state_flag = PC_UPDATE;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        current_state <= next_state_flag;
    end

endmodule
