# RISC-V from Scratch

Building a RISC-V CPU in Verilog, step by step — from a blinking LED counter up to a full processor.

## Progress

### Step 1 — Blinker (`step1.v`)
A 5-bit counter that increments every clock cycle, wired directly to 5 LEDs.
Wraps automatically from `11111` → `00000` due to integer overflow.
This verifies the clock and LED wiring before adding any CPU logic.

## Files

| File | Purpose |
|---|---|
| `step1.v` | SOC top-level module — currently a 5-bit LED blinker |
| `bench_iverilog.v` | Simulation testbench — generates a clock and prints LED changes |
| `clockworks.v` | Reusable clock divider module — slows down the design clock by a power of 2 |

## Running the Simulation

Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/).

```bash
iverilog bench_iverilog.v step1.v -o sim && ./sim
```

Expected output — LEDs counting up in binary:
```
LEDS = 00001
LEDS = 00010
LEDS = 00011
...
```

## Clockworks Module

`clockworks.v` provides a parameterized clock divider. Set `SLOW` to divide the board clock by `2^SLOW`, useful for slowing things down enough to observe on real hardware.

```verilog
Clockworks #(.SLOW(18)) CW(.CLK(CLK), .RESET(RESET), .clk(clk), .resetn(resetn));
```
