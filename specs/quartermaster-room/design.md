# Design — The Quartermaster as a Room (TD-101)

> Satisfies R361–R369. Properties P164–P167.
> Presentation + interaction only. `src/**` is not touched.

---

## Where the code is

| what | where | change |
|---|---|---|
| item data | `src/shared/src/gear.ts` → `client/protocol/protocol.gd` → `core/catalog.gd` | **none** |
| item prose | `stations/quartermaster/lore.gd` | **none** (kept verbatim) |
| coordinator | `stations/quartermaster/register.gd` | re-skinned; keeps its role |
| the pack + flight | `stations/quartermaster/pack.gd` | kept; `fly_in` re-aimed from the counter |
| the record | `stations/quartermaster/record.gd` | re-laid as a ledger entry |
| the seal | `stations/quartermaster/seal_rite.gd` | **none** |
| the frame | `main.gd` — `_show_station` popup sizing | one branch: `QUARTERMASTER` goes full-frame |
| icons | `assets/ui/stations/gear_icons.png` | **reused, not regenerated** (brief §5) |

---

## Composition (640×360 logical)

```
┌──────────────────────────────────────────────────────────────┐
│ ✝ QUARTERMASTER                                              │  header 34
│   COLLEGIUM STORES · EXPEDITION ISSUE                        │
├───────────────────────────────────┬──────────────────────────┤
│ ┌ INSTRUMENTS OF SIGHT ─────────┐ │ ┌ RECORD ──────────────┐ │
│ │ ▪ ◎ ⊕ △ ☥ ♪ ● ▪            │ │ │ [ic]  ASHEN LENS     │ │
│ ├ INSTRUMENTS OF TRIAL ─────────┤ │ │  Instrument of Sight │ │  shelves 396 wide
│ │ ▪▪ ♨ ❄ ⛉ ☀ ▪▪▪           │ │ │  "What did it…?"     │ │  record  244 wide
│ └───────────────────────────────┘ │ │  note / care         │ │
│                                   │ │  [E] ADD TO PACK     │ │
│ ┌ THE COUNTER ──────────────────┐ │ └──────────────────────┘ │
│ │ ledger   [ the item ]  scale  │ │ ┌ EXPEDITION PACK ─────┐ │
│ └───────────────────────────────┘ │ │ ▢ ▢ ▢ ▢   2/4        │ │
│                                   │ └──────────────────────┘ │
│                       SEAL & DEPART                          │
└──────────────────────────────────────────────────────────────┘
```

**Shelf objects are absolutely positioned, not laid out by a container.** A `VBox`/`HBox` gives flow
positions that reflow when a child's size changes — which is exactly what must not happen when an
instrument lifts on hover or leaves for the counter. Each object is a child of the shelf `Control` at
a **computed** position, so `AVAILABLE → ON_COUNTER → AVAILABLE` returns it to the same pixel (R365).

Position is derived from catalog order, never per-id:

```
row      = 0 for PERCEPTION, 1 for PROBE
col      = index within its kind
x        = SHELF_PAD + col * PITCH
y        = board_top(row) + BOARD_H - ICON_PX      # objects stand ON the board
```

---

## The item state machine (P164)

```
        hover ┌─────────┐ unhover
  AVAILABLE ──┤ HOVERED ├── AVAILABLE
      │       └─────────┘
      │ click
      ▼
   SELECTED ──(carry ≈0.5s)──► ON_COUNTER
      │                            │ PACK
      │ another item selected      ▼
      │  (return first)         PACKING ──(fly_in)──► PACKED
      ▼                                                  │ click slot
  AVAILABLE ◄──────────── REMOVING ◄──────────────────────┘
```

Held as `item_state: Dictionary[id → int]` on the view, with an enum in `shelf.gd`. **Presentation
reacts to state**; nothing is baked into a texture (brief §18). A state change repaints only the
affected object plus the record (P165) — never the room.

---

## New modules (S3, one responsibility each)

| file | responsibility | ~lines |
|---|---|---|
| `stations/quartermaster/room.gd` | the environment: wall, floor, shelving frames, counter body, lamp | 200 |
| `stations/quartermaster/shelf.gd` | objects on boards: placement, hover, select, the state machine, stock | 260 |
| `stations/quartermaster/counter.gd` | the inspection counter's surface, props, and the object resting on it | 150 |

`register.gd` stays the coordinator and shrinks — it stops building rows and starts wiring these
three to `record.gd` / `pack.gd` / `seal_rite.gd`. Dependencies run **one way**
(`register → room/shelf/counter/pack/record`), so no cyclic `preload` (the TD-067 rule).

---

## New art — `client/assets/ui/gen_qm_room.py`

Modular and reusable (brief §16/§17), authored **at display size**, `NEAREST`, on the Ash & Ember
ramps with `assert_on_palette`. Reuses the existing `navestone` ramp so this room and the Great Hall
are the same building.

| asset | size | note |
|---|---|---|
| `qm_wall.png` | 64×64 | tiling navestone ashlar, dark |
| `qm_shelf.png` | 48×48 | 9-slice shelving frame: uprights, top rail, side brackets |
| `qm_board.png` | 32×12 | one shelf plank with a lit top edge and cast shadow beneath |
| `qm_label.png` | 24×12 | 9-slice brass-edged label plate for the shelf headings |
| `qm_counter.png` | 64×40 | 9-slice counter: worn top surface, panelled front, iron feet |
| `qm_stock.png` | 8×24 tiles | dressing atlas — crate, bottle, jar, book stack, tin, roll, sack, case |
| `qm_props.png` | 4×24 tiles | counter props — ledger, candle, inkwell, scale |

**Not generated:** a single big painted room. The brief forbids it (§17) and TD-072 already recorded
a procedurally generated hero plate as a structural failure.

**Icons are reused as-is** — `gear_icons.png` already holds ten 24px instruments, and brief §5 says
not to duplicate existing item artwork.

---

## Lighting, and why not `Light2D`

**`Light2D` cannot reach `Control` nodes** — established twice (TD-047, re-confirmed TD-083 for the
world layer). This screen is Control-based, so light is **baked into the art** with one exception:
the lamp's flicker is a looping tween on a warm `modulate`, which costs no frame callback.

---

## Performance

Budget is in `requirements.md` and is enforced by `tools/qm_budget.py` (the `world_budget.py`
pattern): node count, particle total, no `_process`, no full-frame additive layer. Structural checks
that bite against a broken copy, not just a printed number.

The one real cost is node count: ~10 instruments + ≤30 stock + ~4 props + 4 slots + chrome ≈ 90
`Control`s. All static after build; only tweens move.

---

## Files

**New:** `stations/quartermaster/{room,shelf,counter}.gd`, `assets/ui/gen_qm_room.py` + its 7 PNGs,
`tools/qm_budget.py`.
**Changed:** `register.gd`, `record.gd`, `pack.gd` (flight origin), `main.gd` (one popup branch).
**Untouched:** `lore.gd`, `seal_rite.gd`, `gear_icons.png`, all of `src/**`.
