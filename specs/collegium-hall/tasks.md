# Tasks — The Collegium stops being a greybox (TD-081)

> T# continues global from T309. Client render + generated art; the layout stays server-owned.
> Phased so each phase is capturable on its own.

## Phase A — Light and stone

- [ ] T310 [R293, P142 / V1] — **Prove `Light2D` reaches the world layer, before building on it.**
      `SpaceView` is a `Node2D`, so it should — but TD-047 recorded the opposite for Control and that
      finding has shaped every lighting decision since. Drop one `PointLight2D` into the Collegium and
      capture with and without it.
      Test: **V1** — two captures; if the lit one differs, the premise of this whole spec holds and
      the result is written into the DECISION_LOG as the correction to "Light2D doesn't work in
      Testament". If it does not differ, **stop** and re-plan Phase A around the additive technique.

- [ ] T311 [R294, P144 / V2] — **`gen_collegium_tiles.py`.** Four floor variants (worn flags, mortar,
      chipped corners), two wall cells reading as the base of a wall from above, and a threshold cell
      so floor-meets-wall is not a butt seam. 16×16, `NEAREST`, `assert_on_palette`.
      Plus `tiles_n.png` from the same height field, the `gen_normals` idiom.
      Test: **V2** — captured: no grid seam, no visible repeat across the 22-tile span; a second run
      of the generator is byte-identical.

- [ ] T312 [R293, R298 / V1, V5] — **Light the hall.** Six `PointLight2D`s — one per station, one at
      the spawn atrium, two along the walk — warm, generous falloff, genuinely dark between them. The
      `TileMapLayer` takes a `normal_map` so the stone has relief.
      Test: **V1** — `--lights-off` visibly removes them; **V5** — the budget check passes at ≤6.

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
