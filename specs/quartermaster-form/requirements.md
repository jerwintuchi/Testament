# Requirements — The Stores Gain Form (TD-115)

> **R397+**, **P178+**, **T426+**. Written to be picked up cold.
> Author brief, 2026-08-11, on the shipped TD-113/TD-114 room. **Presentation only** —
> no `src/**` change, no change to the item data, bag rules, flow or the seal rite.

---

## What a fresh session needs to know

The Quartermaster is a room built from two kinds of art, and they no longer belong to
each other.

The **author's** furniture — cabinet, bench, record board, three bench props — is
hand-drawn with baked form: bevels, grain, ambient occlusion, drawn highlights. The
**generated** surfaces around it — wall, altar cloth, rite plate, satchel, lantern,
banner — are flat colour fields with a border and nothing else. Measured off a 3×
contact sheet of every generated piece, that is literally what they are: the cloth is a
red rectangle with two flat crosses, the rite plate is a red rectangle with a gold rule,
the satchel is a dark box with a lid strip, the lantern is a bracket and an orange bar.

**The wall is the worst of them, and for an instructive reason.** It is a nearly
featureless diffuse carrying a normal map and a lighting shader. The shader dutifully
paints a smooth gradient across a surface with no drawn structure, and a smooth gradient
over nothing is exactly what reads as a 3D render dropped into a pixel-art scene. The
fault is not the shader; it is that the art gives it nothing to describe.

**The division of labour for this spec is settled (author ruling, 2026-08-11):** the
**author draws** the replacement art; this spec **writes the briefs, grades, wires and
verifies**. Per-asset briefs are in [`asset-briefs.md`](asset-briefs.md).

Four author rulings shape everything below:

| question | ruling |
|---|---|
| how the cabinet gets bigger | **rebuilt bigger at 1:1** — extend the drawn art, never scale it |
| who draws the replacements | **the author draws**; this spec briefs, grades and wires |
| what happens to the wall | **keep the shader**, give the diffuse real drawn form |
| what "ambient" meant | **moodier** — deeper darks, stronger pools, higher contrast |
| dark vs. readable | **hover carries the light** — dark at rest, legible on demand |

**Standing constraints.** The Contract Board and every finished spec are closed work;
style widgets in the builders that create them, never in a cascading `Theme` (TD-089).
`Light2D` cannot reach `Control` (TD-047, re-confirmed TD-083) — this screen is
Control-based, so light is the `board_surface.gdshader` rig or it is baked. Performance
is budgeted here, before building (`performance.md` P0). Author art is welcome as
authored; the palette lock is retired (TD-046), so nothing here asserts a palette.

---

## R397 — The cabinet is rebuilt larger, at 1:1

- AC: the cabinet is **wider and taller** than the 166×166 that ships, at roughly
  **240×199**, and every pixel is still the same size as an instrument icon's. It is
  **never drawn through a scale factor** (TD-050/TD-055).
- AC: it is **derived from the author's own drawing** by repeating drawn bands — one
  extra shelf band across the full width, and one backboard slice inside each bay — so
  the extension is the author's art, not new art invented beside it.
- AC: each bay gains a shelf (**four per bay**) and enough clear span for **three**
  instruments per shelf rather than two.
- AC: shelf rows and bay spans stay **measured off the emitted art**, never hand-typed,
  so a re-derivation cannot silently disagree with where instruments stand.
- **Why:** at 166 wide in a 339 column the cabinet reads as a small piece of furniture
  in a large empty room, and its two bays are just wide enough for two instruments,
  which is what makes the shelves look sparse.

## R398 — The wall reads as built stone, not as a render

- AC: the tile grows **64×64 → 128×128**, halving the visible repeat across the frame
  from ten to five.
- AC: the diffuse carries **real drawn structure** — deep cut joints, per-block tone,
  lit chamfers, shadowed feet, chipped arrises, damp — so the shader has something to
  describe rather than a flat field to gradient across.
- AC: it **tiles seamlessly on both axes**, proven by a tiling check, not by eye.
- AC: the normal map is **derived from the delivered diffuse**, so relief and shading
  cannot disagree (the rule the generated surfaces already followed and the reason they
  looked coherent even when they looked flat).
- AC: the surface shader **stays** (author ruling). This is not a lighting rewrite.

## R399 — The altar cloth reads as cloth

- AC: it shows **folds, a woven texture and a drape over the bench's front edge** —
  form, not a rectangle with a fringe.
- AC: **104×46 exactly.** The rest point of an inspected instrument is derived from this
  rect (P176) and the caption is placed beneath it, so a size change moves both.
- AC: the Collegium device on it reads as **embroidered into** the weave — sunk, catching
  light on one side — rather than printed flat on top.

## R400 — The rite plate reads as a struck object

- AC: `SEAL & DEPART` is a **physical plate** — bevelled edge, worn face, fixings — not a
  filled rectangle with a rule around it.
- AC: it is a **9-slice whose centre is a uniform field**, because the centre is the only
  region a 9-slice may stretch. This is the lesson the altar cloth and the record's
  divider each taught once already (TD-110); a device or a bevel in the centre smears
  across the full width.
- AC: its **two states survive** — subdued while the pack cannot be issued, gold when it
  can (R376) — as one object in two states, not two different-looking controls.

## R401 — The pack, the lantern and the banner read as objects

- AC: the **satchel** shows leather with grain, a stitched edge, a turned-back flap and
  compartments with depth. It is 9-sliced to the pack row, so its centre must be a
  uniform field for the same reason as R400.
- AC: the **lantern** shows a frame, glass, a flame inside it and a hanging fixture —
  presently a bracket and a bar.
- AC: the **banner** shows folds and a hem, so it hangs rather than lies flat.
- AC: all three keep their current dimensions unless a brief says otherwise, because each
  is positioned by constants that would otherwise need re-deriving.

## R402 — The seal-stamp sits at bench scale

- AC: the seal-stamp prop is **smaller** relative to the bench — reduced by four rather
  than three (37×57 → ~28×43).
- AC: the other two bench props are **unchanged**; only the stamp was oversized.

## R403 — The room is darker, and the light pools

- AC: the room's ambient falls, the darks deepen, and the warm pools tighten, so the
  bench reads as the lit working spot and the corners fall away (author ruling: moodier).
- AC: the pools stay **coupled to their fixtures** — the candle on the bench and the
  hanging lantern in the gutter (P95). A light with no visible source is a cheat.
- AC: the header, the record's prose and the rite plate keep their legibility; **drama
  is spent on surfaces, never on text**.

## R404 — Hover carries the light

- AC: at rest the shelves are genuinely dark. **Hovering or focusing an instrument lifts
  it out of shadow** — the existing gold edge (TD-103) plus a local brighten.
- AC: it is **presentation only** — no state is recorded, nothing is sent, and the
  instrument does not move (TD-103 retired the lift on purpose: an object that rises
  under the cursor reads as a UI element responding to a mouse).
- AC: **keyboard focus does the same thing as the mouse**, so the room is not darker for
  someone not using a pointer.
- AC: under reduced motion the brighten is instant rather than tweened.

## R405 (containment) — presentation only

- AC: **no change to** `src/**`, the gear catalog, bag rules, item descriptions,
  expedition logic, multiplayer behaviour, or any unrelated UI.
- AC: the Contract Board is **provably unchanged** — captured and its `keepout` readout
  compared, not judged by eye (TD-089's rule).
- AC: the author's furniture and the record board are **not redrawn** by this spec.

---

## Correctness Properties

- **P178 (one grade, one door):** every author-supplied asset enters the tree through
  `gen_qm_furniture.py` and takes the same measured grade. A second entry point is how
  two pieces of the same room end up in two different colour spaces — which is the defect
  TD-114 existed to fix.
- **P179 (a missing asset degrades, never errors):** until a briefed PNG is delivered the
  room renders what ships today. The spec is written so art can land one file at a time,
  and a half-delivered set must never be a broken screen.
- **P180 (relief is derived from its own diffuse):** a normal map is generated from the
  luminance of the exact image it belongs to, so the pixel the art darkens as a recess is
  the pixel the map tilts away from the light.
- **P181 (hover is presentation):** the hover brighten holds no state, sends no message
  and moves nothing. It is an affordance; the server authorises regardless (P148).
- **P182 (geometry is measured, not typed):** shelf rows, bay spans and 9-slice margins
  for the rebuilt cabinet are derived from the emitted PNG, so art and placement cannot
  drift apart.

## Performance budget (canon, `performance.md` P0)

Stated before building, measured after. The room currently reports `qm nodes=169/220`,
`particles=14/20`.

| | budget | note |
|---|---|---|
| node count | **≤ 220** | the cabinet grows but stays ONE sprite; three instruments per shelf adds no nodes, only positions |
| particles | **≤ 20** | unchanged — dust only |
| full-frame additive layers | **0** | a darker room must not be darkened by an overlay; ambient is a shader uniform |
| per-frame work | **none** | no `_process`; the hover brighten is a property set, not a tween that runs every frame |
| rebuild scope | hover and selection rebuild **nothing** | the defect TD-064/TD-065/TD-068 each fixed once |
| wall cost | one tiling 128×128 sampled by one shader | a larger tile is not a larger draw |

## Verification

- **V1 (R397, P182):** `--quartermaster` capture — the cabinet is ~240×199, four shelves
  per bay, three instruments per shelf; a printed readout confirms the shelf rows were
  measured off the PNG.
- **V2 (R398, P180):** capture with the wall delivered; a tiling self-check asserts the
  128×128 seams match on both axes; `--lights-off` shows the diffuse's own form.
- **V3 (R399, R400, R401):** captures — cloth, rite plate, satchel, lantern, banner each
  read as objects; the rite plate's two states both captured.
- **V4 (R402):** capture — the stamp sits at bench scale beside the quill.
- **V5 (R403):** capture — measured mean luma of the room falls, while the record's text
  contrast is re-measured and still passes.
- **V6 (R404, P181):** `--qm-hover` capture with an instrument hovered; a check proves the
  brighten sets no state and sends nothing.
- **V7 (R405):** `git diff` touches no `src/**`; the board's `keepout` readout is
  unchanged; `qm_budget.py` and `asset_map.py` selftests green.
- **V8 (P179):** with every briefed PNG temporarily absent, the room still builds and
  captures without an error.

## Open questions

None blocking. Answered by the author on 2026-08-11: cabinet rebuilt at 1:1; the author
draws the replacements; the wall keeps its shader and gains form; lighting goes moodier;
hover carries the light; scope is wall + cloth + rite plate + satchel/lantern/banner.
