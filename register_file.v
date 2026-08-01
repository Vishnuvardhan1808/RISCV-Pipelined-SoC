module register_file (
    input  wire        clk,
    input  wire        we,         
    input  wire [4:0]  rs1,        
    input  wire [4:0]  rs2,        
    input  wire [4:0]  rd,         
    input  wire [31:0] write_data, 
    
    output wire [31:0] rs1_data,   
    output wire [31:0] rs2_data    
);

    reg [31:0] registers [31:0];

    // Asynchronous Combinational Reads
    assign rs1_data = (rs1 == 5'b0) ? 32'b0 : registers[rs1];
    assign rs2_data = (rs2 == 5'b0) ? 32'b0 : registers[rs2];

    // Synchronous Writes
    always @(posedge clk) begin
        if (we && (rd != 5'b0)) begin
            registers[rd] <= write_data;
        end
    end

endmodule
