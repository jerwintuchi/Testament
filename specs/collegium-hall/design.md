# Design — The Collegium stops being a greybox (TD-081)

> Satisfies R293–R299. Client render + generated art only; the layout stays server-owned.

---

## The one structural insight

**`SpaceView` is a `Node2D`, so `Light2D` works.**

Every lighting decision in this project so far has been shaped by TD-047 — a `PointLight2D` cranked
to energy 8 changed nothing on the Contract Board, so torches became additive sprites and the
"lighting" became a shader reading uniform light positions. That finding is correct and it is about
**Control nodes**. The world layer is not one.

So the Collegium can have the thing the bible has been asking for since TD-043: real lights, real
falloff, real normal-mapped relief, and a hall that is genuinely dark between its sources. It is also
*cheaper* than the fake — one `PointLight2D` costs less than a large additive quad.

```
world layer  (Node2D)   →  Light2D. Use it.            ← the Collegium, the field
Control UI              →  additive sprites + shader.  ← the board, the title (TD-047)
```

That boundary is **the node type, not the screen** (P142), and it is worth writing down because the
next person will otherwise inherit "Light2D doesn't work in Testament", which is false.

## Phases, so this is buildable in pieces

### Phase A — Light and stone

The largest visual return, and it needs no new scenes.

`gen_collegium_tiles.py` emits a tileset in the Ash & Ember register:

| cell | what |
|---|---|
| floor ×4 | worn flags: mortar lines, chipped corners, differing wear |
| wall ×2 | the base of a wall from above — a lit top course, a dark face |
| threshold | where floor meets wall, so the join is not a butt seam |

Plus `tiles_n.png`, a normal map derived from the same height field the diffuse is drawn from — the
`gen_normals` idiom the board already uses. The `TileMapLayer` gets a `CanvasItemMaterial` with
`normal_map`, so the flags take the lights with relief.

**The grid must stop being visible.** Today each cell is flat with a darker edge, which is exactly a
debug grid. Wear and mortar have to cross cell boundaries, which is why there are four floor variants
chosen by `hash(x, y)` — deterministic (P144), so every client sees the same hall.

Lights: one per station (3), one at the spawn atrium, and two along the walk between them. Six, at
the ceiling of R298, warm, with generous falloff and a dark middle distance.

### Phase B — The stations become objects

`marker.tscn` is replaced per kind. The Contract Board's art **already exists** and is the single
best asset in the game — a top-down view of it against the north wall is most of the work done.

The floating white labels go. `Press E: <Station>` already appears on approach, so a permanent
caption in the default sans is a second naming of the same thing in the wrong typeface. An object you
can recognise does not need a caption; if it does, the object is wrong.

Each station's lit footprint matches `STATION_RADIUS`, so **what you see is where the action is
legal** — currently the gold square and the validated radius are unrelated, which is a small lie the
player has to learn around.

### Phase C — Air and finish

Dust at the title screen's density and slowness, in the lit volume only. No fog banks, no rolling
smoke — TD-079's ruling holds. Cinzel wherever the Collegium speaks.

## What this must not do

- **Not touch the layout.** `COLLEGIUM` in `src/server/` owns the grid, the spawn and the station
  coordinates, and the client draws what the snapshot says (I1/P143). Decoration never invents
  geometry.
- **Not add props.** The restraint that governs the title screen governs here: stations and stone,
  nothing else.
- **Not regress the paint path.** The tilemap is painted once per `set_space`, never per frame.

## The budget (R298, stated before building)

| | ceiling |
|---|---|
| `Light2D` | 6 |
| live particles | 60 |
| full-frame additive layers | 0 |
| per-frame script in the render path | none |

Verified by a tool that reads the world scene, in the same shape as `title_assets --budget`: a
screenshot cannot show a frame cost, so if the budget is not a check it is a comment.

## Files

**New:** `client/assets/ui/gen_collegium_tiles.py`, `client/assets/tiles/tiles_n.png`,
`client/scenes/stations/*.tscn`, `specs/collegium-hall/*`.
**Edited:** `client/assets/tiles/tiles.png` + `.tres` (more cells), `client/scripts/world/
space_view.gd` (variants, lights, per-kind stations), `client/scenes/marker.tscn` (retired or
reduced), `tools/` (the budget check).
**Unchanged:** everything under `src/`.

## Correctness Properties

- **P142 (the world is lit, the UI is faked):** `Light2D` in `world/`, additive sprites in Control.
  The boundary is the node type.
- **P143 (server owns the plan, client owns the look):** every tile and station drawn comes from the
  snapshot.
- **P144 (deterministic decoration):** floor variation is a pure function of tile coordinates.
