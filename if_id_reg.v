module if_id_reg (
    input  wire        clk,
    input  wire        reset,
    input  wire        stall_in,    // <--- NEW: Freeze signal from Cache Miss
    input  wire        flush,       // Flush signal to erase bad instructions
    input  wire        if_id_write, // 1 = update, 0 = freeze (hazard stall)
    
    // Inputs from Fetch (IF) Stage
    input  wire [31:0] if_pc,
    input  wire [31:0] if_instr,
    
    // Outputs to Decode (ID) Stage
    output reg  [31:0] id_pc,
    output reg  [31:0] id_instr
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Priority 1: Reset
            id_pc    <= 32'b0;
            id_instr <= 32'h00000013; // Safe NOP instruction (addi x0, x0, 0)
        end else if (stall_in) begin
            // Priority 2: Cache Miss Global Freeze
            // Do nothing. Retain exact state until memory returns.
        end else if (flush) begin
            // Priority 3: Branch Flush
            // Flush overrides hazard stall: turn the instruction into a NOP
            id_pc    <= 32'b0;
            id_instr <= 32'h00000013; // Safe NOP instruction (addi x0, x0, 0)
        end else if (if_id_write) begin
            // Priority 4: Normal update (No hazard)
            id_pc    <= if_pc;
            id_instr <= if_instr;
        end
        // Implicit Priority 5: Hazard stall (if_id_write == 0 and no flush). 
        // Retains values to give the hazard time to resolve.
    end

endmodule
