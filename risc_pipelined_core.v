module riscv_pipelined_core (
    input  wire        clk,
    input  wire        reset,
    
    // --- Instruction Memory Interface ---
    output wire [31:0] pc,
    input  wire [31:0] instr,

    // --- NEW: Data Memory (Cache) Interface ---
    output wire        dmem_req,
    output wire        dmem_rw,     // 0 = Read, 1 = Write
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    input  wire [31:0] dmem_rdata,
    input  wire        stall_in     // FROM CACHE: Global freeze signal
);

    // ==========================================
    // --- GLOBAL FLUSH & BRANCH SIGNALS ---
    // ==========================================
    wire        do_flush;
    wire [31:0] branch_target;

    // ==========================================
    // --- HAZARD DETECTION SIGNALS ---
    // ==========================================
    wire pc_write;
    wire if_id_write;
    wire stall_bubble;

    // ==========================================
    // STAGE 1: INSTRUCTION FETCH (IF)
    // ==========================================
    wire [31:0] if_pc;
    
    program_counter pc_inst (
        .clk(clk), 
        .reset(reset), 
        .stall_in(stall_in),         // <--- NEW: Global Cache Freeze
        .pc_write(pc_write),         
        .do_jump(do_flush),          
        .jump_target(branch_target), 
        .pc(if_pc)
    );
    assign pc = if_pc; 

    wire [31:0] id_pc, id_instr;
    if_id_reg if_id_inst (
        .clk(clk), .reset(reset), 
        .stall_in(stall_in),         // <--- NEW: Global Cache Freeze
        .flush(do_flush), 
        .if_id_write(if_id_write),   
        .if_pc(if_pc), .if_instr(instr), 
        .id_pc(id_pc), .id_instr(id_instr)
    );

    // ==========================================
    // STAGE 2: INSTRUCTION DECODE (ID)
    // ==========================================
    wire [6:0] opcode, funct7;
    wire [4:0] id_rd, id_rs1, id_rs2;
    wire [2:0] funct3;
    
    wire       id_reg_write_en, id_alu_src, id_mem_write, id_mem_read, id_mem_to_reg, id_is_branch; 
    wire [3:0] id_alu_ctrl;

    riscv_decoder decoder_inst (
        .instr(id_instr), .opcode(opcode), .rd(id_rd), .funct3(funct3), 
        .rs1(id_rs1), .rs2(id_rs2), .funct7(funct7),
        .reg_write_en(id_reg_write_en), .alu_src(id_alu_src), .alu_ctrl(id_alu_ctrl),
        .mem_write(id_mem_write), .mem_read(id_mem_read), .mem_to_reg(id_mem_to_reg), 
        .is_branch(id_is_branch) 
    );

    wire [31:0] id_imm_out;
    imm_gen imm_gen_inst (.instr(id_instr), .imm_out(id_imm_out));

    wire [31:0] id_rs1_data, id_rs2_data;
    wire        wb_reg_write_en;
    wire [4:0]  wb_rd;
    wire [31:0] wb_final_data;

    register_file regfile_inst (
        .clk(clk), .we(wb_reg_write_en), .rs1(id_rs1), .rs2(id_rs2), 
        .rd(wb_rd), .write_data(wb_final_data), 
        .rs1_data(id_rs1_data), .rs2_data(id_rs2_data)
    );

    // --- ID/EX PIPELINE REGISTER ---
    wire        ex_reg_write_en, ex_alu_src, ex_mem_write, ex_mem_read, ex_mem_to_reg, ex_is_branch; 
    wire [3:0]  ex_alu_ctrl;
    wire [31:0] ex_pc, ex_rs1_data, ex_rs2_data, ex_imm_out;
    wire [4:0]  ex_rs1, ex_rs2, ex_rd;

    id_ex_reg id_ex_inst (
        .clk(clk), .reset(reset), 
        .stall_in(stall_in),         // <--- NEW: Global Cache Freeze
        .flush(do_flush), 
        .stall_bubble(stall_bubble), 
        
        .id_reg_write_en(id_reg_write_en), .id_alu_src(id_alu_src), .id_alu_ctrl(id_alu_ctrl),
        .id_mem_write(id_mem_write), .id_mem_read(id_mem_read), .id_mem_to_reg(id_mem_to_reg), 
        .id_is_branch(id_is_branch),                                
        .id_pc(id_pc), .id_rs1_data(id_rs1_data), .id_rs2_data(id_rs2_data), .id_imm_out(id_imm_out),
        .id_rs1(id_rs1), .id_rs2(id_rs2), .id_rd(id_rd),
        
        .ex_reg_write_en(ex_reg_write_en), .ex_alu_src(ex_alu_src), .ex_alu_ctrl(ex_alu_ctrl),
        .ex_mem_write(ex_mem_write), .ex_mem_read(ex_mem_read), .ex_mem_to_reg(ex_mem_to_reg), 
        .ex_is_branch(ex_is_branch),                                
        .ex_pc(ex_pc), .ex_rs1_data(ex_rs1_data), .ex_rs2_data(ex_rs2_data), .ex_imm_out(ex_imm_out),
        .ex_rs1(ex_rs1), .ex_rs2(ex_rs2), .ex_rd(ex_rd)
    );

    // ==========================================
    // --- HAZARD DETECTION UNIT INST ---
    // ==========================================
    hazard_detection_unit hazard_inst (
        .if_id_rs1(id_rs1),           
        .if_id_rs2(id_rs2),           
        .id_ex_rd(ex_rd),             
        .id_ex_mem_read(ex_mem_read), 
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .stall_bubble(stall_bubble)
    );

    // ==========================================
    // STAGE 3: EXECUTE (EX)
    // ==========================================
    wire [1:0] forward_a, forward_b;
    wire       mem_reg_write_en, mem_write, mem_to_reg;
    wire [4:0] mem_rd;
    wire [31:0] mem_alu_result;

    forwarding_unit fwd_inst (
        .id_ex_rs1(ex_rs1), .id_ex_rs2(ex_rs2),
        .ex_mem_rd(mem_rd), .ex_mem_reg_write_en(mem_reg_write_en),
        .mem_wb_rd(wb_rd), .mem_wb_reg_write_en(wb_reg_write_en),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    reg [31:0] alu_in_a, forwarded_b;
    always @(*) begin
        case (forward_a)
            2'b00: alu_in_a = ex_rs1_data;
            2'b10: alu_in_a = mem_alu_result; 
            2'b01: alu_in_a = wb_final_data; 
            default: alu_in_a = ex_rs1_data;
        endcase
        case (forward_b)
            2'b00: forwarded_b = ex_rs2_data;
            2'b10: forwarded_b = mem_alu_result; 
            2'b01: forwarded_b = wb_final_data;  
            default: forwarded_b = ex_rs2_data;
        endcase
    end

    wire [31:0] alu_in_b = ex_alu_src ? ex_imm_out : forwarded_b;
    wire [31:0] ex_alu_result;
    wire        ex_zero, ex_branch_taken; 

    alu alu_inst (
        .a(alu_in_a), .b(alu_in_b), .alu_ctrl(ex_alu_ctrl), 
        .result(ex_alu_result), .zero(ex_zero), 
        .branch_taken(ex_branch_taken)    
    );

    // --- BRANCH LOGIC ---
    assign branch_target = ex_pc + ex_imm_out;
    assign do_flush = ex_is_branch & ex_branch_taken;

    // --- EX/MEM PIPELINE REGISTER ---
    wire [31:0] mem_rs2_data;

    ex_mem_reg ex_mem_inst (
        .clk(clk), .reset(reset),
        .stall_in(stall_in),         // <--- NEW: Global Cache Freeze
        .ex_reg_write_en(ex_reg_write_en), .ex_mem_write(ex_mem_write), .ex_mem_to_reg(ex_mem_to_reg),
        .ex_alu_result(ex_alu_result), .ex_rs2_data(forwarded_b), .ex_rd(ex_rd),
        
        .mem_reg_write_en(mem_reg_write_en), .mem_write(mem_write), .mem_to_reg(mem_to_reg),
        .mem_alu_result(mem_alu_result), .mem_rs2_data(mem_rs2_data), .mem_rd(mem_rd)
    );

    // ==========================================
    // STAGE 4: MEMORY (MEM)
    // ==========================================
    
    // --- CACHE INTERFACE MAPPING ---
    // Instead of using internal RAM, we send these signals out to the Direct Mapped Cache
    
    // Request cache access if it's a Load (mem_to_reg) or Store (mem_write)
    assign dmem_req   = mem_write | mem_to_reg; 
    
    // 1 for Store, 0 for Load
    assign dmem_rw    = mem_write;                  
    
    // Calculated ALU address
    assign dmem_addr  = mem_alu_result;                
    
    // Data to store
    assign dmem_wdata = mem_rs2_data;                
    
    // Data returning from cache
    wire [31:0] mem_read_data = dmem_rdata; 

    // --- MEM/WB PIPELINE REGISTER ---
    wire        wb_mem_to_reg;
    wire [31:0] wb_alu_result, wb_read_data;

    mem_wb_reg mem_wb_inst (
        .clk(clk), .reset(reset),
        .stall_in(stall_in),         // <--- NEW: Global Cache Freeze
        .mem_reg_write_en(mem_reg_write_en), .mem_to_reg(mem_to_reg), 
        .mem_alu_result(mem_alu_result), .mem_read_data(mem_read_data), .mem_rd(mem_rd),
        
        .wb_reg_write_en(wb_reg_write_en), .wb_mem_to_reg(wb_mem_to_reg), 
        .wb_alu_result(wb_alu_result), .wb_read_data(wb_read_data), .wb_rd(wb_rd)
    );

    // ==========================================
    // STAGE 5: WRITEBACK (WB)
    // ==========================================
    assign wb_final_data = wb_mem_to_reg ? wb_read_data : wb_alu_result;

endmodule
