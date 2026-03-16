# apps/jared-octopus

The head agent. Orchestrates the arms.

Jared is the shipboard AI running on OS-1. In the submarine architecture,
Jared is the head — decomposing tasks, assigning arms, aggregating results.

Each arm is an autonomous OpenClaw instance. The head maintains the task queue,
entity memory, and conflict resolution. Arms execute with autonomy within bounds.

## Architecture

```
apps/jared-octopus/   ← HEAD AGENT (this)
apps/landing/         ← ARM: landing page builder
apps/aquabong/        ← ARM: aquabong (planned)
apps/[future]/        ← ARM: more to come
```

## Spawning Arms

```bash
# Each arm gets a git worktree
git worktree add ../sub-worktrees/landing -b arm/landing
git worktree add ../sub-worktrees/aquabong -b arm/aquabong

# Head assigns tasks via shared task queue (tq_tasks in Neon)
# Arms execute, commit, signal completion
# Head reviews, merges, ships
```

## Memory

- Shared: repo-level CLAUDE.md, ARCHITECTURE.md
- Per-arm: each app's own README
- Head: this file + OS-1 agent memory at ~/clawd/memory/

## Status

HEAD AGENT: Jared (OS-1)
ARMS ACTIVE: 1 (landing)
ARMS PLANNED: 2 (aquabong, TBD)
