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
    integer program_last;
    integer mem_addr;
    integer dump_mem_start;
    integer dump_mem_end;
    integer dump_i;
    integer plusarg_found;
    reg [1023:0] waveform_file;
    reg [1023:0] program_file;
    reg [15:0] expected_r0;
    reg [15:0] expected_r1;
    reg [15:0] expected_r2;
    reg [15:0] expected_r3;
    reg [15:0] expected_r4;
    reg [15:0] expected_r5;
    reg [15:0] expected_r6;
    reg [15:0] expected_r7;
    reg [15:0] expected_mem_value;

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
        clk = 1'b0;
        rst = 1'b1;
        cycle_count = 0;
        errors = 0;

        waveform_file = "reports/processor_core_tb.vcd";
        program_file = "programs/test_program.hex";
        program_last = 14;
        expected_r0 = 16'h0000;
        expected_r1 = 16'h0005;
        expected_r2 = 16'h0007;
        expected_r3 = 16'h000C;
        expected_r4 = 16'h000C;
        expected_r5 = 16'h0000;
        expected_r6 = 16'h0007;
        expected_r7 = 16'hFFFA;
        mem_addr = 10;
        expected_mem_value = 16'h000C;
        dump_mem_start = 0;
        dump_mem_end = -1;

        plusarg_found = $value$plusargs("VCD=%s", waveform_file);
        plusarg_found = $value$plusargs("PROGRAM=%s", program_file);
        plusarg_found = $value$plusargs("PROGRAM_LAST=%d", program_last);
        plusarg_found = $value$plusargs("EXPECT_R0=%h", expected_r0);
        plusarg_found = $value$plusargs("EXPECT_R1=%h", expected_r1);
        plusarg_found = $value$plusargs("EXPECT_R2=%h", expected_r2);
        plusarg_found = $value$plusargs("EXPECT_R3=%h", expected_r3);
        plusarg_found = $value$plusargs("EXPECT_R4=%h", expected_r4);
        plusarg_found = $value$plusargs("EXPECT_R5=%h", expected_r5);
        plusarg_found = $value$plusargs("EXPECT_R6=%h", expected_r6);
        plusarg_found = $value$plusargs("EXPECT_R7=%h", expected_r7);
        plusarg_found = $value$plusargs("EXPECT_MEM_ADDR=%d", mem_addr);
        plusarg_found = $value$plusargs("EXPECT_MEM_VALUE=%h", expected_mem_value);
        plusarg_found = $value$plusargs("DUMP_MEM_START=%d", dump_mem_start);
        plusarg_found = $value$plusargs("DUMP_MEM_END=%d", dump_mem_end);

        $dumpfile(waveform_file);
        $dumpvars(0, processor_core_tb);

        $display("Loading program: %0s", program_file);
        $readmemh(program_file, uut.instr_mem, 0, program_last);

        repeat (2) @(posedge clk);
        rst = 1'b0;

        while (!halted && (cycle_count < 600)) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end

        if (!halted) begin
            $display("FAIL: processor did not halt before timeout");
            errors = errors + 1;
        end else begin
            $display("PASS: processor halted after %0d cycles", cycle_count);
        end

        check16("R0", debug_r0, expected_r0);
        check16("R1", debug_r1, expected_r1);
        check16("R2", debug_r2, expected_r2);
        check16("R3", debug_r3, expected_r3);
        check16("R4", debug_r4, expected_r4);
        check16("R5", debug_r5, expected_r5);
        check16("R6", debug_r6, expected_r6);
        check16("R7", debug_r7, expected_r7);
        check16("MEM", uut.data_mem[mem_addr], expected_mem_value);

        if (dump_mem_end >= dump_mem_start) begin
            $display("MEMORY DUMP [%0d..%0d]", dump_mem_start, dump_mem_end);
            for (dump_i = dump_mem_start; dump_i <= dump_mem_end; dump_i = dump_i + 1) begin
                $display("MEM[%0d] = 0x%04h", dump_i, uut.data_mem[dump_i]);
            end
        end

        if (errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED: %0d error(s)", errors);
        end

        $finish;
    end

endmodule
