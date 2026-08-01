`timescale 1ns / 1ps

module soc_top (
    input wire clk,
    input wire reset
);

    // --- Instruction Fetch Wires ---
    wire [31:0] pc;
    wire [31:0] instr;

    // --- CPU to Cache Wires ---
    wire        cpu_req;
    wire        cpu_rw;
    wire [31:0] cpu_addr;
    wire [31:0] cpu_wdata;
    wire [31:0] cpu_rdata;
    wire        cpu_stall;

    // --- Cache to Memory Wires ---
    wire         mem_req;
    wire         mem_rw;
    wire [31:0]  mem_addr;
    wire [127:0] mem_wdata;
    wire [127:0] mem_rdata;
    wire         mem_ready;

    // --- AXI4 Slave Wires ---
    wire s_axi_arready, s_axi_rvalid;
    wire [31:0] s_axi_rdata;
    wire s_axi_awready, s_axi_wready, s_axi_bvalid;

    // ---------------------------------------------------------
    // 1. Instruction ROM (Boot Memory)
    // ---------------------------------------------------------
    instruction_rom i_rom (
        .pc(pc),
        .instr(instr)
    );

    // ---------------------------------------------------------
    // 2. The 5-Stage Pipelined RISC-V CPU Core
    // ---------------------------------------------------------
    riscv_pipelined_core cpu (
        .clk(clk),
        .reset(reset),
        
        // Instruction Fetch Interface
        .pc(pc),
        .instr(instr),
        
        // Data Memory / Cache Interface
        .dmem_req(cpu_req),
        .dmem_rw(cpu_rw),
        .dmem_addr(cpu_addr),
        .dmem_wdata(cpu_wdata),
        .dmem_rdata(cpu_rdata),
        .stall_in(cpu_stall)
    );

    // ---------------------------------------------------------
    // 3. The Direct-Mapped Cache
    // ---------------------------------------------------------
    direct_mapped_cache d_cache (
        .clk(clk),
        .reset(reset),
        .cpu_req(cpu_req),
        .cpu_rw(cpu_rw),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .cpu_stall(cpu_stall),
        .mem_req(mem_req),
        .mem_rw(mem_rw),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );

    // ---------------------------------------------------------
    // 4. AXI4 Bridge Logic (Translates Cache -> AXI)
    // ---------------------------------------------------------
    // AXI Read Channel
    wire s_axi_arvalid = (mem_req && !mem_rw);
    wire s_axi_rready  = 1'b1; // Always ready to receive read data

    // AXI Write Channel
    wire s_axi_awvalid = (mem_req && mem_rw);
    wire s_axi_wvalid  = (mem_req && mem_rw);
    wire s_axi_bready  = 1'b1; // Always ready to receive write response

    // Map AXI outputs back to the Cache's simplified interface
    assign mem_rdata = {96'b0, s_axi_rdata}; // Pad 32-bit AXI data to 128-bit cache line
    assign mem_ready = (mem_req && !mem_rw) ? s_axi_rvalid : 
                       (mem_req && mem_rw)  ? s_axi_bvalid : 1'b0;

    // ---------------------------------------------------------
    // 5. The AXI4 Memory Controller (RAM)
    // ---------------------------------------------------------
    axi4_memory_controller main_memory (
        .clk(clk),
        .reset(reset),
        
        // AXI Read
        .s_axi_araddr(mem_addr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        
        // AXI Write
        .s_axi_awaddr(mem_addr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(mem_wdata[31:0]),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready)
    );

endmodule
