# Design — Main menu + lobby, production presentation (TD-071)

> Satisfies R224–R230. Client render + input only. Verified by captures.

---

## SETTLED — the menu's visual treatment: **diegetic-lite** (author ruling)

**"Diegetic-lite": the menu is a place in the Collegium.** A themed panel on the
stone surround under the existing torch rig: `panel.png` 9-slice, Cinzel title, gilt-on-parchment
controls, the two sconces already built by `BoardDecor.add_torches`. It reuses only shipped art, so
it costs no new generator, and it makes the first screen belong to the same world as the board —
which is the whole complaint. The rejected alternative (a flat typographic title card) is cheaper
still but reads as a game menu bolted onto a game about a place.

If you want the full painted title plate instead (a carved TESTAMENT sign via `gen_header`'s idiom),
that is a follow-up spec with its own generator task — deliberately **not** folded in here.

## Phase A — Wording + correctness

### `scripts/core/station_names.gd` — `StationNames`

`_STATION_LABEL` currently sits in `main.gd`, so the world markers in `space_view.gd` never see it
and print the raw enum. Moved to a preloaded `RefCounted` namespace (canon S3.2/S3.4 — never a
global `class_name`):

```gdscript
const LABEL := {
    "CONTRACT_BOARD": "Contract Board", "QUARTERMASTER": "Quartermaster",
    "DEPLOY_GATE": "Deploy Gate", "EXTRACTION": "Extraction",
}
static func of(kind: String) -> String:
    return LABEL.get(kind, kind)     # unknown kind degrades to its raw value (P125)
```

Consumers: `main.gd` (`_prompt`) and `world/space_view.gd` (`_place_markers`, the raw-enum bug).

### Identity (R225)

`_name_input` drops its `"Seeker"` default for an empty field with a `your name` placeholder, backed
by `user://display-name.txt` (same shape as the reconnect token — a local convenience, never game
state). `Create Room` / `Join Room` refuse an empty name with an inline hint via `_set_status` and
**send nothing** (affordance ≠ authority: the server still validates).

## Phase C — The room scroll

A new `scripts/ui/room_scroll.gd` — a **node-owning** component, so per canon S3.1 it is its own
scene-shaped module driven by methods and emitting signals, not another block inside `main.gd`
(S5: new client features do not enter `main.gd`).

```gdscript
signal ready_toggled
signal leave_pressed
signal kick_requested(player_id: String)

func refresh(snapshot: Dictionary, self_id: String) -> void   # redraw from the snapshot only (P124)
func set_open(open: bool) -> void
func toggle() -> void
```

**Closed** (default): a small parchment tab pinned to a screen corner showing only the party ready
pips (`●●○○`) — readiness stays legible while the world stays clear, which is the author's
constraint. **Open**: the tab unrolls into a parchment panel (`parch_v1_*` on the `panel.png`
9-slice, Cinzel headings, the board's ink colours) carrying:

```
┌──────────────────────┐
│  ROOM                │
│   C Z 3 Z G 4   [⧉]  │   large, letter-spaced; ⧉ = copy
│ ──────────────────── │
│  ● Aldric   ★ (you)  │   ● ready  ○ not ready
│  ○ Wren              │   ✕ Kick shown to the leader
│  ○ —                 │     for a disconnected player
│  ○ —                 │
│ ──────────────────── │
│  [ Ready ] [ Leave ] │
└──────────────────────┘
```

Toggled by **Tab**, guarded by `not _menu_open` so the Contract Board keeps Tab for writ traversal
while its popup is up; the closed tab is also clickable. Animation reuses the reader's idiom — a
short fade/slide on the panel alone, never a rebuild of the world beneath (S6, and the TD-068
lesson: update the smallest subtree).

`main.gd` keeps the socket: it instances the scroll, calls `refresh()` on every `LOBBY_UPDATED`,
and forwards `ready_toggled`/`leave_pressed`/`kick_requested` to the existing
`TOGGLE_READY`/`LEAVE_ROOM`/`KICK_PLAYER` intents. The scroll itself never touches `_net` (S3.5).

### Copy (R229)

`DisplayServer.clipboard_set(code)` then `_show_toast("Room code copied")`. Client-local; no message.

## Correctness Properties

- **P124 (the scroll is view state, R228):** toggling sends nothing and mutates nothing; the roster
  is rendered from the snapshot each `refresh()`, never accumulated client-side (I1). Ready/Leave/
  Kick remain server-validated intents — a raced `NOT_LEADER`/`WRONG_PHASE` still surfaces.
- **P125 (display names are presentation, R224):** the enum stays on the wire and is mapped at the
  render edge; an unmapped kind renders its raw value, so a new server station degrades to ugly,
  never to blank.

## Files touched

New: `client/scripts/core/station_names.gd`, `client/scripts/ui/room_scroll.gd`,
`specs/menu-lobby/*`. Edited: `client/scripts/main.gd` (menu rebuild, lobby delegation, instruction
removal, name persistence, `_STATION_LABEL` → `StationNames`), `client/scripts/world/space_view.gd`
(marker label), `docs/technical/asset-map.md` (regenerated), `docs/DECISION_LOG.md` (TD-071),
`CLAUDE.md`. No `src/**` change.
