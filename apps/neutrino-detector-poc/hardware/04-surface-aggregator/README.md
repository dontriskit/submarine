# 04 — Surface aggregator

## WHAT

Topside box. Lives in a Pelican-style case on the RIB or boya. Powers 5 tethers, terminates 5 Ethernet streams into a Raspberry Pi 5 (or equivalent SBC), maintains a master GPS reference with PPS fan-out to each tether, ships aggregated data over LTE to the Hetzner backend.

## WHY its own board

Lives at the surface, not in a DOM. Different ingress protection, antenna routing, battery management, and connector pinout — nothing about it shares constraints with the underwater boards.

## Block

```
                      [GPS antenna ─ mast SMA]
                                │
                                ▼
                       [uBlox NEO-M9N master]
                                │
                                ▼
                     [PPS fan-out NB3N551 ×5]
                                │
        ┌──────────┬────────────┼────────────┬──────────┐
        ▼          ▼            ▼            ▼          ▼
   [tether 1] [tether 2]  [tether 3]   [tether 4]  [tether 5]
   48V + Eth   48V + Eth   48V + Eth    48V + Eth   48V + Eth
        │          │            │            │          │
        └──────────┴───[GbE switch KSZ9897]──┴──────────┘
                              │
                              ▼
                        [Pi5 carrier]
                              │
                              ▼
                   [Quectel EC25 LTE modem] ─► Hetzner
                              │
                       [12 V LiFePO4 battery]
                              │
                       [BQ24650 charger]
```

## Key parts

| Function | Part |
|----------|------|
| Per-tether 48 V eFuse | TI TPS25940 (×5) — current limit, fault flag, slew control |
| 12 → 48 V boost (tether power) | LM5160 |
| PPS fan-out 1:5 LVDS | ON NB3N551 |
| GPS master | uBlox NEO-M9N + active SMA antenna |
| GbE switch | TP-Link TL-SG105 5-port unmanaged (external module, not on PCB) |
| SBC | Raspberry Pi 5 (8 GB) + NVMe HAT + 500 GB SSD (external) |
| LTE modem | Quectel EC25 USB stick or Huawei E3372 (external USB) |
| Battery + charger | 12 V 100 Ah LiFePO4 + BQ24650 MPPT |

No PoE — power and Ethernet are separate copper to each tether (matches board 02 pinout: pins 1–2 power, pins 3–6 Ethernet, pins 7–8 PPS).

## Gotchas

- **GPS antenna on the RIB mast**, not in the box. Coax with SMA bulkhead through the case.
- **LTE antenna diversity** matters offshore — two SMA jacks, place them >λ/2 apart on the case lid.
- **Ground the case to the RIB hull** or accept that EMI from the outboard motor will couple into the analog side via the tether shield.
- **Battery sizing:** 12 V 100 Ah at ~5 W per DOM × 5 + 10 W Pi/LTE = 35 W; ~25 hours endurance. Adequate for typical deploy day with margin.

## DONE

- 5 simultaneous Ethernet streams to the Pi at ≥ 10 Mbit/s sustained.
- PPS skew across the 5 outputs < 5 ns (measured with scope, single-shot persistence).
- 6-hour run on battery while ingesting all 5 streams and uplinking to Hetzner via LTE.
- Survives a wave-spray test (IP65-ish — gaskets + breather, not full submersion).
