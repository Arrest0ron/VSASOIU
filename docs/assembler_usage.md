# Использование ассемблера ASOIU-16

## 1. Назначение

Ассемблер `scripts/assembler.py` переводит программу на простом ассемблере ASOIU-16 в `.hex`-файл, который тестбенч загружает в память команд процессора.

Общий поток работы:

```text
program.asm -> assembler.py -> program.hex -> processor_core_tb -> simulation result
```

## 2. Пример: вычитание 10 - 4

Файл `programs/demo_sub.asm`:

```asm
ADDI R1, R0, 10
ADDI R2, R0, 4
SUB  R3, R1, R2
HALT
```

Смысл программы:

```text
R1 = 10
R2 = 4
R3 = R1 - R2 = 6
```

## 3. Сборка программы

```powershell
python scripts\assembler.py programs\demo_sub.asm programs\demo_sub.hex
```

Ожидаемый машинный код:

```text
B20A
B404
2650
F000
```

## 4. Запуск симуляции

Сначала собрать Verilog:

```powershell
iverilog -g2005 -o reports\processor_core_tb.vvp -s processor_core_tb tb\processor_core_tb.v rtl\alu.v rtl\register_file.v rtl\control_unit.v rtl\processor_core.v
```

Затем запустить demo-программу:

```powershell
vvp reports\processor_core_tb.vvp +PROGRAM=programs/demo_sub.hex +PROGRAM_LAST=3 +EXPECT_R1=000A +EXPECT_R2=0004 +EXPECT_R3=0006 +EXPECT_R4=0000 +EXPECT_R5=0000 +EXPECT_R6=0000 +EXPECT_R7=0000 +EXPECT_MEM_ADDR=0 +EXPECT_MEM_VALUE=0000 +VCD=reports/demo_sub.vcd
```

Ожидаемый результат:

```text
PASS: R3 = 0x0006
SIMULATION PASSED
```

## 5. Поддерживаемые команды

```asm
NOP
ADD   rd, rs1, rs2
SUB   rd, rs1, rs2
AND   rd, rs1, rs2
OR    rd, rs1, rs2
XOR   rd, rs1, rs2
NOT   rd, rs1
LOAD  rd, [base + imm6]
STORE rs2, [base + imm6]
JUMP  addr_or_label
BEQ   rs1, rs2, offset_or_label
ADDI  rd, rs1, imm6
HALT
```

## 6. Метки

Ассемблер поддерживает метки:

```asm
start:
    ADDI R1, R0, 1
    JUMP start
```

Для `JUMP` метка кодируется как абсолютный адрес команды.

Для `BEQ` метка кодируется как относительное смещение от текущего `PC`.

## 7. Ограничения

- регистры: только `R0`...`R7`;
- `imm6` и offset для `BEQ`: от `-32` до `31`;
- адрес `JUMP`: от `0` до `4095`, в текущем ядре фактически используются младшие 8 бит;
- комментарии начинаются с `;`.
