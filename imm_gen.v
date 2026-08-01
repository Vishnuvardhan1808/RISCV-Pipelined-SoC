module imm_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm_out
);
    
    wire [6:0] opcode = instr[6:0];

    always @(*) begin
        case (opcode)
            // --- I-Type (ALU Imm & Loads) ---
            7'b0010011, 
            7'b0000011: begin
                imm_out = {{20{instr[31]}}, instr[31:20]};
            end
            
            // --- S-Type (Stores like sw) ---
            7'b0100011: begin
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
            
            // --- B-Type (Branches like beq) ---
            // RISC-V scrambles branch bits to match S-type hardware layouts.
            // Note: The lowest bit (bit 0) is always a hardcoded 0 because 
            // instructions are always half-word or word aligned (multiples of 2 or 4).
            7'b1100011: begin
                imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            
            default: begin
                imm_out = 32'b0;
            end
        endcase
    end

endmodule
