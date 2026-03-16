# apps/jared-octopus

The octopus. Head agent + six arms.

Jared is the OS-1 shipboard AI acting as head orchestrator. Each arm is an autonomous agent — independent codebase, independent git worktree, independent deploy.

## Structure

```
apps/jared-octopus/
├── README.md
└── arms/
    ├── landing/           ← ARM 01: project landing page (Hono + anime.js)
    ├── signal-reader/     ← ARM 02: radiotelescope signal acquisition
    ├── power-mgmt/        ← ARM 03: power management and energy budget
    ├── data-logger/       ← ARM 04: observation logging and storage
    ├── calibration/       ← ARM 05: calibration routines
    └── comms-relay/       ← ARM 06: communications relay
```

## ARM Status

| Arm | Purpose | Status |
|-----|---------|--------|
| landing | Project landing page | 🚧 v0.1 in progress |
| signal-reader | Radiotelescope signal acquisition | 📋 Planned |
| power-mgmt | Energy budget management | 📋 Planned |
| data-logger | Observation logging | 📋 Planned |
| calibration | Calibration routines | 📋 Planned |
| comms-relay | Communications relay | 📋 Planned |

## Head Agent

Jared (OS-1). Orchestrates arms, maintains task queue, ships.

## Note

`apps/aquabong/` is a separate project — not a submarine arm.
