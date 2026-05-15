# 05 — LED calibration pulser

## WHAT

Bench-side (and occasionally in-water) tool. Drives a 450 nm LED with sub-10-ns rising edges at programmable amplitude and rate. Used to inject a known photon flux into a DOM's SiPM array for gain calibration, timing calibration, and dark-count characterization.

## WHY its own board

Standalone bench instrument. Not deployed permanently with the DOMs. For in-water cal runs, can be sealed in a small DIY housing and lowered next to a DOM during a deploy.

## Block

```
   USB-C ──► [Tang Nano 9K] ──► [LVDS trigger out → DOM trig in]
                  │
                  ▼
           [LMG1020 driver]
                  │
                  ▼
          [450 nm LED]
                  │
                  ▼
          [diffuser + 3-position ND filter wheel]
                  │
                  ▼
          photons → DOM under test
```

## Key parts

| Function | Part |
|----------|------|
| Trigger + USB control | Sipeed Tang Nano 9K (single board, no extra MCU) |
| Gate driver | TI LMG1020 (GaN, sub-2 ns rise) |
| LED | Cree XP-E2 royal blue or OSRAM LB W5SM (450 nm — buy both, pick on bench) |
| Diffuser | Thorlabs DG10-1500 ground glass (or DIY sanded acrylic) |
| Attenuation | 3-position DIY filter wheel with ND films |
| Optional housing for in-water | DIY PVC + acrylic window |

ESP32-S3 dropped — the Tang Nano 9K's USB-C bridge handles both control and trigger generation. One MCU, not two.

## Gotchas

- **LMG1020 layout is everything.** Return path under the IC, 0402 decouples right at the pins, no via stitching delays.
- **LED pulse width < 2 ns is hard.** Accept ~5–10 ns FWHM if the LED can't go faster. For calibration what matters is repeatability + known amplitude, not the absolute edge speed.
- **Sync with the DOM**: easiest is to drive the trigger from the DOM's own FPGA via a fiber or copper sync line. The pulser then becomes a slave; the timestamp is known per-pulse.

## DONE

- LED pulse FWHM < 10 ns, jitter relative to trigger < 1 ns.
- Amplitude programmable across 4 decades — from single-PE up to SiPM saturation.
- Round-trip calibration: gain values derived from this pulser match cosmic-muon endpoint gains within 5%.
