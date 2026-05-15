# 02 — design notes

Engineering layer below the README. Numbers, circuit choices, calculations. **Supersedes the README where they disagree** (until I sync the README back).

## 1. Architectural decisions made here

Three things the first README either fudged or left to "TBD." Locking them now:

1. **GPS lives on the surface aggregator (board 04), not on each DOM.** The DOM gets a PPS input from the tether plus a local TCXO for holdover. Cleaner, cheaper, and the SMA-through-tether antenna routing for GPS underwater never worked anyway.
2. **FPGA: Sipeed Tang Primer 25K, not Tang Nano 9K.** Tang Nano 9K is too small once you account for 16 ADC LVDS lanes, ring buffers, soft-TDC, and Ethernet MAC. Primer 25K (Lattice ECP5 LFE5U-25F) has the LVDS pins and BRAM for the job, still €25.
3. **No external TDC7200.** Soft-TDC in the ECP5 carry chains gets to ~150 ps, which is well below our requirements (cross-DOM coincidence needs < 10 ns). Footprint kept as DNP for v2 in case soft-TDC characterisation disappoints.

## 2. Functional partition

```
analog from 01-     ┌─────────────┐         ┌──────────────┐         ┌──────────────┐
 (16 diff pairs) ──►│  2× AD9249  ├─LVDS───►│ Tang Primer  │         │ STM32H743    │
                    │  8-ch each  │         │   25K FPGA   │◄───SPI──┤  (event      │
                    │  14b 65MSPS │         │              │         │   builder,   │
                    └─────────────┘         │ - sample cap │         │   slow ctrl, │
                                            │ - trigger    │         │   Ethernet)  │
   10 MHz TCXO ────────────────────────────►│ - soft-TDC   │         │              │
                                            │ - ring buf   │         └──────┬───────┘
   PPS from tether ────────────────────────►│ - packetiser │                │
                                            └──────────────┘                │
                                                                            ▼
                                                                     ┌─────────────┐
                                                                     │  LAN8720A   │
                                                                     │  RMII PHY   │
                                                                     └──────┬──────┘
                                                                            │
                                                                       tether (RX/TX)
```

- **FPGA owns the fast path:** ADC LVDS interface, trigger on per-channel threshold, capture ~1 µs window per event into BRAM, attach timestamp from soft-TDC + PPS counter.
- **MCU owns the slow path:** drain FPGA event FIFO over SPI, package into UDP packets, push out over Ethernet. Also handles I²C slow control to board 01 (HV trim DAC, supervisor).
- **No CPU on the FPGA.** Pure RTL. Keeps it simple and synthesisable on the Primer 25K.

## 3. ADC choice

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| 16× single-channel ADC (e.g. ADS7042) | Cheap, simple per-channel | Routing nightmare, 16 SPI buses, no LVDS | No |
| 4× quad ADC (ADC3424 or LTC2174) | Moderate routing | Mid-range cost ~€20/each | Workable backup |
| **2× AD9249 (8-ch 14-bit 65 MSPS)** | One chip per 8 channels, serialised LVDS to FPGA, mature | EOL risk (verify at order); needs careful clocking | **Yes** |
| 1× ADS5263 (quad 16-bit 100 MSPS) ×4 | Best performance | €70+ each, overkill | No |

Sample rate sanity check: SiPM pulse rises in ~1 ns, decays in ~50 ns. At 65 MSPS (15.4 ns/sample) we're at the edge of being able to fit the pulse shape with 3–4 samples — fine for area integration, marginal for peak finding. Acceptable for PoC where we mainly care about pulse energy, not shape.

If AD9249 is unsourceable at order time, fallback is TI ADC3424 (quad 12-bit 65 MSPS) × 4 chips — adds €20 to BOM but well-stocked at LCSC.

## 4. Timing chain

```
   surface GPSDO                  tether                       DOM mainboard
   (board 04)                                                  (board 02)
   ┌─────────────────┐                                        ┌──────────────────┐
   │  uBlox NEO-M9N  │           PPS                          │  PPS input       │
   │  + GPSDO        ├──►LVDS──► pair  ──►─diff RX──►─FPGA──► │  ┌────────────┐  │
   │  10 MHz disc.   │                                        │  │ PPS counter│  │
   └─────────────────┘                                        │  │ 10 MHz × 1s│  │
                                                              │  └──────┬─────┘  │
                                                              │         │        │
                                                              │  ┌──────▼─────┐  │
                                                              │  │ soft-TDC   │  │
                                                              │  │ ECP5 carry │  │
                                                              │  │ chain      │  │
                                                              │  │ ~150 ps    │  │
                                                              │  └──────┬─────┘  │
                                                              │         │        │
                                                              │     event ts     │
                                                              └──────────────────┘
```

**Sources of timing error, end to end:**

| Source | Magnitude | Notes |
|--------|-----------|-------|
| GPS PPS jitter (NEO-M9N) | ±20 ns RMS | dominant on surface side |
| Tether PPS propagation | ±1 ns | 50 m × 5 ns/m, stable so calibrated out |
| LVDS receiver | <100 ps | negligible |
| TCXO holdover drift (1 s between PPS) | <50 ns at ±0.5 ppm | re-disciplined every PPS |
| Soft-TDC quantisation | ±150 ps | ECP5 carry chain |
| ADC sample clock jitter | ~1 ns | LTC6957 or just FPGA-derived clock |
| **Total per-DOM event timestamp** | **~25 ns RMS** | dominated by GPS PPS |

Good enough for cross-DOM coincidence (target < 100 ns window) and far better than needed for mion ToF over the array baseline (~5 m / c_water = 23 ns full traversal).

**Underwater holdover behaviour:** Tether PPS is the discipline source. If tether PPS drops out (transient, lightning, deliberate test), the TCXO drifts at ~0.5 ppm = 0.5 µs/s. The MCU flags PPS-lost in event metadata; downstream analysis can re-align using cross-DOM coincidence with neighbouring known-good DOMs.

## 5. Tether interface — pinout lock

8-pin Subconn Micro (or DIY epoxy gland with equivalent count). **This pinout must match boards 03 (power), 04 (surface aggregator), and the tether cable build.**

| Pin | Function | Direction | Notes |
|-----|----------|-----------|-------|
| 1 | +48 V power | in (from surface) | through TVS + CM choke on board 03 |
| 2 | Power GND | — | tied to chassis at surface end only |
| 3 | Ethernet TX+ (DOM→surface) | out | 100Base-TX, magnetics on board 02 |
| 4 | Ethernet TX− | out | paired with pin 3 |
| 5 | Ethernet RX+ (surface→DOM) | in | |
| 6 | Ethernet RX− | in | paired with pin 5 |
| 7 | PPS+ (LVDS) | in | from board 04 PPS fan-out |
| 8 | PPS− (LVDS) | in | paired with pin 7 |

No PoE — separate copper for power keeps the EMI story simpler and the connector pinout obvious. Tether copper count fits the 8-pin Subconn Micro / DIY gland without needing larger connectors.

## 6. Component values

**Reference clock (10 MHz TCXO → FPGA PLL):**

- Abracon ABLNO-10.000MHZ-T2 (±0.5 ppm, 100 fs jitter typ)
- ECP5 PLL multiplies to 130 MHz for ADC sample clock and 100 MHz for system clock
- Phase noise budget: ADC ENOB drop from clock jitter < 0.1 bit at this jitter level — fine

**Ethernet (LAN8720A + RMII to FPGA):**

- 50 MHz clock from FPGA PLL → PHY (single-clock RMII configuration)
- Direct copper to tether pins 3–6 via small magnetics (Bothhand HX1188NL or equivalent)
- No RJ45 magjack — tether is the cable

**PPS input chain:**

- Differential pair on pins 7–8 → DS90LV019 or similar LVDS receiver → FPGA GPIO
- Termination: 100 Ω across the pair at the receiver

**Slow control I²C to board 01:**

- STM32 I²C2 → 2× pull-ups (3.3 kΩ) → board-to-board connector → MCP4728 + supervisor on board 01
- Bus runs at 100 kHz; HV trim updates every minute, plenty of margin

**Power input split (from board 03):**

- +3.3 V: STM32, FPGA I/O bank, LAN8720
- +1.2 V: FPGA core (Primer 25K module handles this internally from 3.3 V)
- +1.8 V: ADC DVDD, FPGA aux
- +1.8 V analog (separate filter): ADC AVDD
- All rails come pre-conditioned from board 03; on board 02 just local 100 nF + 10 µF bulk per IC.

## 7. Layout

4-layer minimum, likely 6-layer once ADC LVDS routing is in (TBD after schematic — Adam to confirm).

Top-to-bottom proposed stackup:

1. Signal top — components, ADC, FPGA module, MCU module
2. GND plane — solid
3. Power planes — split for analog (1.8 V AVDD) vs digital
4. Signal — LVDS pairs between ADCs and FPGA, matched length within 0.1 mm
5. (if 6-layer) Inner GND
6. (if 6-layer) Signal bottom — slow control, status LEDs, tether breakout

Placement strategy:

- Board-to-board connector to board 01 on left edge
- 2× AD9249 directly to the right of that connector — LVDS pairs go straight up to the FPGA in the centre
- TCXO directly next to the FPGA reference clock pin
- STM32 module on the right side, near the LAN8720 + tether connector
- Tether connector on the right edge

## 8. Open questions

1. **AD9249 sourcing.** Verify LCSC stock at order time. If EOL, fall back to 4× TI ADC3424 (parallel chips, +€20 BOM).
2. **6-layer vs 4-layer.** Driven by LVDS routing density. Adam to confirm after first schematic pass. 4-layer is the goal; 6-layer is the realistic outcome.
3. **STM32 module vs bare H743VIT6.** WeAct STM32H743 module (€20) saves time but is taller. Bare SMT chip is denser but adds risk. Module for v1.
4. **MagJack vs naked twisted pair into Subconn.** No RJ45 — tether termination goes straight to the Subconn pins via on-board magnetics. Verify magnetics work without a chassis ground.
5. **PPS distribution as LVDS or differential RS-422?** LVDS for simplicity (matches the ADC LVDS rails on the same FPGA), but RS-422 has more drive strength for long cables. 50 m of decent twisted pair should be fine for either.

## 9. Failure modes to test for

- **Tether unplugged with power on.** TVS + CM choke on board 03 catches the transient; verify by hot-unplugging on the bench.
- **Lightning surge on tether.** Surface side is the more exposed end; board 04 should have heavier surge suppression. Verify both ends survive a 200 V differential transient.
- **PPS dropout for >10 minutes.** TCXO drifts to ±300 µs; events should still be tagged with a "PPS-lost" flag and a relative timestamp from the last good PPS. Test by killing PPS at the surface and watching the DOM behave.
- **Ethernet link loss.** MCU should buffer up to 10 s of events in RAM and resume transmission when link comes back. Test by unplugging RX pair on the surface side mid-run.
- **ADC clock failure.** FPGA PLL lock-loss should trigger a watchdog reset. Test by removing the TCXO power.
