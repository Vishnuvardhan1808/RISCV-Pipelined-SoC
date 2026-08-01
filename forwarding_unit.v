module forwarding_unit (
    // Inputs from the ID/EX stage (What the ALU needs right now)
    input  wire [4:0] id_ex_rs1,
    input  wire [4:0] id_ex_rs2,
    
    // Inputs from the EX/MEM stage (Data just calculated)
    input  wire [4:0] ex_mem_rd,
    input  wire       ex_mem_reg_write_en,
    
    // Inputs from the MEM/WB stage (Data about to be written back)
    input  wire [4:0] mem_wb_rd,
    input  wire       mem_wb_reg_write_en,
    
    // Outputs controlling the ALU input multiplexers
    // 00 = Normal data from Register File
    // 10 = Forward from EX/MEM stage
    // 01 = Forward from MEM/WB stage
    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);

    always @(*) begin
        // --- DEFAULT: No forwarding ---
        forward_a = 2'b00;
        forward_b = 2'b00;

        // --- FORWARD A LOGIC (For ALU Input A) ---
        // 1st Priority: EX Hazard (Most recent instruction)
        if (ex_mem_reg_write_en && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b10;
        end
        // 2nd Priority: MEM Hazard (Older instruction)
        else if (mem_wb_reg_write_en && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs1)) begin
            forward_a = 2'b01;
        end

        // --- FORWARD B LOGIC (For ALU Input B) ---
        // 1st Priority: EX Hazard
        if (ex_mem_reg_write_en && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end
        // 2nd Priority: MEM Hazard
        else if (mem_wb_reg_write_en && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs2)) begin
            forward_b = 2'b01;
        end
    end

endmodule
