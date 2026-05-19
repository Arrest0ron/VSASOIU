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
