`timescale 1ns / 1ps

module processor_core_tb;

    reg clk;
    reg rst;

    wire halted;
    wire [7:0] pc;
    wire [15:0] instr;
    wire [2:0] state;
    wire [15:0] debug_r0;
    wire [15:0] debug_r1;
    wire [15:0] debug_r2;
    wire [15:0] debug_r3;
    wire [15:0] debug_r4;
    wire [15:0] debug_r5;
    wire [15:0] debug_r6;
    wire [15:0] debug_r7;

    integer cycle_count;
    integer errors;

    processor_core uut (
        .clk(clk),
        .rst(rst),
        .halted(halted),
        .pc(pc),
        .instr(instr),
        .state(state),
        .debug_r0(debug_r0),
        .debug_r1(debug_r1),
        .debug_r2(debug_r2),
        .debug_r3(debug_r3),
        .debug_r4(debug_r4),
        .debug_r5(debug_r5),
        .debug_r6(debug_r6),
        .debug_r7(debug_r7)
    );

    always #5 clk = ~clk;

    task check16;
        input [127:0] name;
        input [15:0] actual;
        input [15:0] expected;
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s actual=0x%04h expected=0x%04h", name, actual, expected);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s = 0x%04h", name, actual);
            end
        end
    endtask

    initial begin
        $dumpfile("reports/processor_core_tb.vcd");
        $dumpvars(0, processor_core_tb);

        clk = 1'b0;
        rst = 1'b1;
        cycle_count = 0;
        errors = 0;

        $readmemh("programs/test_program.hex", uut.instr_mem, 0, 14);

        repeat (2) @(posedge clk);
        rst = 1'b0;

        while (!halted && (cycle_count < 200)) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end

        if (!halted) begin
            $display("FAIL: processor did not halt before timeout");
            errors = errors + 1;
        end else begin
            $display("PASS: processor halted after %0d cycles", cycle_count);
        end

        check16("R0", debug_r0, 16'd0);
        check16("R1", debug_r1, 16'd5);
        check16("R2", debug_r2, 16'd7);
        check16("R3", debug_r3, 16'd12);
        check16("R4", debug_r4, 16'd12);
        check16("R5", debug_r5, 16'd0);
        check16("R6", debug_r6, 16'd7);
        check16("R7", debug_r7, 16'hFFFA);
        check16("MEM[10]", uut.data_mem[10], 16'd12);

        if (errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED: %0d error(s)", errors);
        end

        $finish;
    end

endmodule
