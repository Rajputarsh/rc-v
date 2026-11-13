
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

    reg [1:0] counters [0:15];
    reg [31:0] branches;
    reg [31:0] correct;

    wire [3:0] index;
    wire prediction;

    assign index = pc[5:2];
    assign prediction = counters[index][1];

    // Register read interface
    assign rdata = (sel && re) ?
        (ridx == 4'd0) ? branches :
        (ridx == 4'd1) ? correct :
        (ridx == 4'd15) ? 32'd58 :
        32'd0
        : 32'd0;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            branches <= 32'd0;
            correct <= 32'd0;

            for (i = 0; i < 16; i = i + 1)
                counters[i] <= 2'b01;
        end
        else if (sel && we && ridx == 4'd2) begin
            branches <= 32'd0;
            correct <= 32'd0;

            for (i = 0; i < 16; i = i + 1)
                counters[i] <= 2'b01;
        end
        else if (commit && is_branch) begin

            branches <= branches + 1'b1;

            if (prediction == taken)
                correct <= correct + 1'b1;

            if (taken) begin
                if (counters[index] != 2'b11)
                    counters[index] <= counters[index] + 1'b1;
            end
            else begin
                if (counters[index] != 2'b00)
                    counters[index] <= counters[index] - 1'b1;
            end
        end
    end

endmodule
