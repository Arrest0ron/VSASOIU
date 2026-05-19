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
