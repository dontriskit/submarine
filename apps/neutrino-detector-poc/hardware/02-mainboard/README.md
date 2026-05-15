# 02 — DOM digital mainboard

## WHAT

Carrier for the digital side of the DOM. Mounts MCU + FPGA modules, digitizes 16 analog channels from board `01`, timestamps each event with ns precision against the tether-distributed PPS, ships data over Ethernet through the tether. One per DOM (×5 in the PoC).

GPS is centralised on the surface aggregator (board `04`) and distributed as PPS over the tether — see `DESIGN.md` §1 for the rationale.

## WHY its own board

Combines several COTS modules plus an ADC bank. Splitting digital from analog (`01`) and power (`03`) keeps each ground domain clean. Also lets us respin the digital side without re-fabbing the (more expensive, more careful) analog board.

## Block

```
  16 diff in from 01-      [Tang Primer 25K FPGA]
        │                       │
        ▼                       │
   [2× AD9249 ADC]  ──LVDS───►  │  ── triggers + soft-TDC ──┐
   (8-ch 14b 65MSPS)            │                            │
                          ┌─────┴──────┐                     │
                          │ STM32H743  │ ◄── slow ctrl, event build
                          └─────┬──────┘                     │
                                │                            │
                          [LAN8720 PHY]                 [PPS in via LVDS]
                                │                            │
                                ▼                       ◄────┘
                            tether                     from tether (pins 7–8)
```

## Key parts

| Function | Part | Notes |
|----------|------|-------|
| MCU | STM32H743 (WeAct module or bare) | event builder, slow control, Ethernet stack |
| FPGA | Sipeed Tang Primer 25K (ECP5 LFE5U-25F) | ADC interface, trigger, soft-TDC, ring buffer |
| ADC | 2× AD9249 (8-ch 14-bit 65 MSPS) | LVDS serial to FPGA. Fallback: 4× ADC3424 |
| Ethernet PHY | LAN8720A | RMII, magnetics direct to tether pairs (no RJ45) |
| TCXO | 10 MHz ±0.5 ppm (Abracon ABLNO) | reference for FPGA PLL + holdover between PPS |
| LVDS RX | DS90LV019 | PPS input from tether |
| Tether connector | Subconn Micro 8-pin (surplus) or DIY epoxy gland | pinout locked in DESIGN.md §5 |

No external TDC chip — soft-TDC in the ECP5 carry chains (~150 ps) is below our needs. TDC7200 footprint kept as DNP option in case soft-TDC characterisation disappoints.

## Gotchas

- **PPS comes from the surface, not from a local GPS.** Tether pair carries LVDS PPS from board 04. If the tether glitches, the TCXO holds time for ~0.5 µs/s drift; the MCU flags `pps_lost` in event metadata for downstream re-alignment.
- **PPS routing on the FPGA:** drive a dedicated low-skew clock pin, not a regular GPIO. Don't trust EXTI on the STM32 for ns-level timing.
- **ADC sample clock isolation:** route on its own layer if possible — it couples into ADC LSBs otherwise.
- **4-layer minimum; likely 6-layer once LVDS routing is in.** See `DESIGN.md` §7.

## DONE

- Bench: PPS-disciplined event timestamps reproduce a lab pulse generator's timing within ±25 ns over 1 hour.
- TCXO holdover characterised: drift over 4 hours with PPS deliberately killed < 5 µs.
- Integrated: events from `01-sipm-frontend` reach the surface aggregator with correct timestamps and channel mapping; round-trip from photon → packet at the topside < 100 ms.
- All 5 DOMs deployed on a common tether bundle agree on event timestamps within ±100 ns for a shared coincidence pulse (LED pulser flashed simultaneously near multiple DOMs).
