`timescale 1ns / 1ps

module processor_core #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 8,
    parameter IMEM_SIZE = 256,
    parameter DMEM_SIZE = 256
) (
    input  wire                  clk,
    input  wire                  rst,
    output wire                  halted,
    output wire [ADDR_WIDTH-1:0] pc,
    output wire [DATA_WIDTH-1:0] instr,
    output wire [2:0]            state,
    output wire [DATA_WIDTH-1:0] debug_r0,
    output wire [DATA_WIDTH-1:0] debug_r1,
    output wire [DATA_WIDTH-1:0] debug_r2,
    output wire [DATA_WIDTH-1:0] debug_r3,
    output wire [DATA_WIDTH-1:0] debug_r4,
    output wire [DATA_WIDTH-1:0] debug_r5,
    output wire [DATA_WIDTH-1:0] debug_r6,
    output wire [DATA_WIDTH-1:0] debug_r7
);

    localparam ST_EXECUTE = 3'd2;
    localparam ST_MEMORY = 3'd3;
    localparam ST_HALT = 3'd5;

    localparam OP_NOP   = 4'h0;
    localparam OP_LOAD  = 4'h7;
    localparam OP_STORE = 4'h8;
    localparam OP_JUMP  = 4'h9;
    localparam OP_BEQ   = 4'hA;
    localparam OP_HALT  = 4'hF;

    localparam PC_INC    = 2'd0;
    localparam PC_BRANCH = 2'd1;
    localparam PC_JUMP   = 2'd2;

    reg [ADDR_WIDTH-1:0] pc_reg;
    reg [DATA_WIDTH-1:0] instr_reg;
    reg [DATA_WIDTH-1:0] alu_result_reg;
    reg [DATA_WIDTH-1:0] mem_data_reg;

    reg [DATA_WIDTH-1:0] instr_mem [0:IMEM_SIZE-1];
    reg [DATA_WIDTH-1:0] data_mem  [0:DMEM_SIZE-1];

    wire [3:0] opcode;
    wire [2:0] field_11_9;
    wire [2:0] field_8_6;
    wire [2:0] field_5_3;
    wire [DATA_WIDTH-1:0] imm6_ext;

    wire ir_write;
    wire reg_write;
    wire mem_write;
    wire pc_write;
    wire alu_src_imm;
    wire result_src;
    wire [1:0] pc_src;
    wire [3:0] alu_op;

    wire [2:0] rf_raddr1;
    wire [2:0] rf_raddr2;
    wire [2:0] rf_waddr;
    wire [DATA_WIDTH-1:0] rf_rdata1;
    wire [DATA_WIDTH-1:0] rf_rdata2;
    wire [DATA_WIDTH-1:0] rf_wdata;

    wire [DATA_WIDTH-1:0] alu_b;
    wire [DATA_WIDTH-1:0] alu_result;
    wire alu_zero;
    wire branch_equal;

    integer i;

    initial begin
        pc_reg = {ADDR_WIDTH{1'b0}};
        instr_reg = {DATA_WIDTH{1'b0}};
        alu_result_reg = {DATA_WIDTH{1'b0}};
        mem_data_reg = {DATA_WIDTH{1'b0}};

        for (i = 0; i < IMEM_SIZE; i = i + 1) begin
            instr_mem[i] = {DATA_WIDTH{1'b0}};
        end

        for (i = 0; i < DMEM_SIZE; i = i + 1) begin
            data_mem[i] = {DATA_WIDTH{1'b0}};
        end
    end

    assign opcode = instr_reg[15:12];
    assign field_11_9 = instr_reg[11:9];
    assign field_8_6  = instr_reg[8:6];
    assign field_5_3  = instr_reg[5:3];
    assign imm6_ext = {{10{instr_reg[5]}}, instr_reg[5:0]};

    assign rf_raddr1 = (opcode == OP_BEQ) ? field_11_9 : field_8_6;
    assign rf_raddr2 = (opcode == OP_STORE) ? field_11_9 :
                       (opcode == OP_BEQ)   ? field_8_6  : field_5_3;
    assign rf_waddr = field_11_9;
    assign rf_wdata = result_src ? mem_data_reg : alu_result_reg;

    assign alu_b = alu_src_imm ? imm6_ext : rf_rdata2;
    assign branch_equal = (rf_rdata1 == rf_rdata2);

    assign halted = (state == ST_HALT);
    assign pc = pc_reg;
    assign instr = instr_reg;

    control_unit u_control_unit (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .state(state),
        .ir_write(ir_write),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .pc_write(pc_write),
        .alu_src_imm(alu_src_imm),
        .result_src(result_src),
        .pc_src(pc_src),
        .alu_op(alu_op)
    );

    register_file #(
        .WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(3)
    ) u_register_file (
        .clk(clk),
        .rst(rst),
        .we(reg_write),
        .raddr1(rf_raddr1),
        .raddr2(rf_raddr2),
        .waddr(rf_waddr),
        .wdata(rf_wdata),
        .rdata1(rf_rdata1),
        .rdata2(rf_rdata2),
        .debug_r0(debug_r0),
        .debug_r1(debug_r1),
        .debug_r2(debug_r2),
        .debug_r3(debug_r3),
        .debug_r4(debug_r4),
        .debug_r5(debug_r5),
        .debug_r6(debug_r6),
        .debug_r7(debug_r7)
    );

    alu #(
        .WIDTH(DATA_WIDTH)
    ) u_alu (
        .a(rf_rdata1),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(alu_zero)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_reg <= {ADDR_WIDTH{1'b0}};
            instr_reg <= {DATA_WIDTH{1'b0}};
            alu_result_reg <= {DATA_WIDTH{1'b0}};
            mem_data_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            if (ir_write) begin
                instr_reg <= instr_mem[pc_reg];
            end

            if (state == ST_EXECUTE) begin
                alu_result_reg <= alu_result;
            end

            if ((state == ST_MEMORY) && (opcode == OP_LOAD)) begin
                mem_data_reg <= data_mem[alu_result_reg[ADDR_WIDTH-1:0]];
            end

            if (mem_write) begin
                data_mem[alu_result_reg[ADDR_WIDTH-1:0]] <= rf_rdata2;
            end

            if (pc_write) begin
                case (pc_src)
                    PC_INC: begin
                        pc_reg <= pc_reg + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
                    end

                    PC_BRANCH: begin
                        if (branch_equal) begin
                            pc_reg <= pc_reg + imm6_ext[ADDR_WIDTH-1:0];
                        end else begin
                            pc_reg <= pc_reg + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
                        end
                    end

                    PC_JUMP: begin
                        pc_reg <= instr_reg[ADDR_WIDTH-1:0];
                    end

                    default: begin
                        pc_reg <= pc_reg + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
                    end
                endcase
            end
        end
    end

endmodule
