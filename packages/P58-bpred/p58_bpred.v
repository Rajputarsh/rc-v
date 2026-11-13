module p58_bpred (
    input  wire clk,
    input  wire rst,
    input  wire sel,
    input  wire we,
    input  wire re,
    input  wire [3:0] ridx,
    input  wire [31:0] wdata,
    output wire [31:0] rdata,
    input  wire commit,
    input  wire is_branch,
    input  wire taken,
    input  wire [31:0] pc
);

    reg [1:0]  ctr [0:15];      // 16 two-bit counters
    reg [31:0] branches;        // how many branches were counted
    reg [31:0] correct;         // how many were predicted right
    reg [31:0] rd;              // value sent to rdata

    wire [3:0] i   = pc[5:2];   // which counter this branch uses
    wire [1:0] cur = ctr[i];    // that counter's value
    wire pred = cur[1];         // top bit: 1 means predict taken
    wire upd  = commit & is_branch;

    integer k;

    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k < 16; k = k + 1) ctr[k] <= 2'b00;
            branches <= 32'd0;
            correct  <= 32'd0;
        end else begin
            // CLEAR register (assumed number 2): clears the counts only
            if (sel && we && ridx == 4'd2) begin
                branches <= 32'd0;
                correct  <= 32'd0;
            end else if (upd) begin
                branches <= branches + 32'd1;
                if (pred == taken) correct <= correct + 32'd1;
            end
            // learn from the branch
            if (upd) begin
                if (taken) begin
                    if (cur != 2'b11) ctr[i] <= cur + 2'b01;
                end else begin
                    if (cur != 2'b00) ctr[i] <= cur - 2'b01;
                end
            end
        end
    end

    always @* begin
        rd = 32'd0;
        if (sel && re) begin
            case (ridx)
                4'd0:  rd = branches;
                4'd1:  rd = correct;
                4'd15: rd = 32'd58;
                default: rd = 32'd0;
            endcase
        end
    end

    assign rdata = rd;

endmodule
