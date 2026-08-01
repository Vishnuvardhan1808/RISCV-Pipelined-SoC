module axi4_memory_controller (
    input  wire         clk,
    input  wire         reset,

    // --- AXI4 Read Address Channel (AR) ---
    input  wire [31:0]  s_axi_araddr,
    input  wire         s_axi_arvalid,
    output reg          s_axi_arready,

    // --- AXI4 Read Data Channel (R) ---
    output reg  [31:0]  s_axi_rdata, // Note: Scaled to 32-bit for simplicity
    output reg          s_axi_rvalid,
    input  wire         s_axi_rready,

    // --- AXI4 Write Address Channel (AW) ---
    input  wire [31:0]  s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,

    // --- AXI4 Write Data Channel (W) ---
    input  wire [31:0]  s_axi_wdata,
    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,

    // --- AXI4 Write Response Channel (B) ---
    output reg          s_axi_bvalid,
    input  wire         s_axi_bready
);

    // 1KB Block RAM to act as Main Memory
    reg [31:0] ram [0:255]; 
    reg [31:0] read_addr;
    reg [31:0] write_addr;

    // ---------------------------------------------------------
    // AXI4 Read FSM
    // ---------------------------------------------------------
    localparam R_IDLE = 1'b0, R_SEND = 1'b1;
    reg r_state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_state       <= R_IDLE;
            s_axi_arready <= 1'b1; // Always ready to accept an address initially
            s_axi_rvalid  <= 1'b0;
        end else begin
            case (r_state)
                R_IDLE: begin
                    if (s_axi_arvalid && s_axi_arready) begin
                        read_addr     <= s_axi_araddr;
                        s_axi_arready <= 1'b0; // Stop accepting addresses
                        s_axi_rvalid  <= 1'b1; // Data will be valid next cycle
                        s_axi_rdata   <= ram[s_axi_araddr[9:2]]; // Read from RAM (word aligned)
                        r_state       <= R_SEND;
                    end
                end
                R_SEND: begin
                    if (s_axi_rvalid && s_axi_rready) begin // Handshake complete
                        s_axi_rvalid  <= 1'b0;
                        s_axi_arready <= 1'b1; // Ready for next address
                        r_state       <= R_IDLE;
                    end
                end
            endcase
        end
    end

    // ---------------------------------------------------------
    // AXI4 Write FSM
    // ---------------------------------------------------------
    localparam W_IDLE = 2'b00, W_DATA = 2'b01, W_RESP = 2'b10;
    reg [1:0] w_state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            w_state       <= W_IDLE;
            s_axi_awready <= 1'b1;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
        end else begin
            case (w_state)
                W_IDLE: begin // Wait for Write Address
                    if (s_axi_awvalid && s_axi_awready) begin
                        write_addr    <= s_axi_awaddr;
                        s_axi_awready <= 1'b0;
                        s_axi_wready  <= 1'b1; // Ready to accept data
                        w_state       <= W_DATA;
                    end
                end
                W_DATA: begin // Wait for Write Data
                    if (s_axi_wvalid && s_axi_wready) begin
                        ram[write_addr[9:2]] <= s_axi_wdata; // Write to RAM
                        s_axi_wready  <= 1'b0;
                        s_axi_bvalid  <= 1'b1; // Send write response
                        w_state       <= W_RESP;
                    end
                end
                W_RESP: begin // Wait for master to acknowledge response
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid  <= 1'b0;
                        s_axi_awready <= 1'b1; // Ready for next transaction
                        w_state       <= W_IDLE;
                    end
                end
            endcase
        end
    end
endmodule
