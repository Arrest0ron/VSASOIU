# ASOIU-16 Processor Core

Учебный проект процессорного ядра на Verilog по дисциплине "Вычислительные средства АСОИУ".

## Структура проекта

| Путь | Назначение |
| --- | --- |
| `docs/` | документация проекта, ISA Manual |
| `rtl/` | Verilog RTL-модули процессора |
| `tb/` | тестбенчи |
| `programs/` | тестовые программы и машинный код |
| `scripts/` | вспомогательные скрипты, включая ассемблер |
| `reports/` | логи симуляции и отчеты синтеза |
| `diagrams/` | архитектурные схемы, FSM, waveforms, RTL schematic |

## Этапы

1. Разработка архитектуры и ISA.
2. RTL Design на Verilog.
3. Верификация и симуляция.
4. Синтез и анализ ресурсов.
5. Тестовая программа и программно-аппаратная интеграция.

## Текущие артефакты

- Этап 1: [docs/isa_manual.md](docs/isa_manual.md).
- Пояснение Data Path: [docs/datapath_overview.md](docs/datapath_overview.md).
- Использование ассемблера: [docs/assembler_usage.md](docs/assembler_usage.md).
- Этап 2, RTL:
  - [rtl/alu.v](rtl/alu.v)
  - [rtl/register_file.v](rtl/register_file.v)
  - [rtl/control_unit.v](rtl/control_unit.v)
  - [rtl/processor_core.v](rtl/processor_core.v)
- Этап 3, Verification:
  - [tb/processor_core_tb.v](tb/processor_core_tb.v)
  - [programs/test_program.asm](programs/test_program.asm)
  - [programs/test_program.hex](programs/test_program.hex)
  - [reports/simulation.log](reports/simulation.log)
  - [reports/simulation_report.md](reports/simulation_report.md)
  - [reports/processor_core_tb.vcd](reports/processor_core_tb.vcd)
- Этап 5, программно-аппаратная интеграция:
  - [scripts/assembler.py](scripts/assembler.py)
  - [programs/demo_sub.asm](programs/demo_sub.asm)
  - [programs/demo_sub.hex](programs/demo_sub.hex)

## Быстрая проверка RTL

```powershell
iverilog -g2005 -tnull -s processor_core rtl\alu.v rtl\register_file.v rtl\control_unit.v rtl\processor_core.v
```

## Симуляция

```powershell
iverilog -g2005 -o reports\processor_core_tb.vvp -s processor_core_tb tb\processor_core_tb.v rtl\alu.v rtl\register_file.v rtl\control_unit.v rtl\processor_core.v
vvp reports\processor_core_tb.vvp
```

Ожидаемый итог:

```text
SIMULATION PASSED
```

## Сборка своей программы

Пример для программы `10 - 4`:

```powershell
python scripts\assembler.py programs\demo_sub.asm programs\demo_sub.hex
```

Запуск этой программы в тестбенче:

```powershell
vvp reports\processor_core_tb.vvp +PROGRAM=programs/demo_sub.hex +PROGRAM_LAST=3 +EXPECT_R1=000A +EXPECT_R2=0004 +EXPECT_R3=0006 +EXPECT_R4=0000 +EXPECT_R5=0000 +EXPECT_R6=0000 +EXPECT_R7=0000 +EXPECT_MEM_ADDR=0 +EXPECT_MEM_VALUE=0000 +VCD=reports/demo_sub.vcd
```
