module riscv_decoder (
    input  wire [31:0] instr,
    output wire [6:0]  opcode,
    output wire [4:0]  rd,
    output wire [2:0]  funct3,
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,
    output wire [6:0]  funct7,
    output reg         reg_write_en,
    output reg         alu_src,
    output reg  [3:0]  alu_ctrl,
    output reg         mem_write,
    output reg         mem_read,    // <--- NEW: 1 for Load (lw)
    output reg         mem_to_reg,
    output reg         is_branch    // 1 for Branch (beq)
);

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    always @(*) begin
        // Default values
        reg_write_en = 1'b0;
        alu_src      = 1'b0;
        alu_ctrl     = 4'b0000;
        mem_write    = 1'b0;
        mem_read     = 1'b0;        // <--- NEW: Default to 0
        mem_to_reg   = 1'b0;
        is_branch    = 1'b0;        

        case (opcode)
            7'b0110011: begin // R-Type (add, sub)
                reg_write_en = 1'b1;
                alu_src      = 1'b0;
                // 0001 for Sub, 0000 for Add
                alu_ctrl     = (funct7 == 7'b0100000) ? 4'b0001 : 4'b0000;
            end
            7'b0010011: begin // I-Type (addi)
                reg_write_en = 1'b1;
                alu_src      = 1'b1;
                alu_ctrl     = 4'b0000; // Add
            end
            7'b0000011: begin // Load (lw)
                reg_write_en = 1'b1;
                alu_src      = 1'b1;    // ALU adds base + imm
                alu_ctrl     = 4'b0000; // Add
                mem_read     = 1'b1;    // <--- NEW: Tell pipeline we are reading RAM
                mem_to_reg   = 1'b1;    // Route RAM to Register
            end
            7'b0100011: begin // Store (sw)
                alu_src      = 1'b1;    // ALU adds base + imm
                alu_ctrl     = 4'b0000; // Add
                mem_write    = 1'b1;    // Turn on RAM Write
            end
            7'b1100011: begin // Branch (beq) 
                alu_src      = 1'b0;    // Compare rs1 and rs2
                alu_ctrl     = 4'b0001; // Subtract (matches your R-type logic!)
                is_branch    = 1'b1;    // Tell the pipeline we are branching
            end
        endcase
    end
endmodule
