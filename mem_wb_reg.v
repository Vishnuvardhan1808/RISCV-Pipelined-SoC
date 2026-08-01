module mem_wb_reg (
    input  wire        clk,
    input  wire        reset,
    input  wire        stall_in,        // <--- NEW: Freeze signal from Cache Miss
    
    // --- INPUTS FROM MEMORY (MEM) STAGE ---
    input  wire        mem_reg_write_en,
    input  wire        mem_to_reg,      // Load memory flag
    input  wire [31:0] mem_alu_result,
    input  wire [31:0] mem_read_data,   // Data loaded from Data RAM/Cache
    input  wire [4:0]  mem_rd,
    
    // --- OUTPUTS TO WRITEBACK (WB) STAGE ---
    output reg         wb_reg_write_en,
    output reg         wb_mem_to_reg,   // Tells WB multiplexer what to choose
    output reg  [31:0] wb_alu_result,
    output reg  [31:0] wb_read_data,    // Passing loaded data to WB
    output reg  [4:0]  wb_rd
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wb_reg_write_en <= 1'b0;
            wb_mem_to_reg   <= 1'b0;  
            wb_alu_result   <= 32'b0;
            wb_read_data    <= 32'b0; 
            wb_rd           <= 5'b0;
        end else if (!stall_in) begin   // <--- NEW: THE GLOBAL FREEZE CONDITION
            wb_reg_write_en <= mem_reg_write_en;
            wb_mem_to_reg   <= mem_to_reg;     
            wb_alu_result   <= mem_alu_result;
            wb_read_data    <= mem_read_data;  
            wb_rd           <= mem_rd;
        end
        // Implicit else: If stall_in is 1, do nothing (registers retain current values)
    end

endmodule
