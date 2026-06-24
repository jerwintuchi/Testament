# Technical — Stack & Deployment

> **Status:** Canon (summary — authoritative source is DECISION_LOG.md + configs)
> **Sources:** DECISION_LOG.md (stack, renderer, test runner, deployment, PWA, browser-only entries)
> **See also:** [technical/architecture.md](architecture.md) · [ui-style-guide.md](../ui-style-guide.md) · [progression.md](../progression.md)

## Stack

| Concern | Choice | Notes |
|---------|--------|-------|
| UI / lobby | **React** | hosted on Vercel |
| Game canvas | **Phaser 3 (WebGL)** | 2D top-down twin-stick; primitive shapes for now (no sprite sheets) |
| Server | **Node + Socket.io** | hosted on Fly.io; authoritative |
| DB | **Supabase** | meta-progression + auth only; never touches active runs |
| Package manager | **pnpm workspaces** | `src/server`, `src/client`, `src/shared`; `@veins/shared` reference |
| Tests | **Vitest** | all packages; native ESM, fast |

**Renderer:** Phaser chosen over 3D (Three/Babylon) — 3D adds load time, asset budget, and payload with no gameplay benefit for a top-down crawler.

## Algorithms

- **Pathfinding:** A* on the dungeon tile grid.
- **Collision:** spatial hashing (O(1) average) for enemy-count scaling.
- (Detail in [systems/combat.md](../systems/combat.md) and [determinism-and-rng.md](determinism-and-rng.md).)

## Deployment

- **Server → Fly.io** via Docker (Node 20 + `tsx` runtime for ESM TypeScript). Fly.io stays alive on WebSockets (unlike Render, which spins down). `tsx` handles `@veins/shared` `.ts` source imports at ~100ms startup — acceptable for a 20–40 min session game. Listens on `process.env.PORT || 3001`.
- **Client → Vercel** via Vite static build. `VITE_SERVER_URL` points at the Fly.io URL.
- **Browser-only, no app stores** — avoids store fees, review delays, and platform-policy risk. SSL is free (Let's Encrypt via Vercel + Fly.io); custom domain optional.

## PWA / mobile fullscreen

`manifest.json` with `"display": "standalone"` + iOS meta tags lets users add the game to their home screen and play without browser chrome. Chosen over the Fullscreen API (blocked on iOS Safari for non-video elements). See [ui-style-guide.md](../ui-style-guide.md).

## Spec rotation (process)

The active spec is switched by manually editing 3 `@import` lines in `CLAUDE.md` (chosen over Windows symlinks, which need Developer Mode/Admin and fail silently). Every switch is logged in [DECISION_LOG.md](../DECISION_LOG.md).
