//-----------------------------------------------------------------------------
// Testbench
//
// This testbench sets up and runs a simulation of the multicycle RV32I CPU.
// It generates the system clock and reset signals, instantiates the top-level
// processor module, and executes a loaded RISC-V program from memory.
// The testbench is used to verify correct instruction sequencing, register
// and memory behavior, and overall CPU functionality across multiple cycles.
//
// File Contributor(s): Ishan Porwal
//-----------------------------------------------------------------------------

`timescale 10ns/10ns
`include "top.sv"

module testbench;

    logic clk = 0;
    logic reset = 1;

    always begin
        #4 clk = ~clk;
    end

    top dut (
        .clk(clk)
    );

    defparam testbench.dut.MEM.INIT_FILE = "test_files/rv32m.txt";

    initial begin
        $dumpfile("processor.vcd");
        $dumpvars(0, testbench);
        $display("==== Starting Multicycle Processor Simulation ====");

        // Reset
        $display("[RESET]");
        reset = 1;
        #8;
        reset = 0;
        $display("Reset released\n");

        // Run long enough to execute program
        #2048;

        for (int i = 0; i < 32; i++) begin
            $display("x%0d = 0x%08h", i, dut.REGFILE.regs[i]);
        end

        $finish;
    end

endmodule
