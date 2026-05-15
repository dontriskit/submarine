# 03 — design notes

Engineering layer below the README. Power topology, rail budgets, noise targets.

## 1. Power budget per DOM

| Consumer | Rail | Current | Power |
|----------|------|---------|-------|
| LMH6629 × 16 (board 01 TIA) | +5 V_a | 16 × 5 mA = 80 mA | 0.4 W |
| THS4541 × 16 (board 01 diff drv) | +5 V_a | 16 × 30 mA = 480 mA | 2.4 W |
| LT3494 HV boost (board 01) | +12 V_a | 5 mA + losses | 0.2 W |
| AD9249 × 2 (board 02 ADC) | +1.8 V_a | 2 × 230 mA = 460 mA | 0.8 W |
| Tang Primer 25K (board 02 FPGA) | +5 V_d | ~600 mA | 3.0 W |
| STM32H743 module (board 02) | +3.3 V_d | ~300 mA | 1.0 W |
| LAN8720 PHY (board 02) | +3.3 V_d | 70 mA | 0.2 W |
| Misc (supervisors, LDOs) | various | — | 0.4 W |
| **Total** | | | **~8.4 W** |

Add ~20% margin → **10 W per DOM**. At 48 V tether → 210 mA per DOM.

## 2. Topology

Single isolated brick 48 V → 12 V, then non-isolated POL bucks for the remaining rails. Separate analog and digital pathways downstream.

```
   tether +48V ──► [TVS SMBJ58A] ──► [CM choke 744232511] ──► [bulk 10µF×4]
                                                                    │
                                                                    ▼
                                                       [Mornsun K7812-3000R3]
                                                          48→12V, 36W iso
                                                                    │
                                                          12V_iso (≈ chassis-isolated)
                                                                    │
              ┌────────────────────┬───────────────────┬────────────┴──────────┐
              ▼                    ▼                   ▼                       ▼
         [LMR33630]           [LMR33630]          [LMR33630]              [bypass]
          → +5 V_a              → +5 V_d           → +3.3 V_d              → +12 V_a
          (board 01)            (board 02)         (board 02)              (board 01 HV boost)
                                                       │
                                                       ▼
                                                 [LT3045 LDO]
                                                   → +1.8 V_a
                                                   (board 02 ADCs)
```

Rationale:

- **Isolated brick** breaks the surface↔DOM ground loop. Mandatory for low-noise analog.
- **POL bucks per rail** (one IC family, LMR33630 or TPS62933) for the heavy lifters.
- **LDO for +1.8 V_a** because the ADCs are the most noise-sensitive consumer and ~150 mA is in LDO range without excessive heat. LT3045 (low-noise LDO) sits downstream of the +3.3 V buck.

## 3. Rails — targets

| Rail | Voltage | Current | Ripple target | Noise target | Sourced via |
|------|---------|---------|---------------|--------------|-------------|
| +12 V_a | 12.0 ±0.3 V | 50 mA | < 20 mVpp | < 2 mVrms 1kHz–10MHz | direct from isolated brick + LC filter |
| +5 V_a | 5.0 ±0.1 V | 600 mA | < 10 mVpp | < 1 mVrms | LMR33630 + LC + bulk |
| +5 V_d | 5.0 ±0.2 V | 600 mA | < 50 mVpp | — | LMR33630, no extra filter |
| +3.3 V_d | 3.3 ±0.1 V | 400 mA | < 50 mVpp | — | LMR33630 |
| +1.8 V_a | 1.80 ±0.02 V | 500 mA | < 5 mVpp | < 0.5 mVrms | LT3045 LDO from +3.3 V |

The two analog rails get LC post-filters (10 µH + 100 µF) downstream of the buck to chew ripple at the buck switching frequency (typ. 400 kHz–2 MHz).

## 4. Isolated brick selection

Mornsun K7812-3000R3:
- 36–75 V in → 12 V out, 3 A, 36 W
- 1.5 kV isolation
- ~82% efficiency at 600 mA load → ~1 W in the brick itself, dissipated as heat
- Through-hole SIP8 footprint; thermal pad to housing wall via M3 stud

Alternative: RECOM RPM30-4812SH (SMT, easier production) — same envelope, slightly more expensive (~€18 vs €12).

## 5. Supervisor and watchdog

ICL7665 dual-threshold supervisor monitors +3.3 V_d and +1.8 V_a:
- Below 3.1 V or 1.7 V → assert RESET line to STM32 (it forwards to FPGA)
- Hold reset for 200 ms after recovery (RC delay)
- One LED per rail on the board (during bench bringup; covered for deploy)

Independent: bias supervisor for board 01's HV rail. If HV < 25 V (below SiPM breakdown), board 03 trips a `bias_fault` line to the MCU; SiPMs aren't generating signals anyway, but flagging the fault is cleaner than silent dropout.

## 6. Thermal

~2 W total dissipation on board 03 in steady state (mostly the isolated brick + bucks). Pelican-case-shaped DOM at 16 °C ambient → component ΔT < 30 °C with passive PCB heatspreading. Pour ground copper aggressively under the brick and POL ICs. If any IC runs > 70 °C in bench testing, add a thermal pad to the aluminum housing wall.

## 7. Layout

4-layer, conservative:

1. Signal top — POL ICs, decoupling, supervisor
2. GND plane — solid
3. Power plane — split into zones for each rail (no overlap; copper pours per rail)
4. Signal bottom — supervisor logic, LEDs, board-to-board breakout

Critical placement:

- Isolated brick at one edge (the "dirty" side), thermal pad to housing wall
- POLs grouped, with their inductors on the dirty side
- LC post-filters at the boundary between POL zone and clean output
- Board-to-board connector on the opposite edge — clean side
- HV monitor sense line (from board 01 HV bus) routed to a dedicated comparator near the supervisor

## 8. Open questions

1. **Isolated brick: through-hole vs SMT?** SMT (RPM30) is friendlier to assembly but harder to thermal-pad to the housing. Through-hole (K7812) is uglier but easier to mount. Probably through-hole for v1.
2. **Common ground tie point.** Iso brick's secondary GND ties to chassis (housing) at exactly one point. Where? Suggest right under the brick, with a single M3 bolt to the housing. Verify no ground loops at deploy.
3. **+5 V analog and +5 V digital — share or split?** Splitting costs an extra POL (~€5). Sharing risks digital noise into op-amp rails. For v1 split them; if measurements show negligible coupling, collapse in v2.

## 9. Failure modes to test for

- **Tether reverse polarity.** TVS catches it; verify by deliberately swapping +48 V/GND on the bench. Brick survives.
- **Tether short on +48 V.** Brick should current-limit / shut down; verify SCP behaviour. Surface side (board 04) eFuse should trip.
- **Single rail collapse.** Pull one POL's enable low; verify supervisor reset propagates and the FPGA/MCU come back cleanly.
- **Thermal soak.** 48 h at full load in a sealed dummy housing at 25 °C ambient; all ICs < 75 °C, all rails in spec.
- **Inrush at power-on.** Verify surface-side breaker doesn't trip when 5 DOMs come on simultaneously. Soft-start the brick with a 22 µF cap on its UVLO pin.
