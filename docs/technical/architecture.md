# Technical — Architecture

> **Status:** Canon (summary — authoritative source is the code, CLAUDE.md, and DECISION_LOG.md)
> **Sources:** CLAUDE.md (trust boundary, invariants); DECISION_LOG.md (stack, pnpm workspaces)
> **See also:** [technical/netcode.md](netcode.md) · [technical/determinism-and-rng.md](determinism-and-rng.md) · [technical/stack-and-deployment.md](stack-and-deployment.md)

## Trust boundary

| Layer  | Path           | Role                                                          |
|--------|----------------|---------------------------------------------------------------|
| Server | `src/server/`  | Authoritative. All game state lives here. Never trust client. |
| Shared | `src/shared/`  | Types + constants only. No logic. Single source of truth.     |
| Client | `src/client/`  | Render + UI only. Untrusted. Zero game logic.                 |

The line between `src/server/` (trusted) and `src/client/` (untrusted) is the **Trust Boundary**. `src/shared/` sits on the line — types and constants only.

## Workspace structure

pnpm workspaces with three packages: `src/server`, `src/client`, `src/shared`. Shared types are consumed via the `@veins/shared` workspace reference. This gives strict dependency isolation and separate build pipelines (Vercel for client, Fly.io for server). See [stack-and-deployment.md](stack-and-deployment.md).

## Key invariants

1. Seeded RNG is deterministic: same run ID → same dungeon, always. ([determinism-and-rng.md](determinism-and-rng.md))
2. No client-originated game state. Clients receive delta events and render them — nothing more. ([netcode.md](netcode.md))
3. Relic adjacency and synergy are always evaluated server-side. ([../systems/circulatory-board.md](../systems/circulatory-board.md))
4. `docs/DECISION_LOG.md` is append-only — never edit past entries, only add new ones.
5. Every task (T#) must cite a requirement (R#) and name a test before being marked done.

## Core pattern — pure core, thin sockets

Game logic is pure functions returning discriminated-union result objects (`{ ok: true, ... } | { ok: false, error }`). Socket.io handlers are thin plumbing: validate via the pure function, then emit the returned event(s). This keeps the entire game-logic core testable without a live server. Full detail and the full invariant set (I1–I7): [netcode.md](netcode.md).

> This file is a reader-facing summary. The binding rules live in `.claude/rules/netcode-invariants.md` and the dated history in [DECISION_LOG.md](../DECISION_LOG.md).
