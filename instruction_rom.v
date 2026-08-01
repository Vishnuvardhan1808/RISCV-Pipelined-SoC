module instruction_rom (
    input  wire [31:0] pc,
    output reg  [31:0] instr
);

    // Create a small ROM array (64 words of 32 bits)
    reg [31:0] rom [0:63];

        integer i;
    initial begin
        // Initialize with NOPs
        for (i = 0; i < 64; i = i + 1) begin
            rom[i] = 32'h00000013; // addi x0, x0, 0 (NOP)
        end
        
        // Load a simple test program:
        // Address 0x00: ADDI x1, x0, 5    (x1 = 5)
        rom[0] = 32'h00500093;
        // Address 0x04: ADDI x2, x0, 10   (x2 = 10)
        rom[1] = 32'h00a00113;
        // Address 0x08: ADD x3, x1, x2    (x3 = 15)
        rom[2] = 32'h002081b3;
        // Address 0x0C: SW x3, 0(x0)      (Store 15 to memory addr 0)
        rom[3] = 32'h00302023;
        // Address 0x10: LW x4, 0(x0)      (Load from memory addr 0 to x4)
        rom[4] = 32'h00002203; 
    end

    // Asynchronous read (ROM behavior)
    // The PC increments by 4, but our array is indexed by word (0, 1, 2, 3)
    // So we shift the PC right by 2 (divide by 4) to get the array index.
    always @(*) begin
        instr = rom[pc[31:2]];
    end

endmodule
