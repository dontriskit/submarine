# apps/jared-octopus

The octopus. Head agent + six arms.

Jared is the OS-1 shipboard AI acting as head orchestrator. Each arm is an autonomous agent — independent codebase, independent git worktree, independent deploy. The head decomposes tasks, assigns arms, resolves conflicts, ships.

## Structure

```
apps/jared-octopus/
├── README.md              ← This file (head agent spec)
├── arms/
│   ├── landing/           ← ARM 01: project landing page (Hono + anime.js)
│   ├── aquabong/          ← ARM 02: aquabong subapp (spec TBD)
│   ├── signal-reader/     ← ARM 03: radiotelescope signal acquisition (planned)
│   ├── power-mgmt/        ← ARM 04: power management and energy budget (planned)
│   ├── data-logger/       ← ARM 05: observation logging and storage (planned)
│   └── comms-relay/       ← ARM 06: communications relay (planned)
```

## How Arms Work

Each arm is an isolated subproject:
- Own `package.json` scoped as `@submarine/arm-<name>`
- Own `Dockerfile` targeting `linux/arm64`
- Own git worktree when developing in parallel: `git worktree add ../worktrees/arm-landing -b arm/landing`
- Communicates with head via shared Neon task queue (`tq_tasks`)
- Deploys independently

## Head Agent Protocol

1. **Decompose** — break project goals into arm-sized tasks
2. **Assign** — each task goes to the right arm (or spawns a new one)
3. **Monitor** — arms signal completion via task queue
4. **Merge** — head reviews, resolves conflicts, ships
5. **Memory** — shared CLAUDE.md + per-arm README, head maintains `~/clawd/memory/`

## Starting a New Arm

```bash
# 1. Create the arm directory
mkdir -p apps/jared-octopus/arms/<name>

# 2. Add README with spec (what, why, done criteria)
# 3. Open a GitHub issue before building
# 4. Create worktree for parallel dev:
git worktree add ../worktrees/<name> -b arm/<name>

# 5. Build, commit, PR back to main
```

## ARM Status

| Arm | Purpose | Status |
|-----|---------|--------|
| landing | Project landing page | 🚧 v0.1 in progress |
| aquabong | Aquabong subapp | 📋 Spec needed |
| signal-reader | Radiotelescope signal acquisition | 📋 Planned |
| power-mgmt | Energy budget management | 📋 Planned |
| data-logger | Observation logging | 📋 Planned |
| comms-relay | Communications relay | 📋 Planned |

## Head Agent: Jared

Running on OS-1. Memory at `~/clawd/memory/`. Entity files at `~/clawd/memory/entities/`.
Communicates via WhatsApp (TRIBE group) and Neon Postgres (`tq_messages`).

This project started as a Sunday evening conversation. It's going somewhere real.
