# Requirements — The Collegium stops being a greybox (TD-081)

> The author, after TD-080 made the create path instant: spec the Collegium greybox pass. Removing
> the form put the finished Great Hall directly against flat grey tiles, a visible grid and white
> system labels — and this is the screen the player actually spends time in.
>
> **R293+**, **P142+**, **T310+**.

---

## What is actually there today

Measured, not impressions:

- **`client/assets/tiles/tiles.png` is 32×16 and contains four colours.** Two 16×16 cells — one flat
  floor, one flat wall — and that is the complete art of the Collegium.
- **Each station is `marker.tscn`:** a 12×12 gold `Polygon2D` and a white `Label` reading its kind in
  the default sans.
- **There is no light at all.** No `Light2D`, no shader, no ambient — the tiles render at their
  authored value everywhere.
- The server's own comment says it: *"The client decorates the tileset; the server only needs the
  wall/floor + station grid."* Decoration was always the client's job and was never done.

## R293 — The Collegium is lit by real `Light2D`

The single most important finding in this spec: **`SpaceView` is a `Node2D`.** TD-047 established
that `Light2D` cannot reach Control nodes and the board's torches have been faked with additive
sprites ever since — but that ruling was about **UI**. The world layer was never subject to it.

- AC: the hall is lit by actual `PointLight2D`s with real falloff, and `--lights-off` visibly removes
  their contribution. This is the bible's lighting pillar (TD-043) satisfied *literally* for the
  first time.
- AC: light is **warm and sparse** — a hall lit by a few sources with dark between them, not evenly
  bright. The title screen's grammar: depth reads as luminance.
- AC: each station is lit by its own source, so walking the hall changes what you can see. That is
  the point of a walkable space and it is currently absent.
- AC: a normal map on the tileset so the stone takes the light with relief, the same technique
  `board_surface.gdshader` uses.

## R294 — Floor and walls become authored stone

- AC: the tileset is re-authored in the Ash & Ember register: worn flags, mortar, wear at the edges
  of the walked route — pixel art at 16×16, `NEAREST`, on-palette (`assert_on_palette`).
- AC: **the visible grid goes.** Flat cells with edge lines read as a debug grid; tiles must tile
  without a seam announcing every cell.
- AC: more than one floor variant, placed deterministically from the tile's own coordinates, so the
  floor does not repeat visibly across a 22-tile span. No `Math.random` — same tile, same look.
- AC: the border wall reads as the *base of a wall* seen from above, not a flat block.

## R295 — The stations become objects, and stop shouting their names

- AC: the gold square is replaced by an object per station: the **Contract Board** (whose art already
  exists and should be reused), the **Quartermaster**'s counter, the **Deploy Gate**.
- AC: the floating white `STATION` labels are **retired**. The proximity prompt already reads
  `Press E: <Station>` when you are close enough to act — so the label is a second naming of the same
  thing, in the wrong typeface, permanently on screen. An object you can recognise needs no caption.
- AC: each station's footprint matches the `STATION_RADIUS` the server already validates against, so
  what you see is where the action is legal.

## R296 — It reads as the same building as the title screen

The title is a nave seen down its axis; this is the same hall from above. Continuity is therefore
**material and light**, never composition.

- AC: the same stone palette, the same warm/cool split, the same darkness.
- AC: type is Cinzel wherever the Collegium speaks (station prompt, any label that survives).
- AC: no new decorative props beyond the stations themselves — the restraint that governs the title
  screen governs here (TD-079).

## R297 — Air, consistent with the title

- AC: dust drifting in the lit volume, at the title screen's density and slowness. It should be
  noticed only after a moment.
- AC: no fog banks, no rolling smoke — the same ruling as TD-079.

## R298 — Performance, under the standing canon

Budgeted before building, per `.claude/rules/performance.md`:

- AC: **≤ 6 `Light2D`s** live in the hall.
- AC: **≤ 60 live particles**.
- AC: **no full-frame additive layer** and **no per-frame script** in the render path.
- AC: the tilemap is painted **once per space change**, never per frame (it already is; this must not
  regress).
- AC: verified by a tool, not asserted — extending `title_assets --budget` or a sibling that reads
  the world scene.

## R299 (containment) — client render + generated art only

- AC: **the layout stays server-owned.** No change to `COLLEGIUM`, its grid, its spawn or its station
  coordinates; this spec decorates what the server sends (I1). No `src/**` change, no wire change.
- AC: maps, registry and manifest regenerated; suites green.

---

## Correctness Properties

- **P142 (the world is lit, the UI is faked):** `Light2D` is used in `world/` because it works there;
  Control surfaces keep the additive-sprite technique (TD-047). Both are correct, and the boundary
  between them is the node type, not the screen.
- **P143 (the server owns the plan, the client owns the look):** every tile and station drawn comes
  from the snapshot. Decoration never invents geometry the server did not send.
- **P144 (deterministic decoration):** floor variation is a pure function of tile coordinates, so the
  same hall looks the same on every client and every launch — the same discipline the seeded
  generators hold to.

## Verification

- **V1 (R293/P142):** capture with and without lights; the difference is unmistakable and the hall is
  dark between sources.
- **V2 (R294/P144):** capture; no grid seam, no visible repeat across the hall; a second run is
  pixel-identical.
- **V3 (R295):** capture; each station is recognisable without its label, and the prompt still names
  it on approach.
- **V4 (R296/R297):** capture beside the title screen; same palette and darkness.
- **V5 (R298):** the budget tool reports lights, particles and layers inside their ceilings, and
  fails when one is exceeded.
- **V6 (R299):** `git diff` shows no `src/**`; suites green.

---

## Deliberately out of scope

- **The lobby / room scroll HUD** — its own pass.
- **The layout itself** (where stations sit, how big the hall is) — server-owned, and changing it is
  a design decision, not a decoration one.
- **Animation rig work** on the Seeker sprite.
- **Changing your name.** Noted here because TD-080 left it: the display name is asked once and there
  is currently no way to change it. The Collegium is the natural home for that affordance, but it is
  a feature, not decoration, and is only worth building if the author wants it.
