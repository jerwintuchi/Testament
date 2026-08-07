# Tasks — The Collegium stops being a greybox (TD-081)

> T# continues global from T309. Client render + generated art; the layout stays server-owned.
> Phased so each phase is capturable on its own.

## Phase A — Light and stone

- [x] T310 [R293, P142 / V1] — **Prove `Light2D` reaches the world layer, before building on it.**
      `SpaceView` is a `Node2D`, so it should — but TD-047 recorded the opposite for Control and that
      finding has shaped every lighting decision since. Drop one `PointLight2D` into the Collegium and
      capture with and without it.
      Test: **V1** — two captures; if the lit one differs, the premise of this whole spec holds and
      the result is written into the DECISION_LOG as the correction to "Light2D doesn't work in
      Testament". If it does not differ, **stop** and re-plan Phase A around the additive technique.
      **RESULT: it works, decisively.** One `PointLight2D` (energy 2.0, warm, at the spawn atrium)
      against an otherwise identical frame: **peak channel delta 244/255, mean 33.21, 70.4% of the
      frame changed**. The tiles take a warm falloff, the Seeker sprite is lit, and the Deploy Gate
      marker brightens. TD-047's finding is confirmed as being about **Control nodes only**; the
      world layer was never subject to it. Recorded as **TD-083**.
      **And it surfaced the missing half:** there is no `CanvasModulate`, so a light can only *add* —
      the lit capture is a bright hall with a brighter pool in it, not a dark hall with light carved
      from it. R293's "genuinely dark between sources" needs a dark `CanvasModulate` under the
      lights. One node, folded into T312.
      Kept behind `--light-test` until T312 ships the real rig, since until then there is no other
      way to re-verify this.

- [x] T311 [R294, P144 / V2] — **`gen_collegium_tiles.py`.** Four floor variants (worn flags, mortar,
      chipped corners), two wall cells reading as the base of a wall from above, and a threshold cell
      so floor-meets-wall is not a butt seam. 16×16, `NEAREST`, `assert_on_palette`.
      Plus `tiles_n.png` from the same height field, the `gen_normals` idiom.
      **Shipped as a 64×32 atlas** — 4 flagstone variants, 1 flag-under-a-wall (carrying the shadow
      the wall casts down), 3 wall variants — plus `tiles_n.png` from the diffuse's own luminance,
      Sobelled through `gen_normals._normal_pixel` so the convention cannot drift from the board's.
      Palette is **`navestone`**, the warm ashlar authored for the nave: this room *is* the Hall of
      Petitions, seen from above instead of down its axis, which is what makes it the same building
      as the title screen. `space_view` picks variants from a hash of the tile's own coordinates —
      two players in the same room must be standing on the same floor (P144).
      **Three passes failed first, and the diagnosis was wrong twice:**
      (1) avoiding joints entirely for fear of redrawing the grid gave **noisy rubble** — and
      per-pixel noise is what TD-075 forbids outright;
      (2) small wear patches read as **pebbles lying on the floor** — objects, not stone;
      (3) a large stepped diagonal read as a **decorative tiled pattern**.
      The correction: a flagstone floor *is* a grid of joints — the difference from a debug grid is
      that the **stones vary**, not that the joints are hidden. With only seven ramp steps, a whole
      step across part of a 16px tile is enormous contrast, far more than worn stone has, so
      variation moved **flag-to-flag** and the detail budget went to a crack and a chipped corner.
      Test: **V2** — the hall mock and an in-engine capture show no grid seam and no visible repeat
      across the 22-tile span; the generator re-runs **byte-identical** (md5 unchanged).

- [x] T312 [R293, R298 / V1, V5] — **Light the hall.** Six `PointLight2D`s — one per station, one at
      the spawn atrium, two along the walk — warm, generous falloff, genuinely dark between them. The
      `TileMapLayer` takes a `normal_map` so the stone has relief.
      **Shipped:** six `PointLight2D`s placed from the snapshot (one per station, one over the
      central atrium, two on the walk at 55% toward the furthest stations — so crossing the hall
      passes through light rather than one unbroken dark middle), plus the `CanvasModulate` T310
      found to be the missing half. The `TileSet` texture became a **`CanvasTexture`** carrying
      diffuse + normal together, which is what lets the flagstones take the light with relief. The
      lamp falloff is memoized (S6/TD-064) rather than rebuilt per space change.
      **Three tuning corrections, each found by capture:**
      (1) at strength 5.0 the normal map made the **joints glow** — molten mortar, not stone — so it
      is 2.2, set by looking at the lit hall rather than at the normal map;
      (2) the first rig was **far too dark**, and the cause is worth keeping: the tiles from T311
      were authored to look right **unlit**, so the modulate darkened them a second time and they
      landed nearly black. Art for a lit scene must be authored at **full-light value** — the diffuse
      is what stone looks like with a lamp on it, and the darkness is the rig's job. T311's bases
      moved up a step and the wall face with them;
      (3) energy and reach then traded against ambient until the pools read as sources.
      Test: **V1** — `--lights-off` differs by **peak 245/255, mean 42.2**, and neutralises the
      modulate so the unlit control is a true one. **V5** — the ceiling is enforced *by construction*
      (`mini(MAX_LIGHTS, …)`, 6); T316 turns it into a check that can fail.
      **Honest caveat:** the pools are still fairly even, and final light tuning is better done after
      T313 — the gold marker squares blow out under any light and distort the read while judging it.
      **Darkened on the author's note** ("the floor was darker earlier — dark aesthetic vibes").
      Measured first, because the premise turned out to be wrong: the lit hall was *already* darker
      than the unlit T311 floor everywhere (29/39/30 against a flat 49/51/52), so what was remembered
      as darker was one of the **intermediate** T312 passes — the near-black ones walked back because
      the flagstone detail vanished. The knob for "how dark is this hall" is the **ambient, never the
      texture**: darkening the diffuse darkens the lit pools too and defeats the rig, while darkening
      the ambient deepens only what no lamp reaches. `DARK` 0.48 → **0.32** with energy 1.05 → 1.20 —
      far corner **19.2**, near a lamp **26.0**, and the joints still read where light falls.

## Phase B — The stations

- [ ] T313 [R295 / V3] — **Stations become objects.** Per-kind scenes replacing the gold
      `Polygon2D`: the **Contract Board** (reusing the art that already exists — a top-down view of it
      against the north wall is most of the work), the **Quartermaster**'s counter, the **Deploy
      Gate**. Each lit footprint matches `STATION_RADIUS`, so what you see is where the action is
      legal.
      Test: **V3** — captured; each is recognisable with its label removed.

- [ ] T314 [R295, R296 / V3] — **Retire the floating labels.** `Press E: <Station>` already names the
      station on approach, so a permanent white sans caption is a second naming of the same thing in
      the wrong typeface. Delete it; move the prompt to Cinzel.
      Test: **V3** — captured at distance (no captions) and on approach (the prompt names it).

## Phase C — Air and finish

- [ ] T315 [R297, R296 / V4] — **Dust, at the title's density.** Drifting in the lit volume only, at
      the title screen's slowness. No fog banks, no rolling smoke (TD-079's ruling holds).
      Test: **V4** — captured beside the title screen: same palette, same darkness, same restraint.

- [ ] T316 [R298 / V5] — **Make the budget a check.** Lights, particles, additive layers and
      per-frame work read out of the world scene and enforced, in the shape of `title_assets
      --budget`. **Proven to fail** by exceeding a ceiling.

- [ ] T317 [R299 / V6] — **Land it.** No `src/**` change; maps, registry and manifest regenerated;
      suites green; diff scoped. DECISION_LOG **TD-081**, including the `Light2D`-in-`world/` finding
      as an explicit correction to the inherited belief.

## Open, for the author

- **Changing your name.** TD-080 asks for it once and there is no way to change it afterwards. The
  Collegium is the natural home for that affordance — but it is a *feature*, not decoration, so it is
  listed rather than assumed. Say if you want it in this pass.

## Not in this spec

- The **lobby / room scroll** HUD.
- The **layout** — where stations sit, how large the hall is. Server-owned; changing it is a design
  decision, not a decoration one.
- **Animation rig** work on the Seeker.
