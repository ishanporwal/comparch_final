//-----------------------------------------------------------------------------
// Branch Logic
//
// The Branch Logic module determines whether a conditional branch instruction
// (such as beq, bne, blt, bge, etc.) should be taken. It receives the values
// of the two source registers and the funct3 field from the instruction,
// and compares the values according to the branch condition. If the condition
// is met, it asserts the branch_taken signal, which is used by the top-level
// module to update the PC to the branch target address.
//
// Used In: Execute
//
// File Contributor(s): Ahan Trivedi
//-----------------------------------------------------------------------------

module branch_logic(
    input  logic [31:0] rs1, // First register value
    input  logic [31:0] rs2, // Second register value
    input  logic [2:0] funct3, // Branch type selector
    output logic branch_taken // Asserted if branch condition is met
);

    always_comb begin
        case (funct3)
            3'b000: branch_taken = (rs1 == rs2); // BEQ
            3'b001: branch_taken = (rs1 != rs2); // BNE
            3'b100: branch_taken = ($signed(rs1) < $signed(rs2)); // BLT
            3'b101: branch_taken = ($signed(rs1) >= $signed(rs2)); // BGE
            3'b110: branch_taken = (rs1 < rs2); // BLTU
            3'b111: branch_taken = (rs1 >= rs2); // BGEU
            default: branch_taken = 1'b0; // Not a branch
        endcase
    end

endmodule
