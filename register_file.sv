//-----------------------------------------------------------------------------
// 32 Register Bank
//
// This module implements a 32x32-bit register file for the RV32I architecture.
// It supports two synchronous read ports (rs1 and rs2) and one synchronous
// write port (rd) with a write enable controlling all. Register x0 is
// hardwired to 0 and cannot be modified. The register file is used to store
// temporary values and intermediate results during instruction execution.
//
// File Contributor(s): Ishan Porwal, Ertug Umsur 
//-----------------------------------------------------------------------------

module RegisterFile #(
    parameter data_width = 32,
    parameter num_reg = 32,
    parameter idx_width = $clog2(num_reg)
)(
    input logic clk,
    input logic WEn,                                // write enable
    input logic [idx_width-1:0] rs1, rs2, rd,       // r/w reg addresses
    input logic [data_width-1:0] rdv,               // destination register value
    output logic [data_width-1:0] rs1v, rs2v        // register data
);

    logic [num_reg-1:0][data_width-1:0] regs;       // register array

    int i;
    
    initial begin
        for(i = 0; i < 32; i++) begin
            regs[i] = 32'b0;
        end
    end

    always_ff @(posedge clk) begin

        if (WEn && rd != 0) begin
            regs[rd] <= rdv;                         // writing to destination register
        end
    end

    always_comb begin
        rs1v = (rs1 == 0) ? '0 : regs[rs1];
        rs2v = (rs2 == 0) ? '0 : regs[rs2];
    end

endmodule
