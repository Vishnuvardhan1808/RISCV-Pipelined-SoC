module hazard_detection_unit (
    input  wire [4:0] if_id_rs1,       // Source register 1 from Fetch/Decode instruction
    input  wire [4:0] if_id_rs2,       // Source register 2 from Fetch/Decode instruction
    input  wire [4:0] id_ex_rd,        // Destination register of instruction in EX stage
    input  wire       id_ex_mem_read,  // Asserted if instruction in EX is a Load (e.g., lw)
    
    output reg        pc_write,        // 1: Enable PC update, 0: Freeze PC
    output reg        if_id_write,     // 1: Enable IF/ID register update, 0: Freeze IF/ID
    output reg        stall_bubble     // 1: Inject NOP/bubble into ID/EX, 0: Normal operation
);

    always @(*) begin
        // By default, the pipeline flows normally
        pc_write     = 1'b1;
        if_id_write  = 1'b1;
        stall_bubble = 1'b0;

        // --- Load-Use Hazard Condition ---
        // 1. The instruction in EX is reading from memory (lw)
        // 2. The destination register is not x0 (x0 is hardwired to 0, no need to stall)
        // 3. The destination register matches either of the source registers in ID stage
        if (id_ex_mem_read && (id_ex_rd != 5'b0) && 
           ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))) begin
            
            pc_write     = 1'b0;  // Freeze Program Counter
            if_id_write  = 1'b0;  // Freeze IF/ID Pipeline Register
            stall_bubble = 1'b1;  // Inject a bubble (NOP) into ID/EX control bits
        end
    end

endmodule
