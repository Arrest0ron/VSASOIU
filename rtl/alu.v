`timescale 1ns / 1ps

module alu #(
    parameter WIDTH = 16
) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire [3:0]       alu_op,
    output reg  [WIDTH-1:0] result,
    output wire             zero
);

    localparam ALU_ADD = 4'h0;
    localparam ALU_SUB = 4'h1;
    localparam ALU_AND = 4'h2;
    localparam ALU_OR  = 4'h3;
    localparam ALU_XOR = 4'h4;
    localparam ALU_NOT = 4'h5;

    always @(*) begin
        case (alu_op)
            ALU_ADD: result = a + b;
            ALU_SUB: result = a - b;
            ALU_AND: result = a & b;
            ALU_OR:  result = a | b;
            ALU_XOR: result = a ^ b;
            ALU_NOT: result = ~a;
            default: result = {WIDTH{1'b0}};
        endcase
    end

    assign zero = (result == {WIDTH{1'b0}});

endmodule
