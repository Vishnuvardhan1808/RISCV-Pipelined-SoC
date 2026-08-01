`timescale 1ns / 1ps

module tb_soc_top();

    reg clk;
    reg reset;

    // Instantiate the complete SoC
    soc_top dut (
        .clk(clk),
        .reset(reset)
    );

    // Clock Generation (100 MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk = 0;
        reset = 1;

        $display("========================================");
        $display("   RISC-V SoC Simulation Started        ");
        $display("========================================");

        // Release reset after 20ns
        #20 reset = 0;

        // Let the CPU run its hardcoded assembly program
        // Increased to 500ns to account for Cache Miss latencies and Pipeline depth
        #100; 

        $display("========================================");
        $display("   RISC-V SoC Simulation Completed      ");
        $display("========================================");
        $finish;
    end

    // Console Output Monitor
    // This prints to the Vivado Tcl Console every time one of these signals changes
    initial begin
        $monitor("Time=%0t ns | PC=0x%08h | Instr=0x%08h | Cache_Stall=%b", 
                 $time, dut.pc, dut.instr, dut.cpu_stall);
    end

endmodule
