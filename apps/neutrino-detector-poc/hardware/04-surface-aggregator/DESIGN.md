# 04 — design notes

Engineering layer below the README. Topside box architecture, integration choices.

## 1. Architectural decisions

1. **Most "system" parts are off-the-shelf modules in the Pelican case, not on this PCB.** The custom PCB handles only: tether power injection × 5, GPS + PPS fan-out, breakout to Pi/switch. Pi 5, GbE switch, LTE modem stay as discrete modules connected by short patch cables. This keeps the custom PCB small, cheap, and easy to respin.
2. **No PoE.** Power and Ethernet are separate copper to each tether (matches board 02 pinout). Simpler EMI story, obvious wiring.
3. **Battery: 12 V LiFePO4, boost to 48 V for tether output.** Cheap, common, safe. 12 V is also the native rail for the Pi 5 carrier.
4. **GPS: uBlox NEO-M9N.** ±20 ns RMS PPS jitter is the dominant timing error in the whole chain. NEO-F9P would halve it for ~€20 more — defer to v2.

## 2. System block

```
                    GPS antenna (mast SMA)
                              │
                              ▼
                       [uBlox NEO-M9N]
                              │
                          PPS │ (LVCMOS 3.3V)
                              ▼
                       [NB3N551 LVDS buffer + fan-out ×5]
                              │
                  ┌───────────┼───────────┐
                  ▼           ▼           ▼      ... × 5
              tether 1    tether 2    tether 3
              ┌───────┐   ┌───────┐   ┌───────┐
              │ +48V  │   │ +48V  │   │ +48V  │
              │  GND  │   │  GND  │   │  GND  │
              │ Eth±  │   │ Eth±  │   │ Eth±  │
              │ PPS±  │   │ PPS±  │   │ PPS±  │
              └───────┘   └───────┘   └───────┘
                  │ × 5
                  │
        [TPS25940 eFuse per tether]
                  │
                  ▼
   12V→48V boost ─►──[5× outputs, 250mA limit each]
   (LM5160 or TPS55340)

                                          ┌───────────────┐
   12V battery in (LiFePO4 100Ah) ────────►│ BQ24650       │
                                          │ MPPT charger  │◄── solar / boat 12V
                                          └───────┬───────┘
                                                  │
                                            12V_battery bus
                                                  │
                              ┌───────────────────┼──────────────────┐
                              ▼                   ▼                  ▼
                       12V→5V buck         12V→48V boost     12V→3.3V buck
                       (Pi5 + switch)      (tether power)    (GPS, LVDS bufs)

   Pi 5 ──USB3──► [Quectel EC25 USB modem] ──► LTE ──► Hetzner
   Pi 5 ──Eth───► [TP-Link 5-port unmanaged GbE switch] ◄── 5 tethers
```

## 3. Tether output stage (×5)

Each tether output is identical:

```
   12→48V boost bus (single supply)
                │
                ▼
   [TPS25940 eFuse: 48V, 250mA limit, slew control, fault flag]
                │
                ▼
   [TVS SMBJ58A] [CM choke 744232511]
                │
                ▼
        tether pin 1 (+48V) ─ to DOM
        tether pin 2 (GND)  ─ to DOM
```

The eFuse per tether means a short on tether N doesn't take down tethers 1..N−1. Fault flag from each eFuse goes to the Pi 5 GPIO via I²C expander — Pi logs which tether tripped and surfaces it in the dashboard.

Ethernet pairs to each tether go through TVS arrays (SP3012-06) and small CM chokes, then to the switch via short Cat6 patch cables.

## 4. PPS fan-out

GPS module emits 1 PPS as LVCMOS 3.3 V. We need to deliver it as differential LVDS to 5 tethers with minimum skew across outputs.

```
   GPS PPS (LVCMOS) ──► [SN65LVDS1 driver]
                              │
                              ▼
                     [NB3N551 1:5 LVDS fan-out]
                              │
              ┌───────┬───────┼───────┬───────┐
              ▼       ▼       ▼       ▼       ▼
            tether tether tether tether tether
              1     2     3     4     5  (each is a diff pair on pins 7–8)
```

NB3N551 spec: < 50 ps output-to-output skew, < 100 ps jitter. After 50 m of twisted pair, signal arrival at each DOM is dominated by cable length variation (verify all 5 cables are within 10 cm = 500 ps electrical) — not the buffer.

**Calibrate out the absolute cable delay per tether** by sending a known-time round-trip ping at deploy and measuring the per-DOM offset. Store as a per-DOM constant in the analysis pipeline.

## 5. Power architecture

| Path | Source | Sink | Converter |
|------|--------|------|-----------|
| Charge battery | Boat 12 V or solar 18 V | 12 V LiFePO4 | BQ24650 MPPT |
| Pi 5 + switch | 12 V battery | 5 V @ 5 A | LMR33630 |
| GPS + buffers | 12 V battery | 3.3 V @ 500 mA | TPS62933 |
| Tether power | 12 V battery | 48 V @ 1.5 A (5 DOMs) | LM5160 boost |

**Battery sizing:** 12 V 100 Ah LiFePO4 = 1.2 kWh. Load budget:
- 5 DOMs at 10 W = 50 W
- Pi 5 + switch + LTE = 15 W
- Misc = 5 W
- Total = ~70 W → 17 hours endurance

Plenty for a typical deploy day; recharge between days from a generator or the RIB's alternator.

## 6. GbE switch and Pi5 — module selection

| Component | Pick | Why |
|-----------|------|-----|
| GbE switch | TP-Link TL-SG105 (5-port unmanaged) | €15, well-shielded metal case, runs on 5 V, can power from Pi USB or own DC jack |
| Pi 5 carrier | Pi 5 8 GB + Pimoroni NVMe HAT + 500 GB SSD | local buffer for tens of hours of event data |
| LTE modem | Quectel EC25 USB stick (or Huawei E3372) | USB is simpler than mini-PCIe for the v1 box; outdoor antennas via SMA |

The custom PCB doesn't include these — it includes a short pigtail to each (USB-A for LTE, RJ45 for Pi-to-switch, 5 V power-out to switch and Pi).

## 7. Layout

The custom PCB is the smallest of the five — only the tether power/eFuse stages, PPS fan-out, GPS module socket, and breakouts.

4-layer, 100 × 80 mm.

Component zones:

- Left: 5 tether output blocks (TPS25940 + TVS + CM choke + tether connector)
- Centre: 12→48 V boost and 12→5 V/3.3 V bucks
- Top-right: GPS module socket + NB3N551 + LVDS fan-out
- Bottom-right: I²C expander for eFuse status + RJ45 breakout for the 5 Ethernet pairs to the external switch
- Bottom-left: 12 V battery input, BQ24650 charger

## 8. Mechanical (Pelican case)

Single 18 × 13 × 7 in. Pelican-style case (1450 form factor):

- Lid: GPS antenna SMA, 2× LTE antenna SMA, status LED window
- Front: power switch, 5× Subconn tether bulkhead connectors
- Inside: PCB on standoffs, Pi 5 on its NVMe HAT, GbE switch, LTE modem, 12 V 100 Ah battery (heavy — at the bottom)
- Breather valve for pressure equalisation (Pelican includes it; don't seal it shut)

Mass ~15 kg with battery. Carry handle ratings are fine; one person can wrangle it onto the RIB.

## 9. Open questions

1. **Single 12 V LiFePO4 vs 4S 12V (48 V native)?** 48 V native skips the boost stage (€10 saved + better efficiency) but costs more in battery and BMS complexity. For v1 stick with 12 V — common, safe, well-understood.
2. **Pi 5 vs CM5 carrier?** Pi 5 board itself ~€80, easy. CM5 needs a carrier board (more PCB work). Pi 5 for v1.
3. **GbE switch internal vs external module?** Designing a KSZ9897-based switch onto this PCB is non-trivial (impedance control on 5 RGMII ports). External €15 module saves a week. External for v1.
4. **Antenna placement.** GPS needs unobstructed sky; LTE diversity needs spatial separation. Lid-mounted with the case oriented so the lid faces up.

## 10. Failure modes to test for

- **Single tether short.** eFuse trips, others continue, Pi 5 logs the fault. Test by deliberately shorting tether output pins.
- **GPS antenna disconnect.** PPS stops; downstream DOMs go into TCXO holdover. Pi sends alert via LTE. Test by unscrewing the SMA on a running system.
- **LTE outage.** Pi buffers events to local SSD; resumes when link returns. Test by airplane-mode toggling the modem.
- **Battery low.** Pi reads via BQ24650 I²C; sends warning at 20%, graceful shutdown at 5%. Test on the bench.
- **Wave spray ingress.** Pelican case + breather + cable glands. Test with garden-hose simulation before any sea trial.
