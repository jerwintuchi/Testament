# Requirements — Collegium Client (Walkable Spaces) v1

> Phase 5, spec 3 (the follow-up client spec named in TD-036). The Godot client
> learns to **render the walkable spaces and send `MOVE`**, so the party can walk
> the Collegium to its prep stations and walk the field to its extraction node.
> This unblocks the manual playtest that both field-space (TD-035/036) and the
> Collegium (TD-036) left waiting: spawn → Contract Board → accept → Deploy Gate
> → deploy → field → probe → Extraction → extract.
>
> **Client only** (render + input; trust boundary I1). No server or shared
> changes — the wire is already complete: `MOVE`, `POSITIONS`, `LobbySnapshot`
> (`collegium` + `positions`), `FIELD_STARTED` (`site` + `positions`),
> `STATE_RESYNC`, and the `NOT_AT_*` error codes all exist and are codegen'd into
> `client/protocol/protocol.gd`.
>
> One reusable renderer serves **both** spaces: `CollegiumLayout` and `SiteLayout`
> share the shape `{ grid: SiteGrid, <markers at tile coords> }`, positions are
> feet px, tiles are `TILE_SIZE` (16). R# numbering continues from R101.
>
> **Art posture:** v1 renders a *functional greybox* — tiles, station/node
> glyphs, and player bodies drawn programmatically in Godot (Control/Node2D), the
> mirror of the server's authored-but-unskinned layout. This introduces no new
> tool or asset (closed-list safe, CLAUDE.md art direction); authored pixel
> tilesets and the strict 480×270 SubViewport pipeline are a later art task.

---

## Functional Requirements

**R102**: As the client, a single reusable `SpaceView` renders any tile space
from server data, and it is render-only (I1).
- AC: given a `SiteGrid` dict `{ width, height, rows }`, `SpaceView` draws
  `width × height` tiles with solids (`TILE_SOLID` `#`) visually distinct from
  floor (`TILE_FLOOR` `.`), Nearest-filtered, at integer scale.
- AC: `SpaceView` can be handed a list of tile-coord markers (`{ kind, x, y }`)
  and draws a labeled glyph at each tile center — the same call renders Collegium
  `stations` and field `nodes`.
- AC: `SpaceView` holds no `NetClient`/protocol reference and no phase knowledge:
  it renders what it is given and sends nothing (inspection; it is pure render).

**R103**: As a Seeker, I see every party member's body where the server says it
is, updated by `POSITIONS` deltas.
- AC: an initial `positions` map (from `LobbySnapshot`, `FIELD_STARTED`, or
  `STATE_RESYNC`) creates one body per `playerId` at its feet px.
- AC: a `POSITIONS` delta moves only the named players; bodies not named are left
  where they are (client honors the same delta discipline the server sends, I6).
- AC: the local Seeker's body is visually distinct from teammates'.
- AC: a body whose `playerId` is absent from a fresh full `positions` sync is
  removed (left/kicked).

**R104**: As a Seeker, my input sends a movement *intention* and never moves my
body itself — the body moves only when the server reports it (client-side I1/P50).
- AC: WASD/arrow input yields `dx`,`dy` ∈ {-1, 0, 1}; the client sends
  `MOVE { dx, dy }` **only when the intent vector changes** (a key down/up edge),
  and sends `{ dx: 0, dy: 0 }` exactly once on full release — never every frame.
  (The server samples the last intent each tick; the client need not resend it.)
- AC: raw components are sent (no client normalization); the server normalizes
  the diagonal (confirmed: `stepPlayer` normalizes `mag > 1`).
- AC: with no `POSITIONS` arriving (e.g., server not ticking), pressing keys does
  not move the local body — the body is only ever placed from server positions.
- AC: `MOVE` is sent only in walkable phases (WAITING, DEPLOYING, FIELD); in
  MENU/RECONNECTING/TESTAMENT and before a room exists, input sends nothing.

**R105**: As a Seeker, the Collegium *is* the lobby view during WAITING and
DEPLOYING; I walk it, and the roster/ready/requisition controls become an overlay.
- AC: on entering WAITING (`ROOM_CREATED` / `LOBBY_UPDATED`), the client renders
  `snapshot.collegium` (grid + stations) with all present bodies from
  `snapshot.positions`; the party roster + Ready + Leave sit in an overlay.
- AC: DEPLOYING keeps the Collegium rendered (grid unchanged) with the contract +
  requisition overlay; the party keeps walking.
- AC: a reconnect (`STATE_RESYNC`) during WAITING/DEPLOYING re-renders the
  Collegium and places everyone from the snapshot's `positions`.

**R106**: As a Seeker, each prep action is offered only when I stand at its
station, mirroring the server gate; the server stays the authority.
- AC: the local body within `STATION_RADIUS` of the `CONTRACT_BOARD` center shows
  the "Accept Contract" affordance (leader only); within `QUARTERMASTER` shows the
  requisition panel; within `DEPLOY_GATE` shows the "Deploy" affordance (leader).
  Outside the radius, that action is not offered — a hint names the station to
  walk to instead.
- AC: proximity is a **render hint only**, computed from server-provided positions
  and station tile coords; it never authorizes — the send still goes to the server
  and a `NOT_AT_CONTRACT_BOARD` / `NOT_AT_QUARTERMASTER` / `NOT_AT_DEPLOY_GATE`
  error still surfaces in the status line if it races.

**R107**: As a Seeker in the field, the same walkable rendering applies and
EXTRACT is gated at the Extraction node exactly as the stations are.
- AC: on `FIELD_STARTED`, the client renders `site.grid` + `site.nodes` and places
  bodies from `positions`; the existing signs/probe/exposure controls remain an
  overlay.
- AC: the "Extract" affordance appears only within `EXTRACTION_RADIUS` of the
  `EXTRACTION` node center; a `NOT_AT_EXTRACTION` error still surfaces if it races.
- AC: a reconnect (`STATE_RESYNC` carrying a `fieldSnapshot`) re-renders the site
  and positions.

**R108** (standing, I1): As the trust boundary, no game logic crosses into the
client.
- AC: the client never integrates movement (no use of `SEEKER_SPEED` or feet-AABB
  collision to move a body); bodies are only ever placed from server positions.
- AC: proximity gating is a display affordance, never an authorization — every
  station and extraction action remains server-validated (already true server-side;
  the client adds no bypass).
- AC: the client still originates no game state — it sends only intentions
  (`MOVE` plus the existing `ACCEPT_CONTRACT` / `REQUISITION` / `DEPLOY` / `PROBE`
  / `EXTRACT`), each re-validated by the server.

---

## Verification

There is no GDScript unit harness in this repo (prior client spec convention,
godot-client-catchup). Client requirements are verified by a **numbered,
MCP-driven playtest** — `specs/collegium-client/playtest.md` — run through the
Godot MCP (`run_project` on `client/`, assertions read from `get_debug_output`,
`stop_project` when done), against a live `pnpm dev:server`. To make the run
*observable*, the client logs the load-bearing events (`MOVE` edges sent, body
count, active phase/grid, within-station transitions) so `get_debug_output` can
confirm them. Each task below names the playtest item(s) it is verified by.
