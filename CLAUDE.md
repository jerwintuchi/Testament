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

Phase: **Phase 5 — Combat & Incarnate v1, opening** (TD-035). Phase 4 is closed:
all five core deliverables exist server-side (TD-027), the Godot client speaks
the full Testament protocol over the production-wired bootstrap (TD-028), the
protocol-codegen contract is reconciled and load-bearing on both sides (TD-031),
and the disconnect playtest's lobby gaps are fixed (TD-032). Phase 5 lead-in is
done: the encounter cadence doc is in-repo (`docs/systems/encounter-flow.md`)
and the spike-era dungeon/movement chain is pruned (TD-034).

Active spec: **`specs/field-space/`** (T95–T103) — the spatial substrate combat
needs, rebuilt on the canonical 16×16 grid: seeded tile-based site generation
with the TD-018 node vocabulary, authoritative 20Hz movement with feet-AABB
collision, and position-gated extraction. Combat/melee/Omen/verb systems follow
once positions and collision exist.

@specs/field-space/requirements.md
@specs/field-space/design.md
@specs/field-space/tasks.md

Completed Phase 4 specs:
- `specs/raw-ws-transport/`: raw WebSocket transport (wsHub, protocol envelope) + Godot client spike
- `specs/incarnate-signs/` (T39–T44): TraitRoll, SIGN_LEXICON, deriveSigns, generateTraitRoll
- `specs/contract-generation/` (T45–T49): ContractRecord, generateContract, ContractIntel wire type
- `specs/ambient-signs/` (T50–T53): signs in FIELD_STARTED and FieldSnapshot (reconnect)
- `specs/probe-handler/` (T54–T61): PROBE intent, deriveReaction, exposure, probe-gated REACTION channel
- `specs/distributed-perception/` (T62–T67): per-player perception sets, filtered sign delivery
- `specs/loadout-economy/` (T68–T74): GEAR_CATALOG v1, REQUISITION, gear-derived perception, kit-gated probes
- `specs/godot-client-catchup/` (T75–T83): production bootstrap for the Testament protocol, spike retirement, full Godot protocol client
- `specs/protocol-contract/`: shared message-name registry + `tools/` GDScript codegen (authored against the spike protocol on `feat/protocol-contract`, reconciled to the Testament protocol in TD-031)
- `specs/lobby-resilience/` (T88–T94): `LobbyPlayer.connected`, ghost-proof `allReady`, leader `KICK_PLAYER`, client ghost UI + scroll layout (TD-032)

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

## Art Direction & Sanctioned Toolchain — CLOSED LIST

> Decision log: **2026-07-05 — 2D top-down pixel reaffirmed; Blender 3D and
> MediBang directions deprecated and purged.** (DECISION_LOG TD-033)

Testament is **2D top-down pixel art**, full commitment. Canonical conventions:
16x16 tiles; 480x270 internal resolution, integer-scaled; Nearest filtering;
Seeker 16x24 logical / 48x48 canvas / feet anchor (24,44); part-lag animation
rig; per-frame weapon sockets; grayscale ADD-blend VFX; palette-locked Aseprite
sources. No 3D scenes, no 3D-to-sprite rendering, no `.blend`/`.fbx`/`.gltf`/
`.obj` assets, no Node3D-derived scenes, no painterly/HD raster sources, no
`.mdp` files.

| Tool | Role |
|---|---|
| Godot 4.7 | Engine: scenes, TileMap autotiles, Light2D stack, particles, **UI** |
| Aseprite | All hand-authored sprite sources (`art/src/*.aseprite`) |
| Python/PIL generators | Programmatic sheets + JSON metadata (`gen_*.py`) |

- UI is built **in Godot** (Control nodes, theme resources); UI sprites/icons are
  16x16-class pixel assets from Aseprite. No external UI tools.
- Adding ANY tool beyond this list requires explicit user approval first.
  Propose with justification; never install, import, or integrate unprompted.

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
