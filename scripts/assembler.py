#!/usr/bin/env python3
"""Simple assembler for the ASOIU-16 educational processor."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


OPCODES = {
    "NOP": 0x0,
    "ADD": 0x1,
    "SUB": 0x2,
    "AND": 0x3,
    "OR": 0x4,
    "XOR": 0x5,
    "NOT": 0x6,
    "LOAD": 0x7,
    "STORE": 0x8,
    "JUMP": 0x9,
    "BEQ": 0xA,
    "ADDI": 0xB,
    "HALT": 0xF,
}


REGISTER_RE = re.compile(r"^R([0-7])$", re.IGNORECASE)
MEMORY_RE = re.compile(r"^\[\s*(R[0-7])\s*\+\s*([^\]]+)\s*\]$", re.IGNORECASE)


class AssemblerError(Exception):
    pass


def strip_comment(line: str) -> str:
    return line.split(";", 1)[0].strip()


def parse_number(token: str) -> int:
    token = token.strip()
    if token.lower().startswith("0x"):
        return int(token, 16)
    if token.lower().startswith("-0x"):
        return -int(token[1:], 16)
    return int(token, 10)


def parse_register(token: str) -> int:
    match = REGISTER_RE.match(token.strip())
    if not match:
        raise AssemblerError(f"Invalid register: {token}")
    return int(match.group(1))


def split_operands(text: str) -> list[str]:
    return [part.strip() for part in text.split(",") if part.strip()]


def encode_signed(value: int, bits: int, context: str) -> int:
    minimum = -(1 << (bits - 1))
    maximum = (1 << (bits - 1)) - 1
    if value < minimum or value > maximum:
        raise AssemblerError(f"{context} value {value} does not fit into signed {bits} bits")
    return value & ((1 << bits) - 1)


def encode_unsigned(value: int, bits: int, context: str) -> int:
    maximum = (1 << bits) - 1
    if value < 0 or value > maximum:
        raise AssemblerError(f"{context} value {value} does not fit into unsigned {bits} bits")
    return value


def normalize_lines(source: str) -> tuple[list[tuple[int, str]], dict[str, int]]:
    instructions: list[tuple[int, str]] = []
    labels: dict[str, int] = {}
    pc = 0

    for line_no, raw_line in enumerate(source.splitlines(), start=1):
        line = strip_comment(raw_line)
        if not line:
            continue

        while ":" in line:
            label, rest = line.split(":", 1)
            label = label.strip()
            if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", label):
                raise AssemblerError(f"Line {line_no}: invalid label '{label}'")
            if label in labels:
                raise AssemblerError(f"Line {line_no}: duplicate label '{label}'")
            labels[label] = pc
            line = rest.strip()
            if not line:
                break

        if line:
            instructions.append((line_no, line))
            pc += 1

    return instructions, labels


def resolve_value(token: str, labels: dict[str, int], current_pc: int, relative: bool) -> int:
    token = token.strip()
    if token in labels:
        target = labels[token]
        return target - current_pc if relative else target
    return parse_number(token)


def encode_instruction(line_no: int, pc: int, text: str, labels: dict[str, int]) -> int:
    parts = text.strip().split(None, 1)
    mnemonic = parts[0].upper()
    operands_text = parts[1] if len(parts) > 1 else ""
    operands = split_operands(operands_text)

    if mnemonic not in OPCODES:
        raise AssemblerError(f"Line {line_no}: unknown mnemonic '{mnemonic}'")

    opcode = OPCODES[mnemonic]

    if mnemonic == "NOP":
        if operands:
            raise AssemblerError(f"Line {line_no}: NOP takes no operands")
        return opcode << 12

    if mnemonic == "HALT":
        if operands:
            raise AssemblerError(f"Line {line_no}: HALT takes no operands")
        return opcode << 12

    if mnemonic in {"ADD", "SUB", "AND", "OR", "XOR"}:
        if len(operands) != 3:
            raise AssemblerError(f"Line {line_no}: {mnemonic} requires rd, rs1, rs2")
        rd = parse_register(operands[0])
        rs1 = parse_register(operands[1])
        rs2 = parse_register(operands[2])
        return (opcode << 12) | (rd << 9) | (rs1 << 6) | (rs2 << 3)

    if mnemonic == "NOT":
        if len(operands) != 2:
            raise AssemblerError(f"Line {line_no}: NOT requires rd, rs1")
        rd = parse_register(operands[0])
        rs1 = parse_register(operands[1])
        return (opcode << 12) | (rd << 9) | (rs1 << 6)

    if mnemonic == "ADDI":
        if len(operands) != 3:
            raise AssemblerError(f"Line {line_no}: ADDI requires rd, rs1, imm6")
        rd = parse_register(operands[0])
        rs1 = parse_register(operands[1])
        imm6 = encode_signed(parse_number(operands[2]), 6, f"Line {line_no}: ADDI immediate")
        return (opcode << 12) | (rd << 9) | (rs1 << 6) | imm6

    if mnemonic in {"LOAD", "STORE"}:
        if len(operands) != 2:
            raise AssemblerError(f"Line {line_no}: {mnemonic} requires register, [base + imm6]")
        reg = parse_register(operands[0])
        mem_match = MEMORY_RE.match(operands[1])
        if not mem_match:
            raise AssemblerError(f"Line {line_no}: invalid memory operand '{operands[1]}'")
        base = parse_register(mem_match.group(1))
        imm6 = encode_signed(parse_number(mem_match.group(2)), 6, f"Line {line_no}: memory offset")
        return (opcode << 12) | (reg << 9) | (base << 6) | imm6

    if mnemonic == "JUMP":
        if len(operands) != 1:
            raise AssemblerError(f"Line {line_no}: JUMP requires addr12 or label")
        addr = resolve_value(operands[0], labels, pc, relative=False)
        addr12 = encode_unsigned(addr, 12, f"Line {line_no}: jump address")
        return (opcode << 12) | addr12

    if mnemonic == "BEQ":
        if len(operands) != 3:
            raise AssemblerError(f"Line {line_no}: BEQ requires rs1, rs2, offset6 or label")
        rs1 = parse_register(operands[0])
        rs2 = parse_register(operands[1])
        offset = resolve_value(operands[2], labels, pc, relative=True)
        offset6 = encode_signed(offset, 6, f"Line {line_no}: branch offset")
        return (opcode << 12) | (rs1 << 9) | (rs2 << 6) | offset6

    raise AssemblerError(f"Line {line_no}: unsupported instruction '{mnemonic}'")


def assemble(source: str) -> list[int]:
    instructions, labels = normalize_lines(source)
    words = []
    for pc, (line_no, text) in enumerate(instructions):
        words.append(encode_instruction(line_no, pc, text, labels))
    return words


def main() -> int:
    parser = argparse.ArgumentParser(description="Assemble ASOIU-16 assembly into hex words.")
    parser.add_argument("input", type=Path, help="Input .asm file")
    parser.add_argument("output", type=Path, help="Output .hex file")
    args = parser.parse_args()

    try:
        source = args.input.read_text(encoding="utf-8")
        words = assemble(source)
    except (OSError, ValueError, AssemblerError) as exc:
        print(f"assembler error: {exc}")
        return 1

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("".join(f"{word:04X}\n" for word in words), encoding="ascii")
    print(f"Assembled {len(words)} instruction(s): {args.input} -> {args.output}")
    if words:
        print(f"Program address range: 0..{len(words) - 1}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
