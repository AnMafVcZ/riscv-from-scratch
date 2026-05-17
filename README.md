# RISC-V from Scratch

Building a RISC-V CPU in Verilog, starting from a blinking LED and working up to a real processor.

---

## Step 1 — Blinker

A 5-bit counter wired to 5 LEDs. Every clock cycle the counter increments and rolls over automatically.
The point is just to verify the clock and LED wiring works before touching any CPU logic.

`mainsoc.v` is the hardware version — it uses `clockworks.v` to slow the board clock down to ~1Hz so the blink is actually visible. `step1.v` is a stripped down version without the clock divider, meant for simulation.

## Files

| File | Purpose |
|---|---|
| `step1.v` | Bare SOC for simulation — no clock divider |
| `mainsoc.v` | SOC for real hardware — uses Clockworks to slow the blink |
| `clockworks.v` | Clock divider, slows `CLK` by `2^SLOW` |
| `bench_iverilog.v` | Testbench — generates a clock and prints LED changes to stdout |

## Simulation

Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/).

```bash
iverilog bench_iverilog.v step1.v -o sim && ./sim
```

Output — LEDs counting up in binary:
```
LEDS = 00001
LEDS = 00010
LEDS = 00011
...
```
