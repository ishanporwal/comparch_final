//-----------------------------------------------------------------------------
// Arithmetic Logic Unit
//
// This module performs arithmetic and logical operations for the RV32I instruction set,
// based on a 4-bit alu_control signal provided by the ALU control unit. It takes in two
// 32-bit operands and computes the selected operation (e.g., add, sub, and, or, slt, etc.).
// The result is used for register write-back, memory addressing, or branch decision-making.
// The ALU also outputs a zero flag, which is used by the branch logic.
//
// Used In: Execute
//
// File Contributor(s): Ahan Trivedi
//-----------------------------------------------------------------------------

module alu(
    input logic [31:0] operand_a, // First operand
    input logic [31:0] operand_b, // Second operand
    input logic [3:0] alu_control, // Control signal to determine operation to perform
    output logic [31:0] result // Result
);

    logic [4:0] shamt;

    assign shamt = operand_b[4:0];

    always_comb begin
        case (alu_control)
            4'b0000: result = operand_a + operand_b; // ADD
            4'b0001: result = operand_a - operand_b; // SUB
            4'b0010: result = operand_a & operand_b; // AND
            4'b0011: result = operand_a | operand_b; // OR
            4'b0100: result = operand_a ^ operand_b; // XOR
            4'b0101: result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0; // SLT
            4'b0110: result = (operand_a < operand_b) ? 32'd1 : 32'd0; // SLTU
            4'b0111: result = operand_a << shamt; // SLL
            4'b1000: result = operand_a >> shamt; // SRL
            4'b1001: result = $signed(operand_a) >>> shamt; // SRA
            4'b1010: result = (operand_a + operand_b) & 32'hFFFFFFFE; // JALR
            default: result = 32'b0;  // Default case
        endcase
    end

endmodule
