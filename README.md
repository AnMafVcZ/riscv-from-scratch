# RISC-V from Scratch

Building a RISC-V CPU in Verilog from the ground up. Starting with the basics and adding pieces until there's a working processor.

---

## What's working — Step 1 (Blinker)

A 5-bit counter connected to 5 LEDs. The counter increments every clock tick and wraps back to 0 after 31. Nothing fancy, just enough to confirm the clock and LEDs are behaving before writing any CPU logic.

The clock runs way too fast to see on real hardware (~100MHz on most boards), so `clockworks.v` divides it down by `2^21` to get to around 1Hz — that's what makes the blink actually visible.

Reset is also wired up: pulling `RESET` high zeroes the counter via `resetn`.

## Files

| File | What it does |
|---|---|
| `mainsoc.v` | Top-level SOC module — the blinker with clock divider and reset |
| `clockworks.v` | Slows the board clock down by `2^SLOW` |
| `bench_iverilog.v` | Simulation testbench — toggles the clock and prints whenever LEDs change |

## Running the simulation

Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/).

```bash
iverilog bench_iverilog.v mainsoc.v -o sim && ./sim
```

You'll see the counter tick up in binary:
```
LEDS = 00001
LEDS = 00010
LEDS = 00011
...
```
