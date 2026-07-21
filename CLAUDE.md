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

Field Space v1 is shipped (TD-036): `specs/field-space/` (T95–T103) — seeded
tile site, authoritative 20Hz movement with feet-AABB collision, position-gated
extraction, on the canonical 16×16 grid.

Collegium (Staging Site) v1 is shipped (TD-036): `specs/collegium/` (T104–T114)
— the fixed, walkable Collegium occupied during the lobby phases, one generalized
movement tick across WAITING/DEPLOYING/FIELD, and prep actions gated to spatial
stations (Contract Board, Quartermaster, Deploy Gate). Server + shared only.

Collegium Client (Walkable Spaces) is code-complete (TD-038): `specs/collegium-
client/` (T115–T120) — one reusable `SpaceView` draws both the Collegium and the
field from server data; input emits `MOVE` on edges; proximity affordances mirror
the `NOT_AT_*` gates. Plus MCP-driven follow-ups: initial body-sync (Seeker no
longer invisible until first move), a server-authoritative Shift-to-walk register
(`WALK_SPEED`; `MovePayload.walk`), crisp+legible font settings, and a themed
9-slice popup (`assets/ui/panel.png`, `_build_popup_theme`). **T121 (full MCP
playtest) is still unrun — the spec is left open, re-exercised by Station UI.**

Station UI v2 is shipped server/shared-side (`specs/station-ui/`, T122–T130): the
contract **board** + leader `SELECT_CONTRACT` (T122–T124), Stipend-priced
Quartermaster and Deploy Gate. Superseded on the client by the Notice Board.

Completed: **`specs/board-lighting/`** (TD-047/TD-048) — dynamic torch lighting, **Phases A–D
done + verified** (T148–T162 + T154; only the T151 heat-haze stretch deferred). Surround normal-
mapped + shader-lit to a deep dungeon key (`board_surface.gdshader` reading one `BoardDecor.torch_rig`
— Godot Light2D does NOT reach Control UI), `CPUParticles2D` sconce flame, clean crimson banner
(`gen_banner.py`), parchment legibility floor lifted partway (`gen_parch_v1.py`). Commits b011623→6b9d225.

Active spec: **`specs/board-heraldry/`** (TD-049) — re-author the board **header** to the user's
Blasphemous-idiom reference: an ornate gilded-bronze **crest** (upright **sword** + **ring** + **laurel
wreath** + **filigree scroll**, Origin-neutral — the order's blade-and-laurel, not a trait sigil) crowning
a wide **carved-plank nameplate** with **iron corner brackets** + a two-line gilt title ("THE COLLEGIUM"
/ "CONTRACT BOARD"). Replaces the T158 radiant-star medallion + T159 routed placard. Client render-only
(I1/I2); baked + tonally matched to the dungeon-dark board (no dynamic shader — same reach ruling). New
generator `gen_heraldry.py` (crest + nameplate) + header re-wire. Binding = the **design language**,
not pixel-identity (user ruling). **COMPLETE (T163–T166, commit 9338501):** `gen_heraldry.py` emits
the dim-bronze crest (sword+ring+laurel+filigree) + carved nameplate (iron corner plates + brass
bolts, 9-slice); the crest is a popup-tracking **overlay** (outside the clipping ScrollContainer,
anchored to the nameplate rect) so it crowns over the top edge; two-line gilt title 8.6:1;
`TOP_RESERVE_FRAC` 0.20→0.235 so notices still show every line. V1–V6 green, client-only, suites
green. R147–R151, T163–T166.

Completed: **`specs/board-consistency/`** (TD-050) — a Contract Board scene consistency pass on the
user's review of the heraldry header. **COMPLETE (T167–T172, V1–V7 green, client-only):** the crest is
re-authored at display resolution in `gen_heraldry.py` (80×70, bolder sword/laurel strokes, SS=4) and
shown **1:1 NEAREST** in `board_decor.board_crest` (display size == source, killing the LINEAR-downscale
mush); the title collapsed to a single gilt **"CONTRACT BOARD"** line; `TOP_RESERVE_FRAC` 0.235→0.205 so
the KEPT TD-040 scatter sits clear of the compact header (`keepout ok=true`, all notice lines show);
**banners shortened** to `vp.y·0.5` with the sconce **decoupled** to its own gutter position
(`vp.y·0.71`, matching `torch_rig`) so cloth clears the fixture; **wall + backing lifted** (wall ambient
0.30→0.48, backing 0.42/1.1→0.56/1.25 — partial walk-back of TD-048, surfaces only, still darker than
parchment/frame); **one-register style pass** eased the flavor foxing + live-paper fibre jitter
(`gen_detail.py`/`gen_parch_v1.py`) and cobweb opacity (0.5→0.34), leaving the carved **frame untouched**
as the anchor. Server 362 + shared 65 suites green (untouched); headless parses clean.

Completed: **`specs/board-banner/`** (TD-052) — Contract Board scene polish (client render + generated
art only) on the user's emblem/heraldry review. **COMPLETE (T178–T182, commit d600a10):** the crest
shrunk 51×84→40×66 (R165); the flanking **banners** re-authored as proper hanging standards in
`gen_banner.py` (74×474 frayed strip → 180×360: clean woven crimson, baked folds/AO, a **swallowtail**
hem, a baked top hem — the iron rod + nail `Panel`s retired) (R166); the Collegium emblem **imprinted**
on BOTH banners as a **pale bone-dye** printed device baked into `banner_v1.png` (luminance→BONE ramp,
alpha×0.86 so the weave reads through; PIL to read the emblem, still `ashember.write_png` for the
producer edge) (R167); two matching banners centered in each gutter + widened to `vp.x·0.15` (off-screen
overflow OK) with the light rig coherent via one shared `GUTTER_CX` read by both `torch_rig` +
`add_torches` (R168, P95); the **"CONTRACT BOARD" placard** re-cut as refined carved wood
(`gen_heraldry.nameplate_px` — routed groove + crisper double bevel, same 9-slice margins) (R169).

Completed: **`specs/board-header/`** (TD-053) — a Contract Board **header** redesign (client render +
generated art only) on the user's brief: the header must read as a **handcrafted institutional object**
inside the Collegium HQ, ecclesiastical grimdark, not a modern game UI. **Preserve the board composition**
— only the header block changes (R174). A new `gen_header.py` emits a carved oak/walnut **plaque**
(9-slice, forged iron corner straps + bronze bolts, routed field, worn rim — utilitarian, not luxurious)
(R171) and an **inset bronze seal** (socket AO ring + iron rim + aged bronze disc + the emblem in raised
relief) that **replaces the floating `_board_crest` overlay** and its `_process` chase (R172, P98).
`_board_header()` stacks the seal over an **engraved** two-line hierarchy — **THE COLLEGIUM** primary
over a subordinate **Contract Board** — as one centered object (R173). `TOP_RESERVE_FRAC`/`placard_rect`
grow; the keep-out self-check guards the scatter (P99). Materials: aged wood/bronze/iron/brass only,
candlelit, **no bloom/gloss** (R175). Retires the superseded `board_nameplate.png` + dead `crest_v1.png`.
Verified by `--board-preview` captures. **T183–T187 done.**

Superseded by **TD-058** (author review): after three passes fighting the 17x22 device slot (LANCZOS
mush TD-054, blobbed shape functions TD-056, hand-drawn Aseprite TD-057), the crowning **bronze
medallion is removed entirely** and the carved sign hung **flush at the top of the board**. The header
is now just the sign (iron straps + bronze bolts + engraved two-line title); the emblem still rides the
banners at ~112px, where it resolves. Header height is zero-sum against the writs, so dropping the seat
grew the writs **93x54 → 93x67** (larger than the pre-header 93x60). `board_header.png` **204x46 →
204x38**, `placard_rect` **204x65 → 204x38** (`sign_top` 19→0), `TOP_RESERVE_FRAC` **0.24 → 0.17**;
`board_seal.png` + `gen_header.py`'s `seal_px`/device-reader/PIL are deleted (pure surface generator
again). `keepout live=8 ok=true minhit=93x67`. Client render only; `art/src/collegium_device.*` kept as
source art. Verified by `--board-preview` captures.

Active spec: **`specs/board-blend/`** (TD-059) — a Contract Board **blend pass** (client render +
generated art only) on the user's review of the TD-058 board: the header + flanking **banners** don't
read as belonging in the torch-lit scene. **COMPLETE (T188–T192, V1–V6 green, client-only):** the
banner is re-authored in `gen_banner.py` (180×360→**64×176**) as **crisp NEAREST pixel art** with a
**heavily tattered** foot (ragged per-column hem + worn-through holes + loose threads, all alpha), a
**dim/desaturated** crimson, and a **subdued** Collegium imprint (R177/R178); it is now a
**normal-mapped surface lit by the torch rig** — `gen_banner.py` emits `banner_v1_n.png` from its own
fold height field and the banner `Sprite2D` takes a `board_surface.gdshader` material (`--lights-off`
falls to flat dim cloth, proving the shader lights it) (R179); a **larger** banner pushed to the
**outer gutter, clear of the board frame** and **lowered** (TD-059b/c: `GUTTER_CX` 0.065→**0.028**,
width 0.15·vp→**0.095·vp**, `banner_top` 0.012→**0.06·vp.y** — the gutter is narrower than the banner,
so pinning the inner edge clear of the frame while growing walks the centre out; the emblem stays
on-screen, the outer edge spills off-screen, and the top no longer lines up with the board, author
OK'd) (R180). The **placard** now joins the same lighting model (TD-059d/R183): `gen_header.py` emits
`board_header_n.png` and the sign takes a `board_surface.gdshader` material, so it sits in the scene's
cool ambient (matching the frame top, far from the corner sconces) instead of reading as a flat
self-lit plaque — `--lights-off` ~unchanged (ambient-dominated); the gilt title is a separate Label so
legibility holds. `_surface_material` grows one optional
**`radius_scale`** (default 1.0 — existing surfaces unchanged; the banner passes ≈2.4) so the tight
0.24 torch halo still keeps the wall dark but its warmth **climbs the cloth** — same rig, a per-material
reach, not a second light (P102). The **header wood is darkened** (`WALNUT` 50,39,30→38,29,22, blend
0.46→0.56) so the sign recedes while the gilt title only gains contrast (R181). **TD-059e** (author
review) splits the coupling constant: `GUTTER_CX` (0.028/0.972) is **banner placement only**, and a
new **`TORCH_CX`** (inboard between banner and frame; TD-059f centred it in the wall gutter,
0.072→**0.045**/0.955) is what the sconce + flame + `torch_rig` read — the flame hangs mid-wall and
visibly lights the frame; fixture + shader light still share one constant (P95 re-homed).
Geometry/composition otherwise unchanged. No `src/**` change.

@specs/board-blend/requirements.md
@specs/board-blend/design.md
@specs/board-blend/tasks.md

Completed: **`specs/dependency-map/`** (TD-051) — DERIVE the script↔asset dependency graph instead of
hand-maintaining it. **COMPLETE (T173–T177, `--selftest` + `--check` green, tooling/docs only):**
`tools/asset_map.py` (stdlib) statically scans `client/` for the four edge kinds (gd `load`/`preload`,
tscn `ext_resource`, py `write_png`) and emits `docs/technical/asset-map.md` — every asset's
producer(s) + consumer(s), each script's loads/preloads/loaded-by, generators' writes, plus **Orphans**
(dead art), **Dangling** (ref to a missing file), and **Unresolved dynamic references** (variable-path
loads — declared blind spots). Templated `%d/%s/{}` paths are globbed against on-disk files. `--check`
makes staleness a hard failure (exit 1) so the committed map can't silently drift; `--selftest` asserts
known edges + determinism (the named test). `docs/technical/code-map.md` (was a placeholder) is filled
with how to read/regenerate the map + the **provenance-header** convention (the *why* a scanner can't
infer); CLAUDE.md + spec-workflow.md point new work at "regenerate + `--check` on any dependency change".
First map already surfaced real findings: `crest_v1.png` is written by TWO generators (`gen_emblems.py`
legacy + `gen_heraldry.py` current — a latent conflict), and `parch_live_*` + `board_placard.png` are
orphaned dead art. Stdlib-only; no server/shared/client-runtime change.

Paused: **`specs/notice-board/`** — the diegetic commission wall (server done T131–T132,
T138–T139; client Pass-2 raster reskin T140–T144 + the TD-046 art-director polish done).
Remaining **T145–T147** (a11y/keyboard, empty-board, error-toast, L1–L8 verification) are
deferred, not abandoned.

@specs/notice-board/requirements.md
@specs/notice-board/design.md
@specs/notice-board/tasks.md

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
- `specs/field-space/` (T95–T103): seeded tile site (`generateSite`), authoritative 20Hz movement (`stepPlayer`, movement tick), position-gated extraction (TD-035/036)
- `specs/collegium/` (T104–T114): fixed walkable Collegium, one `moveTick` across WAITING/DEPLOYING/FIELD, spatial prep stations (`NOT_AT_*` gates), snapshot `collegium` + `positions` (TD-036)

@.claude/rules/spec-workflow.md
@.claude/rules/netcode-invariants.md

## Local Tooling (Godot, screenshots, server)

> **Read `docs/technical/dev-environment.md` before touching the client.** It has
> the verified WSL↔Windows seams; do not re-derive them. The essentials:

- **One clone.** `/home/jerwin/projects/Testament` (WSL) is canonical.
  `D:\Projects\Testament` is stale — never point Godot at it.
- **Run Godot from Bash**, against the WSL clone over its UNC path:
  ```bash
  GODOT='/mnt/d/Godot_v4.7-stable_win64.exe'
  CLIENT='\\wsl.localhost\Ubuntu-24.04\home\jerwin\projects\Testament\client'
  "$GODOT" --path "$CLIENT" --quit-after 900 -- --capture=3   # screenshot, then quit
  ```
- **You can see the client.** The `DebugCapture` autoload writes the viewport to
  `client/.captures/*.png` (F12, or `--capture=<s>`), which lands in the WSL tree
  and can be `Read` back. Iterate on visuals by *looking*, never by guessing.
  `--headless` cannot capture (dummy renderer) — it only checks that GDScript parses.
- **A live round-trip needs the server up first** (`pnpm dev:server`, `ws://localhost:3001`),
  started **in the background** — it is a watch process and never returns. Without
  it the client reports "server offline" and idles, which is not an error.
- `mcp__godot__*` tools may also be registered (`run_project`, `get_debug_output`,
  `stop_project`, …). They have **no screenshot tool**, and being Windows-side they
  need the UNC path. The direct Bash invocation above is verified and preferred.
- None of this relaxes the trust boundary: capture is render-only, and game logic
  never moves into the client to make a check pass.

**Before scouring for "which script loads this PNG / which generator writes it / who
preloads this `.gd`?" — read the generated dependency map first:**
`docs/technical/asset-map.md` (produced by `tools/asset_map.py`; `res://` == `client/`).
It lists every asset's producer + consumers, orphans (dead art), dangling refs, and
unresolved dynamic loads. Regenerate + `--check` it when a dependency changes (see
`docs/technical/code-map.md` for how to read it + the provenance-header convention). TD-051.

## Art Direction & Sanctioned Toolchain — CLOSED LIST

> Decision log: **2026-07-05 — 2D top-down pixel reaffirmed; Blender 3D and MediBang
> purged.** (TD-033) · **2026-07-11 — in-engine lighting made a pillar; palette-lock
> relaxed.** (TD-043) · **2026-07-12 — single canonical register: hand-painted raster 2D
> pixel art; Claude generates raster PNGs directly (headless import).** (TD-046)

Testament's one canonical register is **hand-painted raster 2D pixel art** (TD-046):
warm, weathered, aged, and **dramatically torch-lit**, in the **Prototype v1** idiom
(Blasphemous / Dead Cells / Curse of the Dead Gods) — never flat greybox. Every UI/world
surface is authored as a **raster PNG** (aged parchment, carved gilded frame, wax seals,
verb sigils, tacks, banner, crest), imported **Nearest**, and lit in-engine.
Canonical conventions: 16x16 tiles; **640x360 internal resolution** (TD-042 —
supersedes 480x270; the only base exact on 720p/1080p/1440p/4K), integer-scaled to
fill via the `PixelScale` autoload; **mobile is a target platform** (TD-042); Nearest
filtering; Seeker 16x24 logical / 48x48 canvas / feet anchor (24,44); part-lag
animation rig; per-frame weapon sockets; grayscale ADD-blend VFX.
- **Claude generates raster directly** (TD-046): the Python generators (`ashember.py` +
  `gen_*.py`) author raster PNGs end-to-end; brand-new files are imported with
  `godot --headless --import` (writes the `.png.import` so a game-run loads them). Raster
  is a first-class Claude deliverable — **not** author-supplied only. Author-painted / AI
  source art is still welcome for richness beyond the generators, never required.
- **No palette-lock.** The strict 15-colour lock is **retired** (TD-046, not merely
  "advisory"): 24-bit painted ramps, gradients, AO, and bevel shading are the norm.
- **Lighting is a core pillar** (TD-043): scenes are lit, not evenly bright —
  per-source **Light2D**, **particle** flames, and **shaders** on walls/props/UI, with
  AO, drop shadows, and warm/cool falloff. The Notice Board is the canonical example;
  every surface (field, sprites, HUD, menus) adopts this as built or re-skinned.
- Still forbidden (TD-033 tool purge): no 3D scenes, no 3D-to-sprite rendering, no
  `.blend`/`.fbx`/`.gltf`/`.obj` assets, no Node3D-derived scenes, no MediBang, no
  `.mdp` files.

| Tool | Role |
|---|---|
| Godot 4.7 | Engine: scenes, TileMap autotiles, Light2D stack, particles, **UI** |
| Aseprite | All **sprite** sources (`art/src/*.aseprite`) — sigils, icons, sprites, animation |
| Python/PIL generators | Programmatic **surfaces** + sheets + JSON metadata (`gen_*.py`) |

**The split (TD-057), settled by measurement, not taste:**
- **Aseprite owns sprites.** Anything where a pixel is a *design decision* — sigils, icons,
  character sprites, animation frames. Claude drives it **in batch from WSL**, no MCP needed:
  `'/mnt/d/Steam/steamapps/common/Aseprite/Aseprite.exe' -b --script 'C:\...\foo.lua'` gives the
  full Aseprite Lua API. It is a **Windows** binary, so the script path and every path *inside*
  it must be Windows-style (`C:/...`); stage via `/mnt/c/Users/jerwi/AppData/Local/Temp` and copy
  the result back. Export a PNG beside the `.aseprite` so the generators/asset-map keep an edge.
- **Python owns surfaces.** Wood grain, stone, parchment, gradients, AO, bevels, normal maps,
  9-slice panels, and anything feeding a shader. Drawing these by hand would be slower and worse.
- Proven at ~17x22 px (the medallion device): hand-placed pixels beat both a LANCZOS reduction of
  author art (TD-054, mush) and shape functions drawn at slot size (TD-056, blobbed). A shape
  function samples a curve; it cannot decide *which pixel* carries the crossguard.

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
