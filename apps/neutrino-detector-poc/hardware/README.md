# hardware

Five PCB designs for the DOM PoC. Each subdirectory is a self-contained KiCad 9 project.

| Dir | Per PoC | Function |
|-----|---------|----------|
| `01-sipm-frontend/` | ×5 | 16-channel SiPM bias + preamp + shaping |
| `02-mainboard/` | ×5 | MCU/FPGA carrier, GPS sync, TDC, Ethernet, tether breakout |
| `03-power/` | ×5 | Isolated DC-DC rails, surge/ESD, watchdog |
| `04-surface-aggregator/` | ×1 | PoE-style power injection, Pi5 carrier, LTE, master PPS fan-out |
| `05-led-pulser/` | ×1 (bench) | ns-pulsed 450 nm calibrator |

## Fab order strategy

- JLCPCB, 5 PCBs/design minimum, ~$10–25 per design including SMT assembly of passives.
- Order 2× spares of `01-sipm-frontend` and `02-mainboard` — likeliest to need a revision.
- Total PCB fab cost across the set: under €500. Components dominate (SiPM, FPGA modules, connectors).

## Per-board layout

```
NN-board-name/
├── README.md                — WHAT / WHY / KEY PARTS / GOTCHAS / DONE
├── BOM.csv                  — component list with LCSC part numbers (when known)
├── NN-board.kicad_pro       — KiCad project (create via File → New Project pointing here)
├── NN-board.kicad_sch
├── NN-board.kicad_pcb
└── fab/                     — generated Gerbers (gitignored except .gitkeep)
```

## Spec-before-build

Per the repo's CLAUDE.md rule, before drawing any schematic write WHAT/WHY/DONE into the board's README and open a GitHub issue. The README stubs already have the structure.

## KiCad version pin

KiCad ≥ 9.0.9, < 10. File format upgrades from 9.x → 10.x are one-way; collaborators on 9.x cannot reopen a file once it has been saved by 10.x.

## Tools in this directory

| File | Purpose |
|------|---------|
| `gallery.html` | Magazine-style concept SVG renders of all 5 boards. Open directly in a browser; no server needed. |
| `viewer.html` | Live in-browser viewer that parses each board's `.kicad_pcb` and renders to SVG. Run `python3 -m http.server 8765` here, then open `http://localhost:8765/viewer.html`. Drag-and-drop a `.kicad_pcb` onto any board for a transient preview. |
| `Makefile` | User-facing entry point. `make fab` builds all five boards' fab artefacts; `make fab-01` builds one. Auto-detects local `kicad-cli`, falls back to Docker if unavailable. `make help` lists targets. |
| `Dockerfile` | Self-contained KiCad 9.0.9 build environment (Ubuntu 24.04 + KiCad PPA). Built once via `make image`, then used by the Makefile's Docker fallback path. No third-party CI required. |
| `make-fab.sh` | The underlying script that calls `kicad-cli` for Gerber + drill + pick-and-place export. Invoked by the Makefile, can also be run directly. |
| `FAB.md` | What manufacturers want, how to verify before sending, JLCPCB ordering parameters, design rules to stay inside, local-vs-Docker build path. |

## End-to-end flow when work resumes

```
[Adam in KiCad]                   ./make-fab.sh           [upload to JLCPCB]
   schematic ───►   PCB ───►   Gerber + drill + CPL ───►   boards arrive
   .kicad_sch    .kicad_pcb       fab/  +  *.zip
```

Each step is committed to git. Tag the PCB commit (`pcb/01/v1.0`) before ordering so the fab artefacts are reproducible from source.
