# Simulation Report

## Цель

Проверить корректность выполнения тестовой программы процессорным ядром ASOIU-16.

## Инструмент

- Icarus Verilog
- VCD waveform dump для просмотра в GTKWave или другом VCD viewer

## Команды запуска

```powershell
iverilog -g2005 -o reports\processor_core_tb.vvp -s processor_core_tb tb\processor_core_tb.v rtl\alu.v rtl\register_file.v rtl\control_unit.v rtl\processor_core.v
vvp reports\processor_core_tb.vvp
```

## Тестовая программа

Файлы:

- `programs/test_program.asm`
- `programs/test_program.hex`

Проверяемые операции:

- `ADDI`;
- `ADD`;
- `SUB`;
- `AND`;
- `OR`;
- `XOR`;
- `NOT`;
- `STORE`;
- `LOAD`;
- `BEQ`;
- `JUMP`;
- `HALT`.

## Ожидаемые значения после HALT

| Объект | Ожидаемое значение |
| --- | --- |
| `R0` | `0x0000` |
| `R1` | `0x0005` |
| `R2` | `0x0007` |
| `R3` | `0x000C` |
| `R4` | `0x000C` |
| `R5` | `0x0000` |
| `R6` | `0x0007` |
| `R7` | `0xFFFA` |
| `MEM[10]` | `0x000C` |

## Результат

Тестбенч автоматически сравнивает фактические значения с ожидаемыми. Успешный результат симуляции:

```text
SIMULATION PASSED
```

Waveform-файл:

```text
reports/processor_core_tb.vcd
```

## Дополнительный запуск demo-программы

Для этапа программно-аппаратной интеграции добавлен ассемблер `scripts/assembler.py` и demo-программа `programs/demo_sub.asm`.

Программа:

```asm
ADDI R1, R0, 10
ADDI R2, R0, 4
SUB  R3, R1, R2
HALT
```

Сборка:

```powershell
python scripts\assembler.py programs\demo_sub.asm programs\demo_sub.hex
```

Запуск:

```powershell
vvp reports\processor_core_tb.vvp +PROGRAM=programs/demo_sub.hex +PROGRAM_LAST=3 +EXPECT_R1=000A +EXPECT_R2=0004 +EXPECT_R3=0006 +EXPECT_R4=0000 +EXPECT_R5=0000 +EXPECT_R6=0000 +EXPECT_R7=0000 +EXPECT_MEM_ADDR=0 +EXPECT_MEM_VALUE=0000 +VCD=reports/demo_sub.vcd
```

Результат:

```text
PASS: R3 = 0x0006
SIMULATION PASSED
```

Файлы результата:

- `reports/demo_sub_simulation.log`;
- `reports/demo_sub.vcd`.
