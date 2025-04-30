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
    input logic [4:0] alu_control, // Control signal to determine operation to perform
    output logic [31:0] result // Result
);

    logic [4:0] shamt;
    logic signed [63:0] product_s;
    logic [63:0] product_u;
    

    assign shamt = operand_b[4:0];
    

    always_comb begin
        case (alu_control)
            5'b00000: result = operand_a + operand_b; // ADD
            5'b00001: result = operand_a - operand_b; // SUB
            5'b00010: result = operand_a & operand_b; // AND
            5'b00011: result = operand_a | operand_b; // OR
            5'b00100: result = operand_a ^ operand_b; // XOR
            5'b00101: result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0; // SLT
            5'b00110: result = (operand_a < operand_b) ? 32'd1 : 32'd0; // SLTU
            5'b00111: result = operand_a << shamt; // SLL
            5'b01000: result = operand_a >> shamt; // SRL
            5'b01001: result = $signed(operand_a) >>> shamt; // SRA
            5'b01010: result = (operand_a + operand_b) & 32'hFFFFFFFE; // JALR

            // RV32M
            5'b01011: result = operand_a * operand_b;   // MUL

            5'b01100: begin                             // MULH
                product_s = $signed(operand_a) * $signed(operand_b);
                result = product_s >>> 32;
            end

            5'b01101: begin                             // MULHSU
                product_s = $signed({{32{operand_a[31]}}, operand_a}) * {{32{1'b0}}, operand_b};
                result = product_s >>> 32;
            end

            5'b01110: begin                             // MULHU
                product_u = $unsigned(operand_a) * $unsigned(operand_b);
                result = product_u >> 32;
            end

            5'b01111: begin                             // DIV
                if (operand_b == 32'd0) begin
                    result = -32'sd1;
                end else begin
                    result = $signed(operand_a) / $signed(operand_b);
                end 
            end

            5'b10000: begin                             // DIVU
                if (operand_b == 32'd0) begin
                    result = 32'hFFFFFFFF;
                end else begin
                    result = $unsigned(operand_a) / $unsigned(operand_b);
                end 
            end

            5'b10001: begin                             // REM
                if (operand_b == 32'd0) begin
                    result = operand_a;
                end else begin
                    result = $signed(operand_a) % $signed(operand_b);
                end 
            end

            5'b10010: begin                             // REMU
                if (operand_b == 32'd0) begin
                    result = operand_a;
                end else begin
                    result = $unsigned(operand_a) % $unsigned(operand_b);
                end 
            end
            default: result = 32'b0;  // Default case
        endcase
    end

endmodule
