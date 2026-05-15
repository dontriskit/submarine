# 05 — design notes

Engineering layer below the README. Pulse driver, sync, optics.

## 1. Architectural decisions

1. **Drop the ESP32-S3.** The first README had ESP32 + FPGA trigger; that's two MCUs for one job. Use just a Sipeed Tang Nano 9K — it has USB-C, programmable from KiCad/openFPGAloader, and a CMSIS-DAP-style bridge for USB-serial control. €10. No reason to add ESP32.
2. **Mechanical attenuation, not electrical.** Variable LED current at sub-ns timescales is hard to do precisely. Use a fixed-amplitude driver and a discrete ND filter wheel (Thorlabs NE-A series or DIY printed wheel with absorptive films). Three positions: single-PE-ish, ~10 PE, saturation. Repeatable, traceable.
3. **Sync to DOM under test via copper fiber.** Tang Nano 9K emits a trigger pulse and the LED-flash event timestamp on a single LVDS pair → goes to the DOM's mainboard via a short pigtail. The DOM stamps the pulser arrival in the same TDC chain as its photon events. No GPS sync needed for the pulser — its time is set by the DOM's trigger receipt.

## 2. Block

```
   USB-C ──► [Tang Nano 9K]
                    │
              ┌─────┴─────┐
              ▼           ▼
   [LVDS trigger out]  [LMG1020 gate driver]
              │              │
              ▼              ▼
        to DOM trig in  [450 nm LED + diffuser + ND wheel]
                              │
                              ▼
                       photons → DOM SiPM window
```

## 3. LED drive

Target: 5–10 ns FWHM pulse, jitter < 1 ns vs trigger, repeatable amplitude across runs.

LMG1020 (GaN gate driver, 5 A peak, rise/fall < 2 ns):

```
   Tang Nano LVDS pair ──► [1-bit comparator AD8611] ──► [LMG1020 IN]
                                                              │
                                                          [LMG1020 OUT]
                                                              │
                                                              ▼
                                                       LED anode
                                                              │
                                                         [LED Cree XP-E2 or OSRAM LB W5SM]
                                                              │
                                                       LED cathode
                                                              │
                                                       [series R 5R 1%]
                                                              │
                                                             GND
```

- LED forward voltage at 1 A pulse: ~3.5 V → drop ~1.5 V across the 5 Ω series, gives ~300 mA peak. Plenty for a sub-10-ns pulse at high intensity.
- Pulse width set by LMG1020 input pulse from FPGA: 5 ns minimum (limited by Tang Nano timing).

## 4. Optics

| Stage | Part | Purpose |
|-------|------|---------|
| LED | Cree XP-E2 royal blue (~450 nm) or OSRAM LB W5SM | Match SiPM PDE peak |
| Diffuser | Thorlabs DG10-1500 ground glass | Uniformity over DOM window |
| Filter wheel | 3-position DIY printed; ND filters from Edmund Optics | Discrete amplitudes |
| Coupling to DOM | Short black acrylic tube, light-tight | Eliminate ambient light |

For in-water calibration runs, the whole optical chain goes into a small DIY housing (PCV tube + acrylic window + epoxy gland for the trigger pigtail). Lower it next to a DOM in 5 m of water at Prasonisi for bench-to-deploy gain comparison.

## 5. Calibration procedure (informational)

1. Set ND filter to position 1 (single-PE-ish).
2. Tang Nano pulses at 1 kHz for 60 s.
3. DOM under test records 60,000 pulser events.
4. Build per-channel histogram of pulse area → single-PE peak position.
5. Repeat for ND positions 2 and 3 to fill out the gain curve.
6. Compare to cosmic-muon-derived gain (separate measurement, longer integration); they should agree within 5%.

## 6. Power and form factor

USB-C powered from a laptop or any 5 V source. ~200 mA average (LED is duty-cycled tiny). One small PCB ~50 × 30 mm, 2-layer is fine. Mounts in a small acrylic enclosure for bench use, or a DIY pressure housing for in-water runs.

## 7. Open questions

1. **LED choice — Cree vs OSRAM.** Both are 450 nm. Cree has slightly faster turn-on (~1 ns vs ~2 ns). For 5–10 ns target pulse either works. Buy two of each, pick on the bench.
2. **In-water housing material.** PVC tube + acrylic window is the cheap path. For a permanent fixture in v2, a small aluminum cylinder with optical-grade window glass would be more durable.
3. **Absolute amplitude calibration.** We're matching to cosmic-muon gain rather than calibrating absolute photon flux. That's circular if the muon gain is wrong. Bring a NIST-traceable photodiode for a one-time bench cross-check; document and forget.

## 8. Failure modes to test for

- **LMG1020 overheats.** Continuous 1 kHz operation is well within spec; 1 MHz pulse train is not. Limit firmware to ≤100 kHz repetition rate.
- **LED degrades over many pulses.** Royal-blue LEDs lose efficiency with cumulative drive. Check intensity vs total pulse count monthly; replace LED if drift > 5%.
- **Trigger jitter under USB activity.** USB host bus activity can couple into the LVDS trigger output. Run the Tang Nano on battery or an isolated USB hub during precision calibration.
