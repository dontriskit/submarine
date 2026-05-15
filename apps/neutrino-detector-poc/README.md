# neutrino-detector-poc

Hardware + firmware + DAQ for the 5-DOM underwater Cherenkov detector PoC.

Part of the Meridian project (see `~/.claude/projects/-home-mhm-projects-submarine/memory/project_meridian.md` for the full strategic context). Currently parked while Maksym finishes the SaaS work; this tree is the seed for the eventual Meridian repo.

## Scope

5 Digital Optical Modules (DOMs) + 1 surface aggregator + 1 bench LED calibrator. Deploy at Prasonisi (Rhodes) ~40 m depth. Goal: prove the architecture by measuring atmospheric muons against the Gaisser parametrization and ⁴⁰K rate against seawater radiochemistry, before scaling.

## Layout

- `hardware/` — KiCad projects for the 5 PCB designs (see `hardware/README.md`)
- `firmware/` — STM32 + Tang Nano sources (TODO)
- `daq/` — ground-side acquisition + analysis pipeline (TODO)

## Toolchain

- KiCad 9.0.9.x (latest stable as of 2026-05-14)
- JLCPCB for fab + SMT assembly of passives
- LCSC for components (Onsemi SiPMs, TI/ADI ICs)
- Hetzner CCX22 for the backend DAQ + storage

## Status

Specs only. No schematics drawn yet. Components not ordered. Next step: WHAT/WHY/DONE per board (per the repo's "spec before build" rule), then KiCad schematics.
