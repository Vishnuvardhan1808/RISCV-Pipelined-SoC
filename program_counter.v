module program_counter (
    input  wire        clk,
    input  wire        reset,
    input  wire        stall_in,    // <--- NEW: Freeze signal from Cache Miss
    input  wire        pc_write,    // 1 = update PC, 0 = freeze PC (hazard stall)
    input  wire        do_jump,     // Tells PC to jump
    input  wire [31:0] jump_target, // The address to jump to
    output reg  [31:0] pc
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Priority 1: Reset
            pc <= 32'b0;      // Start at memory address 0 on boot
        end else if (stall_in) begin
            // Priority 2: Cache Miss Global Freeze
            // PC completely freezes, ignoring branches and increments
        end else if (pc_write) begin  
            // Priority 3: Normal update (No hazard)
            if (do_jump) begin
                pc <= jump_target; // Branch taken! Jump to the target
            end else begin
                pc <= pc + 32'd4;  // Normal execution, go to next instruction
            end
        end
        // Implicit Priority 4: Hazard stall (pc_write == 0). 
        // PC holds its current value to fetch the same instruction again.
    end

endmodule
