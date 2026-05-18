`timescale 1ns / 1ps

module control_unit (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] opcode,
    output reg  [2:0] state,
    output reg        ir_write,
    output reg        reg_write,
    output reg        mem_write,
    output reg        pc_write,
    output reg        alu_src_imm,
    output reg        result_src,
    output reg  [1:0] pc_src,
    output reg  [3:0] alu_op
);

    localparam ST_FETCH     = 3'd0;
    localparam ST_DECODE    = 3'd1;
    localparam ST_EXECUTE   = 3'd2;
    localparam ST_MEMORY    = 3'd3;
    localparam ST_WRITEBACK = 3'd4;
    localparam ST_HALT      = 3'd5;

    localparam OP_NOP   = 4'h0;
    localparam OP_ADD   = 4'h1;
    localparam OP_SUB   = 4'h2;
    localparam OP_AND   = 4'h3;
    localparam OP_OR    = 4'h4;
    localparam OP_XOR   = 4'h5;
    localparam OP_NOT   = 4'h6;
    localparam OP_LOAD  = 4'h7;
    localparam OP_STORE = 4'h8;
    localparam OP_JUMP  = 4'h9;
    localparam OP_BEQ   = 4'hA;
    localparam OP_ADDI  = 4'hB;
    localparam OP_HALT  = 4'hF;

    localparam ALU_ADD = 4'h0;
    localparam ALU_SUB = 4'h1;
    localparam ALU_AND = 4'h2;
    localparam ALU_OR  = 4'h3;
    localparam ALU_XOR = 4'h4;
    localparam ALU_NOT = 4'h5;

    localparam PC_INC    = 2'd0;
    localparam PC_BRANCH = 2'd1;
    localparam PC_JUMP   = 2'd2;

    reg [2:0] next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_FETCH;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            ST_FETCH: begin
                next_state = ST_DECODE;
            end

            ST_DECODE: begin
                if (opcode == OP_HALT) begin
                    next_state = ST_HALT;
                end else begin
                    next_state = ST_EXECUTE;
                end
            end

            ST_EXECUTE: begin
                case (opcode)
                    OP_LOAD,
                    OP_STORE: next_state = ST_MEMORY;

                    OP_ADD,
                    OP_SUB,
                    OP_AND,
                    OP_OR,
                    OP_XOR,
                    OP_NOT,
                    OP_ADDI: next_state = ST_WRITEBACK;

                    OP_NOP,
                    OP_JUMP,
                    OP_BEQ: next_state = ST_FETCH;

                    default: next_state = ST_FETCH;
                endcase
            end

            ST_MEMORY: begin
                if (opcode == OP_LOAD) begin
                    next_state = ST_WRITEBACK;
                end else begin
                    next_state = ST_FETCH;
                end
            end

            ST_WRITEBACK: begin
                next_state = ST_FETCH;
            end

            ST_HALT: begin
                next_state = ST_HALT;
            end

            default: begin
                next_state = ST_FETCH;
            end
        endcase
    end

    always @(*) begin
        ir_write   = 1'b0;
        reg_write  = 1'b0;
        mem_write  = 1'b0;
        pc_write   = 1'b0;
        alu_src_imm = 1'b0;
        result_src = 1'b0;
        pc_src     = PC_INC;
        alu_op     = ALU_ADD;

        case (opcode)
            OP_SUB:  alu_op = ALU_SUB;
            OP_AND:  alu_op = ALU_AND;
            OP_OR:   alu_op = ALU_OR;
            OP_XOR:  alu_op = ALU_XOR;
            OP_NOT:  alu_op = ALU_NOT;
            default: alu_op = ALU_ADD;
        endcase

        case (state)
            ST_FETCH: begin
                ir_write = 1'b1;
            end

            ST_EXECUTE: begin
                if ((opcode == OP_LOAD) || (opcode == OP_STORE) || (opcode == OP_ADDI)) begin
                    alu_src_imm = 1'b1;
                end

                if (opcode == OP_NOP) begin
                    pc_write = 1'b1;
                    pc_src = PC_INC;
                end else if (opcode == OP_JUMP) begin
                    pc_write = 1'b1;
                    pc_src = PC_JUMP;
                end else if (opcode == OP_BEQ) begin
                    pc_write = 1'b1;
                    pc_src = PC_BRANCH;
                end
            end

            ST_MEMORY: begin
                if (opcode == OP_STORE) begin
                    mem_write = 1'b1;
                    pc_write = 1'b1;
                    pc_src = PC_INC;
                end
            end

            ST_WRITEBACK: begin
                if (opcode == OP_LOAD) begin
                    result_src = 1'b1;
                end

                if ((opcode == OP_ADD)  || (opcode == OP_SUB)  ||
                    (opcode == OP_AND)  || (opcode == OP_OR)   ||
                    (opcode == OP_XOR)  || (opcode == OP_NOT)  ||
                    (opcode == OP_LOAD) || (opcode == OP_ADDI)) begin
                    reg_write = 1'b1;
                end

                pc_write = 1'b1;
                pc_src = PC_INC;
            end

            default: begin
            end
        endcase
    end

endmodule
