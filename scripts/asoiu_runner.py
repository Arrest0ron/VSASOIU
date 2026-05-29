#!/usr/bin/env python3
"""Interactive runner for ASOIU-16 assembly, simulation, and result checks."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PYTHON = sys.executable

RTL_FILES = [
    "rtl/alu.v",
    "rtl/register_file.v",
    "rtl/control_unit.v",
    "rtl/processor_core.v",
]


def run(cmd: list[str]) -> int:
    print("\n> " + " ".join(cmd), flush=True)
    result = subprocess.run(cmd, cwd=ROOT)
    return result.returncode


def ask(prompt: str, default: str = "") -> str:
    suffix = f" [{default}]" if default else ""
    value = input(f"{prompt}{suffix}: ").strip()
    return value if value else default


def ask_int(prompt: str, default: int) -> int:
    while True:
        value = ask(prompt, str(default))
        try:
            return int(value, 0)
        except ValueError:
            print("Enter a decimal number or 0x-prefixed hex number.")


def ask_hex16(prompt: str, default: int) -> str:
    value = ask_int(prompt, default)
    return f"{value & 0xFFFF:04X}"


def count_hex_words(hex_path: Path) -> int:
    words = [
        line.strip()
        for line in hex_path.read_text(encoding="ascii").splitlines()
        if line.strip()
    ]
    return len(words)


def assemble(asm_path: Path, hex_path: Path) -> int:
    return run([PYTHON, "scripts/assembler.py", str(asm_path), str(hex_path)])


def compile_verilog() -> int:
    return run(
        [
            "iverilog",
            "-g2005",
            "-o",
            "reports/processor_core_tb.vvp",
            "-s",
            "processor_core_tb",
            "tb/processor_core_tb.v",
            *RTL_FILES,
        ]
    )


def simulate(
    hex_path: Path,
    program_last: int,
    expected: list[str],
    mem_addr: int,
    mem_value: str,
    dump_start: int,
    dump_end: int,
    vcd_path: Path,
) -> int:
    cmd = [
        "vvp",
        "reports/processor_core_tb.vvp",
        f"+PROGRAM={hex_path.as_posix()}",
        f"+PROGRAM_LAST={program_last}",
        f"+EXPECT_R0={expected[0]}",
        f"+EXPECT_R1={expected[1]}",
        f"+EXPECT_R2={expected[2]}",
        f"+EXPECT_R3={expected[3]}",
        f"+EXPECT_R4={expected[4]}",
        f"+EXPECT_R5={expected[5]}",
        f"+EXPECT_R6={expected[6]}",
        f"+EXPECT_R7={expected[7]}",
        f"+EXPECT_MEM_ADDR={mem_addr}",
        f"+EXPECT_MEM_VALUE={mem_value}",
        f"+DUMP_MEM_START={dump_start}",
        f"+DUMP_MEM_END={dump_end}",
        f"+VCD={vcd_path.as_posix()}",
    ]
    return run(cmd)


def choose_asm() -> Path:
    programs = sorted((ROOT / "programs").glob("*.asm"))
    if programs:
        print("\nAvailable .asm programs:")
        for idx, path in enumerate(programs, start=1):
            print(f"{idx}. {path.relative_to(ROOT)}")
        choice = ask("Choose number or enter path", "1")
        if choice.isdigit() and 1 <= int(choice) <= len(programs):
            return programs[int(choice) - 1].relative_to(ROOT)
        return Path(choice)
    return Path(ask("ASM file path", "programs/demo_sub.asm"))


def interactive_flow() -> int:
    asm_path = choose_asm()
    default_hex = asm_path.with_suffix(".hex")
    hex_path = Path(ask("Output HEX file", default_hex.as_posix()))

    if assemble(asm_path, hex_path) != 0:
        return 1

    program_len = count_hex_words(ROOT / hex_path)
    program_last = ask_int("Last program address", program_len - 1)

    if compile_verilog() != 0:
        return 1

    print("\nExpected register values after HALT.")
    expected = [ask_hex16(f"R{i}", 0) for i in range(8)]

    mem_addr = ask_int("Memory address to check", 0)
    mem_value = ask_hex16("Expected value at that address", 0)
    dump_start = ask_int("Memory dump start address", 0)
    dump_end = ask_int("Memory dump end address", max(dump_start, 15))
    vcd_path = Path(ask("VCD waveform file", "reports/asoiu_runner.vcd"))

    return simulate(
        hex_path,
        program_last,
        expected,
        mem_addr,
        mem_value,
        dump_start,
        dump_end,
        vcd_path,
    )


def demo_sub_flow() -> int:
    asm_path = Path("programs/demo_sub.asm")
    hex_path = Path("programs/demo_sub.hex")
    if assemble(asm_path, hex_path) != 0:
        return 1
    if compile_verilog() != 0:
        return 1
    return simulate(
        hex_path=hex_path,
        program_last=3,
        expected=["0000", "000A", "0004", "0006", "0000", "0000", "0000", "0000"],
        mem_addr=0,
        mem_value="0000",
        dump_start=0,
        dump_end=15,
        vcd_path=Path("reports/demo_sub.vcd"),
    )


def main() -> int:
    print("ASOIU-16 runner")
    print("1. Interactive run")
    print("2. Demo: 10 - 4")
    print("3. Compile Verilog only")
    choice = ask("Choose action", "1")

    if choice == "1":
        return interactive_flow()
    if choice == "2":
        return demo_sub_flow()
    if choice == "3":
        return compile_verilog()

    print("Unknown action.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
