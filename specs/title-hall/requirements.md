# Requirements — The Great Hall, built from curved geometry (TD-076)

> **Status:** DRAFT — awaiting the author's approval before any implementation.
>
> **Why this spec exists.** TD-075 moved the title screen to the Contract Board's pixel register,
> and that part holds: 640×360, drawn 1:1 through NEAREST, every colour an Ash & Ember ramp entry.
> What it did **not** fix is the thing the author reported: the hall reads flat, and the ceiling
> does not curve.
>
> That is a defect in the model, not in the shading. The renderer casts rays against **flat planes**:
>
> ```
> gen_nave.hit():   vault → plane at  y = 37m    (flat, horizontal)
>                   walls → planes at x = ±8m    (flat, vertical)
> ```
>
> Ribs and web courses are then *painted onto* that flat ceiling, and colonnettes are *stripes*
> painted onto a flat wall. A flat surface has one normal everywhere, so no shading model can make it
> turn away from the light. Reference A's vault visibly curves down into the piers and its shafts are
> visibly round; ours cannot be, at any level of polish, until the geometry changes.
>
> This spec replaces the hall's geometry with real curved surfaces, then spends the resulting
> shading on the four gaps the author ranked: **density, readable glass, visible age, lighting**.
>
> **R248+**, **P129+**, **T269+**. To be logged as **TD-076** on approval.

---

## R248 — The vault is a curved shell, not a plane

- AC: the ceiling is a **groin vault** — the intersection of a transverse barrel across the nave and a
  longitudinal barrel along each bay — ray-cast as curved surfaces. No horizontal ceiling plane
  remains in the hall's geometry.
- AC: the barrels are **semicircular** (the author's ruling), not two-centred. A barrel of radius
  `HALF_W` springing at the clerestory head, crowning at `SPRING + HALF_W`.
- AC: the vault's surface **descends to the springing line** at both walls, so the ceiling's boundary
  with the wall is a curve, not a horizontal line.
- AC: the diagonal **ribs sit where the two barrels actually intersect** (the groins), and the webs
  sink between them. No rib is drawn as a line on a surface that has no groin under it.
- AC (measurable): on a horizontal scanline crossing a web with no rib on it, the rendered tone takes
  **at least three distinct ramp indices**, ordered — i.e. the web is shaded by its own curvature.
  A flat ceiling produces one.

## R249 — Piers and colonnettes are round

- AC: each compound pier is modelled as a **bundle of vertical cylinders** (a core plus colonnettes),
  ray-cast as cylinders, not as strips of a flat wall.
- AC: shading comes from the **surface normal**, so a shaft's lit side, its turn, and its shadowed
  side are consequences of geometry.
- AC (measurable): a horizontal scanline across one colonnette yields tone indices that rise then
  fall (dark → light → dark). Painted stripes cannot produce that ordering by construction.

## R250 — The hall is furnished

*(the author's first-ranked gap)*

- AC: wooden tables and candle stands stand along both aisles, in world space, receding correctly.
- AC: a **detailed niche** (the author's ruling): a modelled recess with a moulded surround, a
  canopy above, a plinth below, and the recess's own shadow — a piece of carved architecture, not a
  dark rectangle. It holds a robed figure, which the finer grain of R258 makes drawable.
- AC: a run of **memorial plaques** on the aisle walls, with legible plate edges and fixings.
- AC: detail concentrates at focal points; **large stone surfaces stay visually quiet** (the brief).
- AC: furnishings are part of the hall's geometry, not screen-space decals — they occlude and are
  occluded correctly.

## R251 — The stained glass reads as windows

- AC: at least two windows resolve as **windows with tracery**, not as slivers. At the current
  camera the nave walls are grazing, so this requires either window bays turned toward the viewer or
  an opening near the frame edge whose wall faces the camera.
- AC: glass is the hall's own light: warm ambers and bone with a few crimson panes, flat-shaded, with
  stone mullions reading as stone.

## R252 — The age is visible

- AC: chipped stone at exposed corners, **worn stair treads** at the sanctuary, wax build-up at the
  candle stands, soot rising from every flame position, and faded areas where generations have
  passed.
- AC: it reads **ancient but maintained** — never ruined, never abandoned. This is humanity's last
  sanctuary and it is still kept.

## R253 — Lighting has depth and warmth

- AC: light sources live in **world space**, so a candle stand lights the pier beside it, the floor
  under it, and nothing across the hall.
- AC: the lit foreground reads against a dark distance; warm candlelight against cool ambient.
- AC: **still banded** — light contributes an integer number of ramp steps (P131). No dithering, no
  smooth falloff.

## R254 — The pixel register is unchanged (carried from TD-075)

- AC: drawn through **NEAREST**, hard-edged, with no filtering anywhere in the path.
- AC: every pixel is an Ash & Ember ramp entry; `A.assert_on_palette` passes.
- AC: no anti-aliasing, no painterly texture, no per-pixel noise, no dithering. Variation is
  per-block or per-bay.

## R255 — The centre of the frame belongs to the UI (carried from R245)

- AC: title, rule and all four menu options stay legible at every integer scale `PixelScale`
  produces, with nothing bright directly behind them.

## R256 (containment) — client render + generated art only

- AC: no `src/**` change, no wire change. Asset map regenerated, `title_assets --check` green,
  suites green.

## R257 — The hall is DENSE

*(the author's report: "the details of pixels looks ugly … I need the hall to be more detailed")*

The Contract Board's register was never the cap on detail — it fixes pixel **size**, not how much is
in the frame, and Reference A is dense pixel art. What emptied the hall was three self-imposed gates
plus missing content. This requirement reverses that.

- AC: **coursed masonry is visible on every lit stone surface** where a course projects ≥2px,
  including the near piers — which are the largest surfaces in frame and are currently blank.
- AC: stone-to-stone tonal variation across the whole visible range, not only a mid-distance band.
- AC: **ribs run the length of the vault**, not only the nearest bays, thinning with distance rather
  than switching off.
- AC: the objects Reference A's density actually comes from are present: window **tracery**, hanging
  **chains**, arcade **mouldings and capitals**, **plaques**, furniture, floor patterning.
- AC: "quiet" is applied as the brief states it — large **unlit** surfaces stay calm and detail
  concentrates at focal points. It is not a licence to leave surfaces empty.
- AC: the frame still reads at a glance from across a room (the brief's readability test). Density is
  not noise: it must resolve into objects, not texture.

## R258 — Authored at 1280×720 (the author's ruling)

- AC: the hall and its furnishings are authored at **1280×720** — four times the pixels of the base
  resolution to spend on detail, while staying hard-edged NEAREST pixel art on the Ash & Ember ramps.
- AC: drawn at the viewport's logical size, which puts it at **1:1 device pixels** on a 720p window
  (and 1:2 at 1440p) — the common cases the capture harness uses.
- AC (stated honestly): at **odd** integer scales the mapping is 1.5 device pixels per art pixel, so
  NEAREST will double some pixel columns and not others. That is the price of a grain finer than the
  base resolution, and it is accepted deliberately.
- AC: the hall's grain is therefore **half the Contract Board's**. Side by side the board reads
  chunkier. This is a knowing amendment to "match the board exactly", made because the author asked
  for more detail than 640×360 can hold.

---

## Correctness Properties

- **P129 (curvature is geometric):** no surface's roundness is produced by a painted gradient or a
  stripe. Remove the shading and the geometry still curves; remove the geometry and the roundness
  disappears with it. This is what R248/R249's scanline tests actually check.
- **P130 (on-palette):** every opaque pixel of every generated title asset is a curated ramp entry,
  asserted by the generator itself — the same check the Contract Board's art passes.
- **P131 (integer light):** the light term reaching the output is an integer number of ramp steps.
  A float term is what forces dithering, which the brief forbids; making it integral makes that
  class of failure unrepresentable.

## Verification

- **V1 (R248/R249):** a `--debug-surface` render colour-coding surface class and normal, plus the two
  scanline assertions run as a self-test in the generator.
- **V2 (R250/R251/R252):** `--title-preview` capture; furnishings, glass and wear read at 1:1.
- **V3 (R253):** capture with lights on and with `--lights-off`; the difference is local to each
  source, not global.
- **V4 (R254/P130):** `assert_on_palette` passes on the hall and every furniture piece.
- **V5 (R255):** captures at two integer scales; all four options legible.
- **V6 (R256):** diff scoped to `client/ specs/ docs/`; `asset_map --selftest`+`--check`;
  `title_assets --selftest`+`--check`; server + shared suites green.

---

## Explicitly out of scope

- The gameplay world. The brief is explicit: this hall is a **bespoke hero environment** and must not
  become reusable gameplay architecture. Nothing here is designed for the modular top-down pipeline.
- The UI layout. The environment adapts to the interface, never the other way round.
- Audio (T262, still blocked on there being no sanctioned audio tool).
