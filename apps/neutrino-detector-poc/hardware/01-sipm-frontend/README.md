# 01 — SiPM analog front-end

## WHAT

16-channel SiPM bias + transimpedance preamp + CR-RC shaping on a single 4-layer board. One per DOM (×5 in the PoC). Output: 16 differential analog lines to the mainboard's ADC bank.

## WHY this is its own PCB

Analog noise. SiPM signals are mV-range; the digital side (FPGA, Ethernet, DC-DC switching) is loud. Physical separation + continuous ground plane is the cheap way to keep SNR usable. Combining analog and digital on one board nearly always means a respin.

## Block

```
 [16× MicroFJ-30035]
        │
        ▼
 [HV bias network] ◄── trimmable from MCU via DAC
        │
        ▼
 [TIA per channel]  ── OPA858 or LMH6629
        │
        ▼
 [CR-RC shaper]     ── τ ≈ 50 ns
        │
        ▼
 [diff driver]      ── THS4541
        │
        ▼
   16 LVDS-style pairs → mainboard (board 02)
```

## Key parts

| Function | Part | LCSC / source |
|----------|------|----------------|
| SiPM | Onsemi MicroFJ-30035-TR | C2978125 |
| HV bias supply | MAX5026 + LC filter | LCSC |
| Transimpedance amp | OPA858 (or LMH6629 as alt) | LCSC |
| Diff driver | THS4541 | LCSC |
| Bias resistors | 0.1% thin-film, 10k feedback | any |
| DAC for bias trim | MCP4728 (I²C, 4-ch) | LCSC |

## Gotchas

- **HV temperature compensation:** ~22 mV/°C per SiPM. For PoC, single trim at deploy temperature (Prasonisi seabed ~16 °C, stable). For v2, add a thermistor + DAC compensation loop.
- **Layout:** keep TIA inputs short, guard rings around HV nets, no digital trace crossing the SiPM analog ground.
- **4-layer minimum.** Stackup: signal / GND / power / signal.
- **Crosstalk between channels:** isolate channels with stitched ground pours; SiPM dark pulses on neighbor channels otherwise become a measurable systematic.

## DONE

- Bench: each of 16 channels shows a clean single-PE peak in MCA histogram, with dark count rate within 30% of Onsemi datasheet (~50 kHz/mm² @ 25 °C, 5 V overvoltage).
- Integrated with `02-mainboard`: muon coincidence triggers visible in air at sea level (rate consistent with ~1 cm⁻² min⁻¹ × board area, after geometric acceptance).
- Crosstalk between adjacent channels < 1% at single-PE amplitude.
