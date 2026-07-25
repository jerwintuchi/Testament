# Tasks — The title screen: a layered Collegium hall (TD-073)

> T# continues global from T254. Client render only; the named test is a capture.
> **Revised twice.** The single procedural plate (TD-072) and the concept-art matte were both
> withdrawn on author ruling. The concept art is a **composition reference only** — it is not
> shipped and not displayed. The scene is built from independent layers, each rendering a labelled
> **blockout** until its art exists.

## Phase A — The rig (done)

- [x] T255 [R241, R243 / V1] — **`ui/title_scene.gd`.** Every layer an independent node in its real
      position, at its real size, with its real animation, drawn as a labelled placeholder until
      its texture lands: architecture (piers/arcades/vault/apse/floor), cloth, hanging props,
      vessels, overlays. Art is loaded by exact filename and a missing file degrades to a blockout
      rather than erroring — which is what decouples the engineering from art delivery.
      Test: **V1** — `--title-preview` capture shows every layer labelled and placed.

- [x] T256 [R243 L3 / V2] — **Fire + light.** A warm additive pool at each of seven fires with
      **seeded, non-synchronised** flicker. `Light2D` cannot reach Control nodes (TD-047), so the
      pool is an additive radial — the same call the board's torches make.
      Test: **V2** — capture; no two fires pulse together.

- [x] T257 [R243 L4 / V2] — **Atmosphere.** Real `CPUParticles2D`, art-independent so they are
      finished work now: hanging dust motes across the volume, warm embers rising off each fire,
      cold slow incense off the censers. `preprocess = lifetime` so nothing switches on at boot.
      Test: **V2** — capture; motes and embers read, and never cross the menu's reading area.
      Note: `scale_amount` multiplies the 128px radial, so 1.0 is a 128px blob — the first pass
      used unit scales and blew the frame out to white. Motes are hundredths.

- [x] T258 [R243 L1-L2 / V2] — **Motion by kind.** Cloth slow sway; props pendulum with randomized
      phase; overlays drift/breathe; camera 2px idle drift + 1.004 breathing zoom. All looping
      tweens, so nothing needs `_process` and the rig frees with its node.
      Test: **V2** — capture over several seconds; motion is imperceptible frame to frame.

- [x] T259 [R244 / V3] — **Reduced motion.** F9 skips every animation and every particle system.
      Test: **V3** — captured; the frozen frame is **fully lit** (all glow pools present, every
      layer visible) and loses no information.

## Phase B — Art (blocked on assets)

- [x] T260a [R241, R243 / V1, V2] — **The drop path, made real.** The manifest and the rig had
      drifted: the rig loaded seven per-piece architecture slots the manifest never named, and the
      manifest asked for a `hall_plate.png` the rig had no slot for plus a `chain.png` nothing
      loads. Since the rig loads by exact filename and silently skips the unknown, that art would
      have been generated and then simply never appeared. Fixed three ways — the rig now takes
      `hall_plate.png` as a full-frame plate (aspect-preserved, 1.2% overscan against the camera
      drift, inert per P128) with the seven pieces demoted to **optional overrides**; the manifest
      is re-cut to the rig's exact slots; and `tools/title_assets.py` derives the slot list from
      `title_scene.gd` and fails when the two disagree. See DECISION_LOG TD-073 addendum.
      Test: **V1/V2** — `python3 tools/title_assets.py --selftest` green, `--check` exits 0 at 0/18
      slots; a throwaway synthetic plate installed + imported + captured (`--title-preview`) shows
      the architecture blockouts replaced, undistorted, no edge seam, overlays still animating.

- [x] T260b [R241, R242 / V1, V3] — **The plate, generated** (author's call: *"generate the
      hall_plate.png with the generators instead"*). `client/assets/ui/gen_title_plate.py` emits
      1920×1080 by ray-casting the hall through the camera imported from `gen_nave.py`. This
      **retries TD-072's recorded failure** and is narrower where it failed: no props (the class
      that failed at small scale) and no baked fire (the light is in-engine), leaving architecture,
      which the ray-caster was always good at. Symmetry — TD-072's third finding — is answered with
      seeded per-bay variation: opening widths differ ±6% **between the two walls**, clerestory
      panels vary in brightness and colour with some boarded, ashlar courses drift, weathering is
      per bay and the left wall is grimier. The near falls to **silhouette** (inverting TD-072),
      because the foreground is lit by fires that live in the engine, not in the plate.
      DECISION_LOG 2026-07-25.
      Test: **V1/V3** — `--title-preview` captured with the plate in place: architecture blockouts
      replaced, undistorted, no seam; menu legible (the engine's glow pools were retuned 0.34→0.26,
      having been set against a black backdrop); F9 reduced-motion still frame fully lit.

- [x] T260c [R243 L4, R244 / V2, V3] — **The atmosphere overlays, generated.**
      `client/assets/ui/gen_title_overlays.py` emits all three: `dust_overlay.png` (1400 seeded
      motes splatted into an alpha buffer — a size distribution, not a uniform field of specks,
      which is what reads as snow), `smoke_overlay.png` (fBm plumes leaving from the censers'
      own positions, widening and wobbling as they rise), `light_shaft.png` (a wedge that widens
      as it descends, dies before the floor, and carries faint tracery striations). Pure surfaces
      — Python's half of the TD-057 split. RGB is flat white and the image lives entirely in the
      **alpha channel**, so under the rig's additive blend the contribution IS the alpha and
      `modulate` stays an honest dimmer. The frame's centre is thinned because the menu is read
      there (R245).
      Test: **V2/V3** — `--title-preview` captured: motes read across the volume, the shaft falls
      through the left of the nave, smoke drifts under the vault; menu still legible; the F9 still
      frame keeps all three (they are textures, so reduced motion loses nothing).

- [x] T260d [R243 L2 / V2] — **The banners, generated.** `client/assets/ui/gen_title_banners.py`
      emits all three standards in the **painted** register (340px wide, so smooth drape shading is
      right where it would be wrong on the board's 64px cloth): woven crimson, baked folds that
      wander as they fall, a ragged foot resolved per column as alpha, worn-through holes whose rims
      dissolve into the weave, loose threads, and the Collegium device as a bone dye. Each banner is
      **seeded separately** so the right one is "mirror-ish, not identical"; the **iron rod is in the
      image** because the rig sways from top centre, so cloth and rod swing as one object.
      Test: **V2** — `--title-preview` captured; the banners hang on the piers and sway. Faded a
      second time after the first capture showed them out-saturating their own hall — the
      "pasted on" failure TD-059 spent a spec fixing for the board's banners.

- [ ] T260 [R241 / V1] — Drop in the remaining assets per `asset-manifest.md` — props, vessels, and
      the seven optional architecture overrides (**7 of 18 slots filled**). What is left is the
      **Aseprite half** of the TD-057 split: censer, chandelier, candle rack, brazier — objects
      where a pixel is a design decision and a shape function blobs.
      **No code change** — each file simply replaces its blockout. Stage into `art/src/title/`,
      then `python3 tools/title_assets.py --import`.

- [ ] T261 [R245, R247 / V4, V5] — Legibility pass; second integer scale; asset-map; suites; land.

## Blocked

- [ ] T262 [audio] — **Ambient audio.** BLOCKED: no audio assets, no audio pipeline, and no
      sanctioned audio tool (closed list; adding one needs explicit approval).

## Notes

- **The concept art is never shipped.** `art/src/collegium_hall_src.png` is a composition reference.
  Using it as the background was tried and rejected by the author.
- **Do not procedurally reconstruct architecture** — TD-072 established that ceiling over four
  passes.
- Positions in `title_scene.gd` are authored constants in viewport fractions; retuning the
  composition is a one-line edit per layer.
