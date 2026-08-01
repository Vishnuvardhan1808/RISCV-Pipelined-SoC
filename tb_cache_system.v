`timescale 1ns / 1ps

module tb_cache_system();
    reg clk, reset;
    
    // CPU Stimulus
    reg cpu_req, cpu_rw;
    reg [31:0] cpu_addr, cpu_wdata;
    wire [31:0] cpu_rdata;
    wire cpu_stall;

    // AXI wires to connect Cache and Memory
    wire mem_req, mem_rw, mem_ready;
    wire [31:0] mem_addr;
    wire [127:0] mem_wdata, mem_rdata;

    // Instantiate Cache
    direct_mapped_cache dut (
        .clk(clk), .reset(reset),
        .cpu_req(cpu_req), .cpu_rw(cpu_rw), .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata), .cpu_rdata(cpu_rdata), .cpu_stall(cpu_stall),
        .mem_req(mem_req), .mem_rw(mem_rw), .mem_addr(mem_addr),
        .mem_wdata(mem_wdata), .mem_rdata(mem_rdata), .mem_ready(mem_ready)
    );

    // Mock AXI Bridge & Memory (Simplified connection for test)
    // In a real system, you'd use an AXI Interconnect, but this verifies logic
    assign mem_ready = mem_req; // Simplification: memory ready immediately for this test
    assign mem_rdata = {96'b0, 32'hDEADBEEF}; // Return dummy data

    // Clock Generation
    always #5 clk = ~clk;

   initial begin
        clk = 0; reset = 1; cpu_req = 0;
        #20 reset = 0;

        // --- THE SETUP (Let this happen off-screen) ---
        // Force one initial miss to load the block into the cache
        #10 cpu_req = 1; cpu_rw = 0; cpu_addr = 32'h1000;
        #30 cpu_req = 0; 
        
        #20; // Give it some breathing room

        // --- TAKE YOUR SCREENSHOT FROM HERE ONWARD ---

        // PERFECT HIT 1: Read the data instantly
        cpu_req = 1; cpu_rw = 0; cpu_addr = 32'h1000;
        #10 cpu_req = 0;

        #20;

        // PERFECT HIT 2: Write new data instantly (Write-through)
        cpu_req = 1; cpu_rw = 1; cpu_addr = 32'h1000; cpu_wdata = 32'hAABBCCDD;
        #10 cpu_req = 0;

        #20;

        // PERFECT HIT 3: Read back the new data instantly
        cpu_req = 1; cpu_rw = 0; cpu_addr = 32'h1000;
        #10 cpu_req = 0;

        #50 $finish;
    end
endmodule
