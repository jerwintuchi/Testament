# Tasks — The Great Hall from curved geometry (TD-076)

> **STATUS: PROCEDURAL ROUTE RESUMED** — the author asked for the plate to be generated after all,
> in the Contract Board's register. Phase A is UNPARKED and its geometry work is done; Phase D (the
> supplied-plate path) stays available and unstarted, since the rig takes `hall_plate.png` by name
> whoever produced it.
> T# continues global from T268. Client render + generated art only; the named test is stated for
> each task before any code is written (`spec-workflow.md`).
>
> Ordered so the author sees the fix for the reported defect **first**, in one reviewable slice,
> before any of the enrichment work is spent on top of it.

## Phase D — The supplied plate (LIVE)

- [ ] T277 [R260 / V1] — **Land the plate.** `art/src/title/hall_plate.png` → validated, installed
      and imported by `tools/title_assets.py --import`. Crop to 16:9 without distorting the
      composition; no resampling beyond that.
      Test: `--check` green; `--title-preview` captured.

- [ ] T278 [R262 / V1, V4] — **`gen_title_matte.py`: down-register the supplied art.** Crop to 16:9,
      BOX downsample to 640×360, median, quantise to Ash & Ember, then mode passes. NEAREST stays
      everywhere — the plate is brought into the register rather than given a softer filter.
      Test: the landed plate measures **<600 single-pixel islands, ≤34 colours, run-continuity
      ≥0.83** (naive downscale scores 5876 / 41 / 0.474 and fails), and `assert_on_palette` passes.

- [ ] T279 [R261 / V2] — **Reconcile the props.** Either wire the author's matching prop art, or
      disable the cloth/props/vessel layers because they are baked into the plate. The fire pools,
      dust, smoke and rays stay live either way.
      Test: capture; one register across the whole frame, and the animated layers that remain still
      read as atmosphere.

- [ ] T280 [R255, R256 / V5, V6] — **Land it.** Legibility at two scales; `title_assets --selftest`
      + `--check`; asset map; suites; DECISION_LOG for the route change and for withdrawing TD-075's
      pixel discipline from the title screen.

---

## PARKED — the procedural route

*Kept as the record of the flat-plane finding and the camera measurement. Not started.*

## Phase A0 — The camera, measured (R259)

- [ ] T268a [R259 / V1] — **Land `tools/measure_reference.py`.** Already written and run: it solves
      the camera from two vanishing points, and — the part that matters — **checks its own fits
      against the hall's symmetry and rejects them when they fail**. It has already rejected one bad
      cornice fit (intersection at fx −7.04) rather than handing back a plausible-looking wrong
      camera.
      Test: run against Reference A; the zenith fit passes its symmetry check (fx 0.475 vs 0.5), the
      cornice fit is reported as rejected. Both are the current recorded results.

- [ ] T268b [R259 / V1] — **Fit the camera and the hall's proportions.** One vanishing point is
      recoverable, so the solve is under-determined; the zenith survives as the hard constraint
      `cot(P) = 6.832·TAN_V` and the rest is closed by minimising landmark error (vault crown fy
      0.335, lit far end fx 0.256–0.746, near piers to fx 0.329/0.669).
      Test: the **same measurement code** run against our render reproduces each target within
      tolerance. The reference and the render are measured identically or the comparison is worthless.

- [x] T268c [R259 / V2] — **Model the aisles and the wet floor.** The arcade currently opens onto
      black; in Reference A it opens into a lit aisle, and that is most of the depth. The floor
      reflects, via a second ray mirrored about the floor plane.
      Test: capture; the arches read as openings into a space, and standing objects appear beneath
      themselves on the flags.

## Phase A — The geometry (the reported defect)

- [x] T269 [R248, P129 / V1] — **`hall_geometry.py`: the camera and the curved vault.** Move the
      measured camera out of `gen_nave.py`; add the groin vault as the intersection of a transverse
      and a longitudinal barrel, solved bay by bay as quadratics (no marching). `trace()` returns
      kind, world point, **unit normal**, distance.
      Test: `python3 hall_geometry.py --selftest` — on a horizontal scanline across a web carrying
      no rib, the surface normal's `x` component **changes sign** across the nave and its magnitude
      is monotonic to either side. A plane cannot satisfy that; a barrel does by construction.

- [x] T270 [R249, P129 / V1] — **Round piers.** Compound piers as a core cylinder plus engaged
      colonnettes, ray-cast, with normals; the wall behind stays a plane.
      Test: `--selftest` — a scanline across one colonnette yields `n·L` rising then falling, and
      the rendered indices read dark → light → dark. Painted stripes cannot produce that order.

- [x] T271 [R253, P131 / V3] — **Lighting from normals, in world space.** Point lights with radius
      and strength; contribution `max(0, n·l̂)·falloff`, summed and **banded to an integer** before
      it reaches the output.
      Test: capture with lights on and `--lights-off`; every difference is local to a source. Plus
      an assertion that the light term's type is `int` at the point of use (P131).

- [ ] T272 [R248, R249, R254, R258, P130 / V1, V4] — **Re-render the plate on the new geometry, at
      1280×720.** `gen_title_hall.py` keeps its material and banding discipline and drops every
      painted-curvature hack (rib lines on a plane, shaft stripes on a wall). Authoring resolution
      goes to 1280×720 so the grain is fine enough for the detail Phase B adds.
      Test: `A.assert_on_palette` passes; `--title-preview` captured, and the capture is checked for
      1:1 device mapping at `int_scale 2`. **This is the slice the author reviews before anything
      below is built.**

## Phase B — Density and content

- [ ] T273a [R257 / V2] — **Lift the three detail gates.** Coursing on every lit stone where a bed
      projects ≥2px (including the near piers, currently blank); per-stone variation across the whole
      visible range; ribs the full length of the vault, thinning rather than switching off. Add the
      arcade's moulding profiles and capitals.
      Test: capture; the near piers carry visible masonry, and the vault reads as vaulted to the
      sanctuary. The readability check is the brief's: it still resolves at a glance from a distance.

- [ ] T273b [R250 / V2] — **Furnish the hall.** Tables, benches and candle stands as world-space
      primitives along both aisles; memorial plaques on the aisle walls; a **detailed niche** — recess, moulded surround, canopy, plinth, cast shadow — with a robed
      figure, which resolves at 1280×720. Per-bay primitive lists so a pixel only tests its own bay.
      Test: capture; furnishings recede correctly and occlude each other; the far nave stays quiet.

- [ ] T274 [R251, R257 / V2] — **Windows that read as windows, with tracery.** The nearest bay on each side turns its
      window wall ~35° toward the viewer, carrying a full traceried window in the upper corners; a
      cool wash from the (unseen) west window opposes the warm candlelight.
      Test: capture; at least two windows show tracery rather than slivers.

- [ ] T275 [R252 / V2] — **Age.** Chipped block corners, worn stair treads at the sanctuary, wax
      build-up at the candle stands, banded soot above every flame, a polished processional line.
      Test: capture; reads ancient and **maintained**, never ruined.

## Phase C — Landing it

- [ ] T275b [R258 / V5] — **Re-author the furniture at 1280×720.** The banners, censer,
      chandelier, racks and braziers double in size (20–96px → 40–192px), which is where chain links,
      taper detail and iron work start to resolve.
      Test: `assert_on_palette` on all nine; `title_assets --check` green.

- [ ] T276 [R255, R256 / V5, V6] — **Legibility, contract, suites.** Captures at two integer scales
      with all four menu options legible; `title_assets --selftest` + `--check`; asset map
      regenerated + `--check`; server and shared suites green; diff scoped to `client/ specs/ docs/`.
      Retire `gen_nave.py`, whose flat-plane `hit()` this spec replaces.

## Notes

- **The statue's figure is IN**, on the author's ruling for a detailed niche. It is drawable because
  R258 doubled the grain: ~90px tall at 1280×720, where at 640×360 it would have blobbed — the
  finding TD-056/TD-057 already paid for twice. If it blobs anyway, the niche stands without it
  rather than shipping a smudge.
- **No gameplay reuse.** The brief is explicit that this hall is a bespoke hero environment. Nothing
  in `hall_geometry.py` is designed for the modular top-down pipeline, and it should not be borrowed
  for it.
- **All four of the author's rulings are folded in:** semicircular vault, detailed niche with a
  figure, nave length unchanged at 58m, and authoring at 1280×720 rather than 640×360. No open
  questions remain in `design.md`.
