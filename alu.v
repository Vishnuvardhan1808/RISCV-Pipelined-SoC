module alu (
    input  wire [31:0] a,          
    input  wire [31:0] b,          
    input  wire [3:0]  alu_ctrl,   
    output reg  [31:0] result,     
    output wire        zero,
    output wire        branch_taken  // <--- NEW: Flag for branching
);

    assign zero = (result == 32'b0);

    // NEW: If control is SUB (0001) and inputs are equal, assert branch_taken
    assign branch_taken = (alu_ctrl == 4'b0001) && (a == b);

    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b;                        // ADD / ADDI
            4'b0001: result = a - b;                        // SUB (also used for BEQ)
            4'b0010: result = a & b;                        // AND / ANDI
            4'b0011: result = a | b;                        // OR / ORI
            4'b0100: result = a ^ b;                        // XOR / XORI
            4'b0101: result = a << b[4:0];                  // SLL / SLLI
            4'b0110: result = a >> b[4:0];                  // SRL / SRLI
            4'b0111: result = $signed(a) >>> b[4:0];        // SRA / SRAI
            4'b1000: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT / SLTI
            default: result = 32'b0;
        endcase
    end

endmodule
