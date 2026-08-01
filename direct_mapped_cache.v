module direct_mapped_cache (
    input  wire         clk,
    input  wire         reset,

    // --- CPU Interface ---
    input  wire         cpu_req,    
    input  wire         cpu_rw,     // 0 = Read, 1 = Write
    input  wire [31:0]  cpu_addr,   
    input  wire [31:0]  cpu_wdata,  
    output reg  [31:0]  cpu_rdata,  
    output reg          cpu_stall,  

    // --- Main Memory Interface (Pre-AXI Bridge) ---
    output reg          mem_req,    
    output reg          mem_rw,     
    output reg  [31:0]  mem_addr,   
    output reg  [127:0] mem_wdata,  
    input  wire [127:0] mem_rdata,  
    input  wire         mem_ready   
);

    // Address Slicing
    wire [3:0]  offset = cpu_addr[3:0];  
    wire [3:0]  index  = cpu_addr[7:4];  
    wire [23:0] tag    = cpu_addr[31:8]; 

    // Cache Internal SRAM
    reg         valid_array [0:15];      
    reg [23:0]  tag_array   [0:15];      
    reg [127:0] data_array  [0:15];      

    // Hit Logic
    wire is_hit = (cpu_req) && (valid_array[index] == 1'b1) && (tag_array[index] == tag);

    // FSM States
    localparam IDLE  = 1'b0;
    localparam FETCH = 1'b1;
    reg state;

    integer i;

    // Sequential Logic (FSM & Cache Updates)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            for (i = 0; i < 16; i = i + 1) begin
                valid_array[i] <= 1'b0; // Clear cache on reset
            end
        end else begin
            case (state)
                IDLE: begin
                    if (cpu_req) begin
                        if (cpu_rw == 1'b1) begin
                            // Write-Through: Update cache on a hit
                            if (is_hit) begin
                                // Simplified: Assumes writing to the lowest 32 bits of the block
                                data_array[index][31:0] <= cpu_wdata; 
                            end
                        end else if (!is_hit) begin
                            state <= FETCH; // Read Miss: Go to memory
                        end
                    end
                end
                
                FETCH: begin
                    if (mem_ready) begin
                        // Block fetched from memory, update cache
                        valid_array[index] <= 1'b1;
                        tag_array[index]   <= tag;
                        data_array[index]  <= mem_rdata; 
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    // Combinational Logic (Outputs to CPU and Memory)
    always @(*) begin
        cpu_stall = 1'b0;
        mem_req   = 1'b0;
        mem_addr  = 32'b0;
        mem_rw    = 1'b0;
        cpu_rdata = 32'b0;
        mem_wdata = 128'b0;

        case (state)
            IDLE: begin
                if (cpu_req) begin
                    if (cpu_rw == 1'b0) begin
                        if (is_hit) begin
                            cpu_stall = 1'b0;
                            cpu_rdata = data_array[index][31:0]; 
                        end else begin
                            // Read Miss
                            cpu_stall = 1'b1;
                            mem_req   = 1'b1;
                            mem_rw    = 1'b0;
                            mem_addr  = {tag, index, 4'b0000}; 
                        end
                    end else begin
                        // Write-Through to Memory
                        mem_req   = 1'b1;
                        mem_rw    = 1'b1;
                        mem_addr  = cpu_addr;
                        mem_wdata = {96'b0, cpu_wdata}; // Simplified write alignment
                    end
                end
            end 
            
            FETCH: begin
                cpu_stall = 1'b1;
                mem_req   = 1'b1;
                mem_addr  = {tag, index, 4'b0000};
            end
        endcase
    end
endmodule
