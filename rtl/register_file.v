`timescale 1ns / 1ps

module register_file #(
    parameter WIDTH = 16,
    parameter ADDR_WIDTH = 3
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] raddr1,
    input  wire [ADDR_WIDTH-1:0] raddr2,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire [WIDTH-1:0]      wdata,
    output wire [WIDTH-1:0]      rdata1,
    output wire [WIDTH-1:0]      rdata2,
    output wire [WIDTH-1:0]      debug_r0,
    output wire [WIDTH-1:0]      debug_r1,
    output wire [WIDTH-1:0]      debug_r2,
    output wire [WIDTH-1:0]      debug_r3,
    output wire [WIDTH-1:0]      debug_r4,
    output wire [WIDTH-1:0]      debug_r5,
    output wire [WIDTH-1:0]      debug_r6,
    output wire [WIDTH-1:0]      debug_r7
);

    reg [WIDTH-1:0] regs [0:7];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                regs[i] <= {WIDTH{1'b0}};
            end
        end else if (we && (waddr != {ADDR_WIDTH{1'b0}})) begin
            regs[waddr] <= wdata;
        end
    end

    assign rdata1 = (raddr1 == {ADDR_WIDTH{1'b0}}) ? {WIDTH{1'b0}} : regs[raddr1];
    assign rdata2 = (raddr2 == {ADDR_WIDTH{1'b0}}) ? {WIDTH{1'b0}} : regs[raddr2];

    assign debug_r0 = {WIDTH{1'b0}};
    assign debug_r1 = regs[1];
    assign debug_r2 = regs[2];
    assign debug_r3 = regs[3];
    assign debug_r4 = regs[4];
    assign debug_r5 = regs[5];
    assign debug_r6 = regs[6];
    assign debug_r7 = regs[7];

endmodule
