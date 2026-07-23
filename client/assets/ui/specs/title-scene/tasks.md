# Tasks — The title screen as a composed, lit scene (TD-073)

> T# continues global from T254. Client render + generated art; the named test is a capture.
> Staged so something renders early: layers → composition → props → light → motion.

## Phase A — Architecture layers (Python)

- [ ] T255 [R242, P128 / V1, V2] — **`gen_nave_layers.py`.** Import TD-072's projection unchanged
      and emit `nave_far`, `nave_mid`, `pier` (+ normals) as **depth slices** of the one camera,
      transparent outside their range.
      Test: **V2** — the three layers share a vanishing point by construction; capture shows no seam
      where slices meet.

- [ ] T256 [R241 / V1] — **`ui/title_scene.gd` + composition.** Layer the sprites at authored
      offsets (asymmetric), mirror the pier, add the backdrop; `_show_title` instances this instead
      of the single `TextureRect`.
      Test: **V1** — `--title-preview` shows the composed scene; emblem/title/options still legible.

- [ ] T257 [R242 / V1] — **`gen_title_banner.py` + `floor_wet`.** Cloth with baked folds + normal
      (the `gen_banner` idiom, at title scale); floor with runner and a reflection band.
      Test: **V1** — capture; the banner reads as hanging cloth and the floor catches the light.

## Phase B — Props (Aseprite)

- [ ] T258 [R242 / V1] — **`censer.aseprite`, `candle_rack.aseprite`, `shrine.aseprite`**, authored
      in Aseprite via the batch pipeline and exported beside their sources. Irregularity is the
      point: tapers at varying heights, censers hanging at different angles.
      Test: **V1** — capture; the props read as hand-made, not repeated stamps.

## Phase C — Light and life

- [ ] T259 [R243 / V3] — **The light rig.** A `PointLight2D` per flame, warm, with normal maps on
      the lit layers so the stone takes real relief.
      Test: **V3** — `--lights-off` renders the scene dark and flat, proving the rig lights it.

- [ ] T260 [R244 / V4] — **Subtle life.** Seeded, non-synchronised flicker; slow additive embers;
      a faint out-of-phase banner sway. **F9 freezes all of it** to a fully-lit static frame.
      Test: **V4** — captures with motion and with reduced motion; the frozen frame loses nothing.

## Phase D — Verify

- [ ] T261 [R245, R246 / V5, V6] — Legibility over the plate; re-capture at a second integer scale;
      asset-map `--selftest` + `--check`; diff scoped; suites green; DECISION_LOG TD-073; CLAUDE.md.

## Notes

- **The single-plate approach is not to be retried.** Four passes established the ceiling; the
  reasons are in design.md § Why the single plate failed.
- The TD-072 camera is correct and is **reused**, not rebuilt — it was measured from the reference.
- No board asset changes (P127 stands).
