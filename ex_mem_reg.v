module ex_mem_reg (
    input  wire        clk,
    input  wire        reset,
    input  wire        stall_in,       // NEW: Freeze signal from Cache Miss
    
    // --- INPUTS FROM EXECUTE (EX) STAGE ---
    input  wire        ex_reg_write_en,
    input  wire        ex_mem_write,   // Store memory flag
    input  wire        ex_mem_to_reg,  // Load memory flag
    
    input  wire [31:0] ex_alu_result,
    input  wire [31:0] ex_rs2_data, 
    input  wire [4:0]  ex_rd,
    
    // --- OUTPUTS TO MEMORY (MEM) STAGE ---
    output reg         mem_reg_write_en,
    output reg         mem_write,      // Turns on Data RAM writes
    output reg         mem_to_reg,     // Passing Load flag to WB stage
    
    output reg  [31:0] mem_alu_result,
    output reg  [31:0] mem_rs2_data,
    output reg  [4:0]  mem_rd
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_reg_write_en <= 1'b0;
            mem_write        <= 1'b0; 
            mem_to_reg       <= 1'b0; 
            mem_alu_result   <= 32'b0;
            mem_rs2_data     <= 32'b0;
            mem_rd           <= 5'b0;
        end else if (!stall_in) begin // THE GLOBAL FREEZE CONDITION
            mem_reg_write_en <= ex_reg_write_en;
            mem_write        <= ex_mem_write;  
            mem_to_reg       <= ex_mem_to_reg; 
            mem_alu_result   <= ex_alu_result;
            mem_rs2_data     <= ex_rs2_data;
            mem_rd           <= ex_rd;
        end
        // Implicit else: If stall_in is 1, do nothing (registers retain current values)
    end

endmodule
