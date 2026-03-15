i'm thinking of a vessel that can explore, transport, extract, search, guide, help, rescue, clean,

working prototype idea? small 3d printed.

the goal is to bridge gaps between continents as well as clean the oceans before it is too late.

milestones:

- [] first submarine deployed
- [] first water sample collected
- [] first drone launched from one of autonomous submarines
- [] first submarine controlled by the ai agent
- [] first submarine to discover floating debris/trash
- [] first submarine to extract something solid and bring back to dock
- [] first mind-controlled submarine

---

## Multi-Agent Development Architecture

This project is built using a multi-agent git worktree pattern — the same architecture the submarine itself will use.

**How it works:**

```
Head Agent (orchestrator)
├── section/hero         ← Agent 1 (git worktree)
├── section/mission      ← Agent 2 (git worktree)
├── section/architecture ← Agent 3 (git worktree)
├── section/protocol     ← Agent 4 (git worktree)
├── section/milestones   ← Agent 5 (git worktree)
└── section/cta          ← Agent 6 (git worktree)
```

Six AI agents work in parallel on separate branches, each owning one section of the landing page. The head agent merges the best work. No conflicts. No bottlenecks.

The submarine's physical arms will follow the same pattern — each arm is an autonomous OpenClaw agent, communicating with the head via MCP. The code architecture *is* the hardware architecture.

See [ARCHITECTURE.md](ARCHITECTURE.md) and [issue #2](https://github.com/dontriskit/submarine/issues/2) for the full spec.

## Apps

| App | Description | Status |
|-----|-------------|--------|
| `apps/landing` | Project landing page (Hono + anime.js) | 🚧 v0.1 |
| `apps/aquabong` | Aquabong subapp | 📋 Planned |

## CLAUDE.md

AI agents working in this repo should read [CLAUDE.md](CLAUDE.md) first.
