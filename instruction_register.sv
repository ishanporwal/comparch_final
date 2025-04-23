//-----------------------------------------------------------------------------
// Instruction Register
//
// This module holds the fetched instruction from memory so that it remains
// available throughout the multicycle execution of an instruction.
// The register updates on the rising edge of the clock when 'enable' is high.
//
// File Contributor(s): Ahan Trivedi
//-----------------------------------------------------------------------------

module instruction_register (
    input  logic clk, // Clock signal
    input  logic [1:0] ir_control, // Control unit signal for Instruction Register
    input  logic [31:0] instr_in, // Instruction from memory
    output logic [31:0] instr_out // Latched instruction output
);

    logic reset, enable;

    assign reset = ir_control[1];
    assign enable = ir_control[0];


    always_ff @(posedge clk) begin
        if (reset)
            instr_out <= 32'b0;
        else if (enable)
            instr_out <= instr_in;
    end

endmodule
