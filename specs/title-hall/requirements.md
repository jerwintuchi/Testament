# Requirements — The Great Hall, built from curved geometry (TD-076)

> **STATUS: LANDED — the hall IS the author's painting (R260), at fidelity.**
>
> The author, after seeing several procedural attempts: *"disregard the constraints and make the
> great hall similar / almost 1:1 to the reference image."* The only thing that is 1:1 with a
> painting is the painting. `gen_title_matte.py` processes it into the client; the props stand down
> because the image contains its own; the fires, dust and smoke move onto the lights it actually has.
>
> **Both treatments were built and captured rather than argued about.** `--register` (640×360, on
> palette, mode-filtered — 31 colours, 523 single-pixel islands against a naive downscale's 5876)
> is a technical success and an artistic failure: the architecture dissolves into mush, because the
> painting's structure lives at a frequency 640×360 cannot hold. `--fidelity` (1280×720, drawn 1:1
> on device pixels at 720p, no filtering) is what shipped.
>
> **This reverses two rulings, knowingly:** TD-073's "do not use the PNG as the main menu", and the
> author's own "keep the Contract Board's pixel language on the title screen". Both were overridden
> explicitly. `--register` remains one flag away if the register is ever wanted back.
>
> The author asked the decisive question — *does this ensure a close, almost 1:1 look to the
> reference?* — and the answer was no. A ray-caster produces ordered variation; the reference's
> character is controlled irregularity, plus figurative carving no generator reaches. Structure was
> always reproducible; likeness was not.
>
> So **Phases A0–C below are PARKED**, not deleted. They remain the record of a real finding (the
> flat-plane defect, and the measurement that rejected its own bad fit), and the curved-geometry work
> may still earn its place for in-game Collegium screens, where a generated environment is worth more
> than a painted one. Nothing in them is started.
>
> The live requirement is **R260**.
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

## R260 — The hall is author-supplied art, processed into the client

- AC: the Great Hall arrives as an **author-generated image** — the only route that reaches the
  likeness the author asked for, because the art *is* the reference rather than an approximation of
  it.
- AC: it is **architecture only**. Every element that must animate (banners, censers, candles,
  braziers, smoke, dust, light) is layered over it, per the brief's own implementation philosophy.
  Anything baked into the plate is frozen for good.
- AC: **no UI is baked in** — no title, no menu, no logo. Those are rendered live, and inpainting
  them out afterwards is the problem TD-073 already paid for once.
- AC: it is processed by the existing pipeline (`tools/title_assets.py`), validated, installed and
  imported, with **no code change** — the rig has taken `hall_plate.png` by that name since TD-073.
- AC: **NEAREST throughout, no linear filtering anywhere in the project** (the author's ruling,
  reversing my previous line). The plate does not get a softer filter because it was painted; it
  gets brought INTO the register instead.
- AC: the title screen **keeps Testament's pixel-art language** and belongs to the same world as the
  Contract Board. Grandeur comes from composition, lighting and atmosphere — *not* from pixel
  density or painterly detail. It is a hand-crafted pixel-art matte painting, not a high-resolution
  illustration, and it naturally uses larger, simpler forms because of its architectural scale.

## R262 — The plate is DOWN-REGISTERED, and the result is measured

A supplied image arrives high-resolution and painterly. Landing it in the board's register is a
processing step with a real failure mode: a naive downscale-and-quantise produces speckle — every
pixel a different value — which is precisely the "modern AI-generated pixel art" the brief forbids.
Measured on Reference A:

| Treatment | Colours | Run-continuity | **1px islands** |
|---|---|---|---|
| naive downscale + quantise | 41 | 0.474 | **5876** |
| + median | 35 | 0.738 | 1518 |
| + 2 mode passes | 30 | 0.836 | **492** |

- AC: the pipeline is **crop to 16:9 → BOX downsample to 640×360 → median → quantise to Ash & Ember
  → mode passes**. Mode, not median, for the final consolidation: it keeps boundaries hard while
  flattening interiors, which is what a pixel artist's flat regions actually are.
- AC (measurable): the landed plate has **fewer than 600 single-pixel islands**, **≤34 colours**, and
  **run-continuity ≥ 0.83**. Single-pixel islands are the objective signature of the forbidden look —
  a hand-placed pixel almost never sits alone.
- AC: `A.assert_on_palette` passes, exactly as the board's own art does.
- AC (the honest cost, so the source art is authored for it): consolidation destroys fine detail.
  Tracery, chain links and carved profiles do not survive 640×360 whatever the filter. The source
  should therefore be generated with **large, simple, strongly-silhouetted forms** — detail spent
  below the register's reach is detail thrown away.

## R261 — The props match the plate, or they are not used

- AC: the animated layers and the plate must share one visual register. Pixel-art banners over a
  painted hall is the mismatch that would undo the point of supplying art at all.
- AC: therefore either the author supplies **matching prop art** (transparent PNGs, same generator,
  same lighting), or the props are **baked into the plate and their layers disabled** — trading the
  sway, the pendulum and the drift for a coherent picture.
- AC: whichever is chosen, the fire pools, dust, smoke and god-rays stay live. They are
  art-independent and cost nothing in either arrangement.

---

## PARKED — the procedural route (R248–R259)

*Kept as the record. Not started, not scheduled.*

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

## R259 — The structure matches Reference A, by measurement

*(the author's request: reproduce the reference's interior structure, accessories aside)*

- AC: the camera is **re-measured against Reference A**, not inherited. The camera in the tree
  (hfov 105°, pitch 15°→21°) was measured off the *previous* concept art and has never been checked
  against the image the author actually supplied.
- AC: the hall's proportions, bay rhythm and storey heights are driven to match **measured
  landmarks** from Reference A, and the render is checked back against those same numbers. "Does the
  structure match?" becomes a comparison of figures, not of opinions.
- AC: the aisles are **modelled**, so the arcade opens into a space rather than onto black. This is
  a large part of the reference's depth and its absence is why the current hall reads shallow.
- AC: the floor is **wet**, carrying a reflection of what stands on it — a second ray mirrored about
  the floor plane.
- AC (out of scope, stated so it is not expected): carved figurative detail, painterly per-stone
  tonal variation, and the reference's specific late-Gothic net-vault rib pattern. The result is a
  structural match in a cleaner graphic register, not a duplicate — which the brief asks for anyway
  ("do NOT recreate this image pixel-for-pixel").

### Landmarks measured so far

| Landmark | Reference A | How |
|---|---|---|
| Zenith (verticals converge) | **fy −2.916** | Hough over near-vertical edges, both sides; symmetry-checked at fx 0.475 vs 0.5 |
| Vault crown | fy 0.335 | darkest row, upper half |
| Lit far end spans | fx 0.256 … 0.746 | brightest column band, middle third |
| Near piers occupy to | fx 0.329 / 0.669 | darkest quartile columns at the edges |
| Left/right symmetry | ratio 1.036 | mean column brightness per half |

**The nave vanishing point could not be recovered automatically**, and that is recorded rather than
papered over: the runner is too faded and broken for edge-fitting (per-row red runs catch banner
reflection on the wet flags), and the receding cornices produced two near-parallel lines whose
intersection landed at fx −7.04. The symmetry check rejected it. So R259 is satisfied by a
**landmark fit**, not a closed-form two-point solve — see design.

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

## R258 — WITHDRAWN: the grain returns to 640×360

*Superseded by the author: "ensure the generated hall plate already matches the pixel density and
cluster size established by the Contract Board … not through higher pixel density."* The 1280×720
ruling recorded below is reversed; the hall is authored at **640×360**, the board's own grain, and
everything under R254 applies to it unchanged. Kept in place rather than deleted so the reversal is
legible.

### (superseded) Authored at 1280×720

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
