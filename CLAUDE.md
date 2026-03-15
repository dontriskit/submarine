# CLAUDE.md — Agent Instructions for the Submarine Project

This file tells AI agents (Claude Code, Codex, etc.) how to work in this repo.

## Repo Structure

```
submarine/
├── apps/
│   ├── landing/          ← Landing page (Hono + anime.js)
│   │   ├── src/
│   │   │   ├── index.js
│   │   │   └── public/index.html
│   │   ├── Dockerfile    ← ARM64 compatible
│   │   └── package.json
│   └── aquabong/         ← Future: aquabong subapp (TBD)
├── ARCHITECTURE.md       ← Multi-agent arm spec
├── CLAUDE.md             ← This file
├── README.md
└── package.json          ← Monorepo root (npm workspaces)
```

## Principles

1. **MIT only** — all dependencies must be MIT licensed. No exceptions.
2. **OpenClaw only** for agent framework code — no closed-source agent runtimes.
3. **ARM64 first** — Dockerfiles must target `--platform=linux/arm64`. Test on ARM.
4. **No single-file dumping** — each app lives in `apps/<name>/`. Don't put app code at repo root.
5. **Spec before build** — for anything non-trivial, write a brief spec in the relevant issue before coding.

## Working on the Landing Page

```bash
cd apps/landing
npm install
npm run dev        # starts on :3000 with --watch
```

**Sections** (in order): hero → mission → architecture → protocol → milestones → cta

Each section is a standalone `<section id="...">` block. When improving a section:
- Touch only that section's HTML + its scoped CSS/JS
- Don't break other sections
- Use anime.js (already loaded via CDN) for all animations
- Test that the page still loads before committing

## Docker

```bash
cd apps/landing
docker build --platform linux/arm64 -t submarine-landing .
docker run -p 3000:3000 submarine-landing
```

## Multi-Agent Architecture

This repo uses a multi-agent git worktree pattern for parallel section development:

```bash
# One worktree per section
git worktree add ../sub-worktrees/hero -b section/hero
git worktree add ../sub-worktrees/mission -b section/mission
# etc.

# Each agent works in its worktree independently
# Head agent merges best work from each into the main branch
```

See ARCHITECTURE.md for the full agent swarm spec.

## Adding a New App

```bash
mkdir -p apps/<name>/src
# Add package.json with name "@submarine/<name>"
# Add to root package.json workspaces if needed
# Add Dockerfile targeting linux/arm64
# Open a GitHub issue before building
```

## Commit Style

```
feat(landing): add sonar animation to hero
feat(arch): animated agent swarm diagram
fix(docker): correct WORKDIR path
docs: update README with aquabong plans
```

Scope = app or section name. Keep messages under 72 chars.

## Open Issues Worth Picking Up

- [ ] #2 — Architecture spec (merged)
- [ ] #4 — Landing page v0.1 (in progress)
- [ ] aquabong subapp (no issue yet — open one first)
