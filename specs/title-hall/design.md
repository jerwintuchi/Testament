# Design — The Great Hall from curved geometry (TD-076)

> **Status:** DRAFT — awaiting approval. Satisfies R248–R256. Client render + generated art only.

---

## The one idea

Stop painting curvature onto planes. **Model the surfaces that are curved, cast rays at them, and
let the surface normal do the shading.** Everything the author reported as "flat" — the ceiling, the
columns — is downstream of the hall being four planes.

Today's model, and what it can never express:

| Surface | Today | Why it reads flat |
|---|---|---|
| Vault | plane at `y = 37` | one normal everywhere; ribs are lines drawn on a ceiling |
| Walls | planes at `x = ±8` | colonnettes are stripes; nothing turns away from the light |
| Piers | (not modelled) | — |

## Geometry

A new module, `client/assets/ui/hall_geometry.py`, owns the hall's shape and nothing else. It
exports one function:

```python
trace(fx, fy) -> Hit(kind, p, n, dist, meta)   # kind, world point, unit normal, distance, extras
```

No colour, no ramps, no palette. That separation is what lets the geometry carry its own tests.

### The vault: a groin vault as the intersection of two barrels

A quadripartite bay is two barrel vaults crossing. Each barrel springs from the same line and the
**lower of the two surfaces is the ceiling**; where they meet is the groin — which is exactly where
the diagonal rib belongs. So the rib stops being a painted line and becomes a place the geometry
already has.

```
transverse barrel (across the nave, axis along z):
        x² + (y − SPRING)² = R²          R = HALF_W  = 8m
longitudinal barrel (along the bay, axis along x, one per bay at z = zc):
   (z − zc)² + (y − SPRING)² = r²        r = BAY/2   = 3.5m

vault(x, z) = SPRING + min( √(R² − x²),  √(r² − (z − zc)²) )
```

`SPRING` is the springing line (the height the vault leaves the wall, ≈22m — the clerestory head).
A **pointedness** parameter reuses `gen_nave.lancet`'s two-centred construction so the profile can be
Gothic rather than Roman; semicircular is the fallback and is already an improvement on a plane.

**Intersection, without marching.** A ray-march at 640×360 would be 15M evaluations and take minutes.
Instead the ray is walked **bay by bay** — it crosses at most ~8 — and inside each bay both barrels
are solved as quadratics in `t`. A candidate hit is accepted when the *other* barrel is higher at
that point (i.e. this one is the lower surface). First accepted hit wins. Bounded, exact, ~16
quadratics per pixel.

**Normal.** For the transverse barrel `n = normalize(x, y − SPRING, 0)`, for the longitudinal
`n = normalize(0, y − SPRING, z − zc)`, both pointing down into the nave. The web now shades across
its own curve, which is R248's measurable test.

### Piers: bundles of vertical cylinders

The wall behind stays a plane — a wall *is* flat. Standing proud of it, each compound pier is a core
cylinder plus 4–6 engaged colonnettes:

```
(x − xc)² + (z − zc)² = rc²      solved as a quadratic in t; y bounded to [0, pier top]
n = normalize(x − xc, 0, z − zc)
```

A shaft's lit side, its turn and its shadow then all follow from `n·L`, which is R249's test: a
scanline across one colonnette must read dark → light → dark.

### Furnishings (R250)

World-space primitives, so they occlude and recede correctly:

- **Tables and benches** — axis-aligned boxes (slab test), walnut ramp.
- **Candle stands** — thin vertical cylinders with a disc top; the tapers are the existing furniture
  sprites' idiom re-used in world space.
- **Plaques** — flat quads on the aisle wall, slightly proud, bronze ramp.
- **Statue in a niche** — a niche is a half-cylinder recess in the wall; the figure itself is the one
  piece where a shape function will blob (TD-056/TD-057), so it is authored as a **small hand-placed
  sprite** composited at its world position and depth, not ray-cast.

Culling: each bay holds a list of its own primitives, so a pixel only tests what its bay contains.

### Windows that read as windows (R251)

At this camera the nave walls are grazing, which is why the clerestory resolves as slivers. Two
additions fix it without moving the camera:

1. **Angled aisle bays near the frame edge.** The nearest bay on each side turns its window wall
   ~35° toward the viewer, so a full traceried window faces the camera in the upper corners — which
   is where Reference A's brightest glass sits.
2. **A west window behind the camera** is not visible, but its light is: a bright, cool wash on the
   near piers, banded, opposing the warm candlelight.

## Shading

Materials never choose a colour directly; they choose an **index**, exactly as TD-075 established.
What changes is where the index comes from:

```
idx = material_base
    + band(ambient(n) + Σ lights)      ← integer, 0..3          (P131)
    + depth_band(bay)                  ← per bay, not per pixel
    − vignette_band(fx, fy)
colour = RAMP[material][clamp(idx)]
```

`ambient(n)` is a two-step term from `n·up` (surfaces facing down are darker). Each light is a world
position with a radius and a strength; its contribution is `max(0, n·l̂) · falloff` — so a candle
stand lights the pier beside it and the floor under it, and nothing across the hall (R253). The sum
is banded to an integer **before** it reaches the output, which is P131 and the reason no dithering
is ever needed.

## Age (R252)

All per-block or per-feature, never per pixel:

- **Chips** — a seeded corner of a block loses 1–2 pixels to the joint's index.
- **Worn treads** — the front edge of each sanctuary step takes a lighter index; the tread behind it
  does not.
- **Wax** — pale accumulation at candle-stand bases, in two flat steps.
- **Soot** — a banded rise above every flame position, on the wall behind it.
- **Polish** — the floor along the processional line takes a lighter index than the aisles.

## Performance

Per pixel: one camera ray, ≤16 quadratics for the vault, the bay's cylinders and boxes, and the
plane set. Estimated 60–120s for a full 640×360 render — the same order as the generators already in
the tree, and it stays a one-command regenerate.

## Correctness Properties

- **P129 (curvature is geometric):** roundness comes from normals. The scanline self-tests in
  `hall_geometry.py` fail if a web or a shaft is flat, so a regression to painted curvature is
  caught at the command line rather than in a capture.
- **P130 (on-palette):** `assert_on_palette` on every emitted asset.
- **P131 (integer light):** the light term is an `int` by construction.

## Files

**New:** `client/assets/ui/hall_geometry.py` (camera + primitives + `trace` + geometry self-tests),
`specs/title-hall/*`.
**Rewritten:** `client/assets/ui/gen_title_hall.py` — materials, banding, wear; consumes `trace`.
**Unchanged:** `gen_title_furniture.py`, `gen_title_overlays.py`, `title_scene.gd` (the rig already
draws 1:1 NEAREST; only the plate's content changes).
**Retired on landing:** `gen_nave.py` — its camera moves into `hall_geometry.py` and its flat-plane
`hit()` is the thing this spec exists to replace.

## Open questions for the author

1. **Vault profile** — pointed (Gothic, matches Reference A) or semicircular (Romanesque, simpler)?
   Default: pointed.
2. **The statue** — worth the hand-authored sprite, or leave the niche empty for now? Default:
   niche modelled, figure deferred.
3. **Bay count in view** — the nave currently closes at 58m (≈8 bays). Longer reads more immense but
   makes the far half tiny at 640×360. Default: keep 58m.
