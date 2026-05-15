# 03 — DOM power conditioning

## WHAT

Takes +48 V DC from the tether (pins 1–2 per board 02 pinout), generates the rails for boards `01` and `02` via an isolated brick + POL bucks. Surge + ESD protection on the tether input, watchdog supervisor on the regulated side. One per DOM (×5 in the PoC).

Rails out:
- **+12 V_a** → board 01 (input to HV boost)
- **+5 V_a** → board 01 (op-amp supply, LC-filtered)
- **+5 V_d** → board 02 (Tang Primer 25K)
- **+3.3 V_d** → board 02 (STM32, PHY)
- **+1.8 V_a** → board 02 (ADC AVDD/DVDD, LDO from +3.3 V_d)

Full budgets and noise targets in `DESIGN.md`.

## WHY its own board

Switching DC-DC is a noise source. Isolating it physically + through an isolated brick is the standard move for instrument power. Also lets the analog and digital boards see clean rails regardless of tether ripple.

## Block

```
   tether 48V ──► [TVS + LC filter] ──► [isolated DC-DC 48→12V]
                                                │
                          ┌─────────────────────┼────────────────────┐
                          ▼                     ▼                    ▼
                   [LMR33630 → 5V]      [TPS62933 → 3.3V]    [TPS62933 → 1.8V]
                          │                     │                    │
                          └──────┐         ┌────┘                    │
                                 ▼         ▼                         │
                          [ICL7665 supervisor + reset MCU]            │
                                                                      │
                          [TPS65131 → ±12V analog] ─────────────────► to board 01
```

## Key parts

| Function | Part |
|----------|------|
| Tether surge | SMBJ58A TVS |
| Common-mode choke | Würth 744232511 |
| Isolated brick 48→12 V | Mornsun K7812-3000R3 (THT) or RECOM RPM30-4812SH (SMT) |
| +5 V_a / +5 V_d / +3.3 V_d bucks | 3× TI LMR33630 |
| +1.8 V_a LDO | LT3045 (low-noise) from +3.3 V_d |
| Supervisor | ICL7665 monitoring +3.3 V_d and +1.8 V_a |
| HV bias monitor | TLV3702 comparator (sense from board 01 HV bus) |

## Gotchas

- **Thermals:** ~5 W dissipation inside a sealed DOM. Either thermal-pad to the aluminum housing or accept ΔT and verify SiPM operating point still in spec.
- **Common-mode choke on tether feed is mandatory.** Without it, ground loops via the surface side will swamp the analog board with mains-frequency hum.
- **Soft-start the isolated brick** — inrush from the housing's decoupling caps can trip the topside breaker otherwise.
- 2-layer is fine if thermal vias are stitched generously; 4-layer is cleaner.

## DONE

- All rails within ±2% under 0–100% load swing.
- Noise 1 kHz – 100 MHz on analog rails < 2 mVpp (scope with FFT).
- Survives 48-hour soak in a dummy housing at full load + 30 °C ambient without thermal shutdown.
- Tether reverse-polarity and surge tested (apply 200 V transient to TVS).
