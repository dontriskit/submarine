# 01 — design notes

Engineering layer below the README. Numbers, circuit choices, calculations.

## 1. SiPM operating point

Onsemi MicroFJ-30035 (3.07 × 3.07 mm active area, 5676 microcells, 35 µm pitch):

| Parameter | Value | Source |
|-----------|-------|--------|
| Breakdown voltage Vbr | ~24.5 V @ 25 °C | datasheet typ |
| Recommended overvoltage Vov | 2.5–6 V | datasheet |
| **Operating Vbias** | **27 ± 0.5 V** (Vov = 2.5 V) | choose for low DCR at room temp |
| Gain @ Vov = 2.5 V | ~3 × 10⁶ | datasheet |
| Single-PE charge | q × gain = 1.6e-19 × 3e6 = **0.48 pC** | derived |
| PDE @ 450 nm | ~40% | datasheet |
| Dark count rate | ~50 kHz/mm² @ 25 °C | datasheet, dominant background |
| Temp coefficient of Vbr | +21.5 mV / °C | datasheet |

Prasonisi seabed is ~16 °C, stable. Single trim at deploy temperature is enough for PoC. v2 adds thermistor + DAC compensation.

## 2. Per-channel circuit

Keep it simple — we don't need single-PE resolution for the PoC, we need clean muon pulses. Skip the analog shaper, do shaping digitally on the 125 MSPS samples from board 02.

```
        +27V HV bus
            │
         [1k Ω] ── current limit + decouple from neighbors
            │
         [100 nF + 10 nF] ── per-channel HV decoupling
            │
         ┌──┴──┐
         │ K   │  SiPM cathode (HV)
         │     │  (MicroFJ-30035)
         │ A   │  SiPM anode
         └──┬──┘
            │
         [50 Ω] ── termination to GND (fast pulse readout)
            │
         [100 nF AC-couple]
            │
            ▼
       LMH6629 ── non-inverting, gain = 20 (Rf=1k, Rg=52)
            │
            ▼
       THS4541 ── single-to-diff, gain = 1
            │
            ▼
       diff pair to mainboard (board 02)
```

## 3. Component values

**TIA / amplifier stage (LMH6629):**

- Gain G = 1 + Rf/Rg = 1 + 1000/52 ≈ **20 V/V**
- LMH6629 GBW = 4 GHz; closed-loop BW at G=20 ≈ 200 MHz (plenty for SiPM ~1 ns rise)
- Single-PE pulse: peak current ≈ q × gain × g_m_fastcomp / τ_fast ≈ ~25 µA across 50 Ω = 1.25 mV at amplifier input → **25 mV at amplifier output**
- Atmospheric muon through SiPM coupling glass: ~50–200 PE → 1.2–5 V at output → use diff driver to clip cleanly at ADC input range

**Diff driver (THS4541):**

- Gain 1, output range ±2 V differential → matches mainboard ADC ±1 V single-ended × 2 inputs
- Common-mode at 0.9 V (ADC VREF/2)

**HV decoupling per channel:**

- 1 kΩ series + 100 nF + 10 nF gives ~10 µs RC → blocks crosstalk between channels at pulse timescales
- Drop across 1 kΩ at quiescent current (~100 nA dark, ~3 µA under typical sky) = negligible

**HV bias supply (LT3494):**

- Input +12 V (from board 03), output +30 V, max load = 16 × 5 µA = 80 µA (very light)
- Two-stage RC filter on output: 100 Ω + 10 µF, then 100 Ω + 1 µF → < 1 mV ripple at 10 kHz
- HV ripple couples 1:1 into SiPM bias, so this is the most important filter on the board.

**Bias trim (MCP4728):**

- 12-bit, 0–2.048 V output → fed into LT3494 FB pin via summing resistors
- Gives ~0.5 mV resolution on +30 V output → fine for ±0.1 °C-equivalent trim

## 4. Layout

4-layer stackup (top to bottom):

1. **Signal top** — SiPMs + their decoupling + per-channel amp + diff driver
2. **GND plane** — solid, no breaks
3. **Power plane** — split into +5 V analog, +27 V HV (heavy stitching, large keepout from analog ground)
4. **Signal bottom** — routing for diff pairs to connector, I²C + DAC trim

Physical layout:

- 16 SiPMs in a 4×4 grid, 8 mm pitch (matches Vitrovex 13" sphere inner curvature; for DIY aluminum cylinder, just keep the grid flat in the optical window)
- Per-channel amp directly under or beside its SiPM — TIA input trace < 5 mm
- HV bus as a grid on layer 3 with stitched vias every 5 mm
- Guard rings around HV nets on layer 1 (top), tied to local GND
- Diff pairs to connector routed on layer 4, matched length within 0.1 mm, 100 Ω differential impedance

## 5. Expected performance

- **Single-PE SNR:** ~20 mV signal vs ~3 mV op-amp noise floor (LMH6629, 200 MHz BW) → SNR ≈ 7. Comfortable for PoC.
- **Muon trigger threshold:** set at ~5 PE equivalent (=100 mV at output) → suppresses dark counts (negligible above ~3 PE since DCR is Poisson) while catching all minimum-ionising muons through the SiPM window.
- **Channel-to-channel crosstalk:** target < 1% at single-PE amplitude. Limited by HV bus impedance + GND plane integrity. The 1 kΩ per-channel series resistor is the main mitigation.
- **Bandwidth:** ~200 MHz. SiPM rise time ~1 ns is preserved through the chain; ADC at 125 MSPS (8 ns/sample) is the bandwidth limit downstream, not the analog board.

## 6. Open questions

1. **OPA858 vs LMH6629?** OPA858 has lower input voltage noise (2.3 nV/√Hz vs 3.0 nV/√Hz) but is harder to stabilize at low gain. For PoC stick with LMH6629; revisit for v2 if SNR matters.
2. **Optical coupling between SiPM and water.** Are we potting the SiPMs against the housing's optical window in silicone gel, or air gap? Affects PDE by ~10–15%. Decide before mechanical design freezes.
3. **Single-ended bias trim per SiPM, or one bus voltage for all 16?** Single bus is simpler and likely fine at the stable seabed temperature. Per-SiPM trim is v2.
4. **Magnetic shielding.** Earth's field affects SiPM gain by < 0.1 % — skip for PoC.

## 7. Failure modes to test for

- **HV soft-start:** sudden 0 → 27 V at power-on can latch the LT3494; add 100 ms soft-start RC on the FB pin.
- **Tether reverse polarity:** TVS on board 03 catches this. Verify before deploy.
- **SiPM under-voltage:** if Vbias drops below Vbr the SiPM stops detecting — make the bias supervisor (on board 03) trip if HV < 25 V.
