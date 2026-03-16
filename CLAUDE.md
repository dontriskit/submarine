# CLAUDE.md — Agent Instructions for the Submarine Project

This file tells AI agents (Claude Code, Codex, etc.) how to work in this repo.
Read this before touching anything.

## Repo Structure

```
submarine/
├── apps/
│   └── jared-octopus/         ← The octopus (head + arms)
│       ├── README.md           ← Head agent spec
│       └── arms/
│           ├── landing/        ← ARM 01: landing page (Hono + anime.js)
│           ├── aquabong/       ← ARM 02: aquabong subapp
│           ├── signal-reader/  ← ARM 03: radiotelescope signal
│           ├── power-mgmt/     ← ARM 04: energy budget
│           ├── data-logger/    ← ARM 05: observation logging
│           └── comms-relay/    ← ARM 06: comms relay
├── ARCHITECTURE.md             ← Multi-agent arm spec
├── CLAUDE.md                   ← This file
└── README.md
```

## Principles

1. **MIT only** — all dependencies must be MIT licensed. No exceptions.
2. **OpenClaw only** for agent framework code — no closed-source runtimes.
3. **ARM64 first** — Dockerfiles target `--platform=linux/arm64`.
4. **Spec before build** — open an issue with WHAT/WHY/DONE before coding.
5. **One arm, one concern** — each arm has a single clear purpose.
6. **Head orchestrates, arms execute** — arms don't assign tasks to each other.

## Working on an Arm

```bash
# Landing page
cd apps/jared-octopus/arms/landing
npm install
npm run dev   # starts on :3000 with --watch
```

## Docker (ARM64)

```bash
cd apps/jared-octopus/arms/landing
docker build --platform linux/arm64 -t submarine-landing .
docker run -p 3000:3000 submarine-landing
```

## Parallel Development with Worktrees

```bash
# One worktree per arm
git worktree add ../worktrees/landing -b arm/landing
git worktree add ../worktrees/aquabong -b arm/aquabong

# Work in isolation, then PR back
# Head agent reviews and merges
```

## Commit Style

```
feat(landing): add sonar animation to hero
feat(aquabong): scaffold app structure
fix(docker): correct WORKDIR path
docs: update arm status table
```

Scope = arm name. Messages under 72 chars.

## Starting a New Arm

1. `mkdir -p apps/jared-octopus/arms/<name>`
2. Write `README.md` with: what it does, why it exists, done criteria
3. Open a GitHub issue
4. Create worktree: `git worktree add ../worktrees/<name> -b arm/<name>`
5. Build, PR, merge
