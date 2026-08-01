module id_ex_reg (
    input  wire        clk,
    input  wire        reset,
    input  wire        stall_in,       // <--- NEW: Freeze signal from Cache Miss
    input  wire        flush,          // Flush signal to erase bad instructions
    input  wire        stall_bubble,   // Injects a NOP when stalled

    // --- INPUTS FROM DECODE (ID) STAGE ---
    input  wire        id_reg_write_en,
    input  wire        id_alu_src,
    input  wire [3:0]  id_alu_ctrl,
    input  wire        id_mem_write,
    input  wire        id_mem_read,    
    input  wire        id_mem_to_reg,
    input  wire        id_is_branch,   

    input  wire [31:0] id_pc,
    input  wire [31:0] id_rs1_data,
    input  wire [31:0] id_rs2_data,
    input  wire [31:0] id_imm_out,

    input  wire [4:0]  id_rs1,
    input  wire [4:0]  id_rs2,
    input  wire [4:0]  id_rd,

    // --- OUTPUTS TO EXECUTE (EX) STAGE ---
    output reg         ex_reg_write_en,
    output reg         ex_alu_src,
    output reg  [3:0]  ex_alu_ctrl,
    output reg         ex_mem_write,
    output reg         ex_mem_read,    
    output reg         ex_mem_to_reg,
    output reg         ex_is_branch,   

    output reg  [31:0] ex_pc,
    output reg  [31:0] ex_rs1_data,
    output reg  [31:0] ex_rs2_data,
    output reg  [31:0] ex_imm_out,

    output reg  [4:0]  ex_rs1,
    output reg  [4:0]  ex_rs2,
    output reg  [4:0]  ex_rd
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin 
            // 1. Highest Priority: Reset clears everything
            ex_reg_write_en <= 1'b0;
            ex_alu_src      <= 1'b0;
            ex_alu_ctrl     <= 4'b0000;
            ex_mem_write    <= 1'b0;
            ex_mem_read     <= 1'b0;   
            ex_mem_to_reg   <= 1'b0;
            ex_is_branch    <= 1'b0;   
            ex_pc           <= 32'b0;
            ex_rs1_data     <= 32'b0;
            ex_rs2_data     <= 32'b0;
            ex_imm_out      <= 32'b0;
            ex_rs1          <= 5'b0;
            ex_rs2          <= 5'b0;
            ex_rd           <= 5'b0;
        end else if (stall_in) begin
            // 2. Second Priority: Cache Miss! 
            // Do absolutely nothing. Retain all current register values.
        end else if (flush || stall_bubble) begin
            // 3. Third Priority: Hazard or Branch Flush
            // Clear control signals to 0 (inject NOP)
            ex_reg_write_en <= 1'b0;
            ex_alu_src      <= 1'b0;
            ex_alu_ctrl     <= 4'b0000;
            ex_mem_write    <= 1'b0;
            ex_mem_read     <= 1'b0;
            ex_mem_to_reg   <= 1'b0;
            ex_is_branch    <= 1'b0;   
            // Data path can retain old values, but we'll clear PC to be safe
            ex_pc           <= 32'b0;
        end else begin
            // 4. Normal Operation: Move data down the pipeline
            ex_reg_write_en <= id_reg_write_en;
            ex_alu_src      <= id_alu_src;
            ex_alu_ctrl     <= id_alu_ctrl;
            ex_mem_write    <= id_mem_write;
            ex_mem_read     <= id_mem_read; 
            ex_mem_to_reg   <= id_mem_to_reg;
            ex_is_branch    <= id_is_branch; 
            ex_pc           <= id_pc;
            ex_rs1_data     <= id_rs1_data;
            ex_rs2_data     <= id_rs2_data;
            ex_imm_out      <= id_imm_out;
            ex_rs1          <= id_rs1;
            ex_rs2          <= id_rs2;
            ex_rd           <= id_rd;
        end
    end

endmodule
