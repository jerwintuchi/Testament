# Testament — Root Context

> Testament is a cooperative hunting RPG with roguelike expedition structure.
> You are hunter-scholars of the Collegium. It runs on an authoritative Node
> server (ephemeral in-memory rooms, seeded procedural generation) with a Godot
> client. The reboot and design history live in `docs/DECISION_LOG.md`.

@docs/README.md
@docs/vision.md
@docs/GLOSSARY.md

## The Spine (every feature answers to this)

> Observe → Hypothesize → Test → Record.

Testament is the scientific method dressed as a gothic hunt. A feature that does
not help the party read, bet on, or record an Incarnate is probably noise.

## Trust Boundary

| Layer  | Path          | Role                                                           |
|--------|---------------|----------------------------------------------------------------|
| Server | `src/server/` | Authoritative. All game state lives here. Never trust client.  |
| Shared | `src/shared/` | The wire protocol contract. Types + constants only. No logic.  |
| Client | Godot project | Render + input only. Untrusted. Zero game logic.               |

Transport is **raw WebSocket with a JSON message envelope** (migrated off
Socket.io so Godot's `WebSocketPeer` connects natively and HTML5 export works).
The protocol is the single source of truth and must stay language-neutral: the
TypeScript server and the GDScript client both honor the same message shapes.

## Active Work

Phase: **Phase 2 — Protocol contract & shared codegen**. Active spec: the wire
protocol as one language-neutral source of truth (a shared message-name registry
plus a `tools/` codegen emitting GDScript constants). Commits no gameplay.

@specs/protocol-contract/requirements.md
@specs/protocol-contract/design.md
@specs/protocol-contract/tasks.md
@.claude/rules/spec-workflow.md
@.claude/rules/netcode-invariants.md

## Local Tooling (Godot MCP)

A Godot MCP server may be registered in this environment, exposing `mcp__godot__*`
tools (`run_project`, `get_debug_output`, `launch_editor`, `get_project_info`, plus
scene/node helpers). When those tools are present, use them to drive the client
directly instead of asking the user to press Play and paste errors:

- The Godot client is the `client/` folder (the directory holding `project.godot`).
- To check it: call `run_project` on `client/`, read `get_debug_output` for GDScript
  errors and runtime logs, then `stop_project` when done.
- A live server round-trip needs the Node server up first (`pnpm dev:server`,
  `ws://localhost:3001`); without it the client reports "server offline" and idles,
  which is not an error.
- The MCP reaches only the render client. It does not relax the trust boundary:
  never move game logic into the client to make a check pass.

If the `mcp__godot__*` tools are absent, fall back to asking the user to run the
client manually.

## Immutable Design Pillars (never violate)

1. Preparation is as important as combat.
2. Knowledge is progression (skill that lives in the player, not stats on a sheet).
3. Incarnates are understood through interpretation, never memorization.
4. Cooperation is the primary pillar; solo is supported, never the design center.
5. Every expedition becomes another Testament (even failure teaches).

## Key Invariants

1. Seeded RNG is server-only and deterministic: same expedition seed → same world.
2. No client-originated game state. Clients send intentions; the server validates.
3. Each Incarnate's hidden trait roll lives server-side. Clients only ever see
   *signs* (observable manifestations), never the underlying traits.
4. `docs/DECISION_LOG.md` is append-only. Never edit past entries; only add.
5. Every task (T#) cites a requirement (R#) and names a test before being marked done.

## Workflow note

Ask of every new system: **"Will this still be interesting after 500 expeditions?"**
If not, redesign it.
