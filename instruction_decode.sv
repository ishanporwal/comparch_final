//-----------------------------------------------------------------------------
// Instruction Decoder
//
// This module takes the 32-bit instruction fetched from memory and decodes it
// into its individual fields based on the instruction type (R, I, S, B, U, or J).
// Fields extracted include: opcode, rd, rs1, rs2, funct3, funct7. Based on the
// opcode, only the relevant fields are used downstream.
//
// Required Instructions: RV32I Base ISA (except ECALL, EBREAK, and CSR ops)
// - U-Type:    LUI, AUIPC
// - J-Type:    JAL
// - I-Type:    JALR, ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI --> Arithmetic/Logic
// - I-Type:    JALR --> JALR Instruction
// - I-Type:    LB, LH, LW, LBU, LHU -> Load Instructions
// - S-Type:    SB, SH, SW
// - B-Type:    BEQ, BNE, BLT, BGE, BLTU, BGEU
// - R-Type:    ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
//
// File Contributor(s): Nividh Singh, Ahan Trivedi
//-----------------------------------------------------------------------------

module instruction_decode(
    input logic [31:0] instruction,  // Raw 32-bit instruction pulled from memory
    output logic [6:0] opcode,       // Operation code
    output logic [4:0] rd,           // Destination register
    output logic [2:0] funct3,       // Function 3 bits
    output logic [4:0] rs1,          // Source register 1
    output logic [4:0] rs2,          // Source register 2
    output logic [6:0] funct7        // Function 7 bits (upper 7 bits)
);

    // Always extract the opcode (used to determine instruction type)
    assign opcode = instruction[6:0];

    logic [4:0] rd_i, rs1_i, rs2_i;
    logic [2:0] funct3_i;
    logic [6:0] funct7_i;

    assign rd_i     = instruction[11:7];
    assign funct3_i = instruction[14:12];
    assign rs1_i    = instruction[19:15];
    assign rs2_i    = instruction[24:20];
    assign funct7_i = instruction[31:25];


    // Set safe default values to avoid undefined logic
    always_comb begin
        rd     = 5'b0;
        rs1    = 5'b0;
        rs2    = 5'b0;
        funct3 = 3'b0;
        funct7 = 7'b0;

        case (opcode)
            // -----------------------
            // R-Type: Arithmetic/Logic
            // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
            // opcode: 0110011
            // -----------------------
            7'b0110011: begin
                rd     = rd_i;
                funct3 = funct3_i;
                rs1    = rs1_i;
                rs2    = rs2_i;
                funct7 = funct7_i;
            end
            // -----------------------
            // I-Type: Immediate Arithmetic & Logic
            // ADDI, SLTI, SLTIU, XORI, ORI, ANDI
            // SLLI, SRLI, SRAI (funct7 + rs2 used for shift variants)
            // opcode: 0010011
            // -----------------------
            7'b0010011: begin
                rd     = rd_i;
                funct3 = funct3_i;
                rs1    = rs1_i;
                rs2    = rs2_i;  // for shifts: this is shamt
                funct7 = funct7_i;  // for shifts: distinguishes SRLI/SRAI
            end
            // -----------------------
            // I-Type: Loads
            // LB, LH, LW, LBU, LHU
            // opcode: 0000011
            // -----------------------
            7'b0000011: begin
                rd     = rd_i;
                funct3 = funct3_i;
                rs1    = rs1_i;
            end
            // -----------------------
            // I-Type: Jump and Link Register
            // JALR
            // opcode: 1100111
            // -----------------------
            7'b1100111: begin
                rd     = rd_i;
                funct3 = funct3_i;
                rs1    = rs1_i;
            end
            // -----------------------
            // S-Type: Stores
            // SB, SH, SW
            // opcode: 0100011
            // -----------------------
            7'b0100011: begin
                funct3 = funct3_i;
                rs1    = rs1_i;
                rs2    = rs2_i;
            end
            // -----------------------
            // B-Type: Conditional Branches
            // BEQ, BNE, BLT, BGE, BLTU, BGEU
            // opcode: 1100011
            // -----------------------
            7'b1100011: begin
                funct3 = funct3_i;
                rs1    = rs1_i;
                rs2    = rs2_i;
            end
            // -----------------------
            // U-Type: LUI, AUIPC
            // opcode: LUI = 0110111, AUIPC = 0010111
            // -----------------------
            7'b0110111, // LUI
            7'b0010111: // AUIPC
            begin
                rd = rd_i;
            end
            // -----------------------
            // J-Type: Jump and Link
            // JAL
            // opcode: 1101111
            // -----------------------
            7'b1101111: begin
                rd = rd_i;
            end
            // -----------------------
            // Default: safe zeroes
            // -----------------------
            default: begin
                // All outputs already defaulted to 0
            end
        endcase
    end
endmodule
