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

- [x] T260e [R243 L2 / V2] — **The props, generated.** `client/assets/ui/gen_title_props.py` emits
      the censer (chain to the top edge, pierced brass vessel, ruby panels), the chandelier (an iron
      corona on three chains, twelve prickets), the candle rack (two ranks of tapers at differing
      heights, wax runs clinging to the tray lip) and the brazier (riveted bowl, three legs, dead
      coals). Anti-aliased signed-distance parts composited back to front — a hard alpha would crawl
      the moment the rig scales it. **Python, not Aseprite, and not a contradiction of TD-057:** that
      finding was measured at 17×22 px; at 140–520px in the painted register the job is form, and a
      hand-placed pixel would be resampled away. Nothing burns (rule 6).
      Test: **V2** — `--title-preview` captured. Dimmed after the first capture washed the candles
      to near-white: an unlit asset in a torch-lit hall must be dark enough that the FIRE brightens
      it. The same correction the banners needed.

- [x] T260f [R241, P128 / V1] — **The architecture layers, cut from one camera.**
      `client/assets/ui/gen_title_arch.py` emits the seven pieces as **slices of the plate**, not a
      second drawing of it: every pixel comes from `plate_px`, and each layer keeps only the pixels
      whose ray strikes its surface (walls split near/far at z=14m per design.md, then by side).
      **Placement is derived** — each layer is cropped to the box its surface actually occupies and
      the generator prints that box back as the viewport fractions ARCH wants, so the table can
      never drift from the geometry. `_layer` gained the plate's overscan for architecture, or the
      slice would sit 1.2% inside the plate and show a hairline double edge.
      Test: **`python3 gen_title_arch.py --verify`** — reassembles the seven committed layers at the
      placement parsed out of `title_scene.gd` and diffs against the committed plate:
      **2,073,600 px, 0 uncovered, 0 mismatched.** One check proving the layers tile the frame, carry
      the plate's shading, and still match the rig's numbers.

- [x] T260 [R241 / V1] — **18 of 18 slots filled**, all generated: `gen_title_plate` /
      `gen_title_overlays` / `gen_title_banners` / `gen_title_props` / `gen_title_arch`.
      Author-painted art still replaces any slot by name via `art/src/title/` — the rig neither knows
      nor cares which produced a file.
      Test: **V1** — `python3 tools/title_assets.py --check` reports 18 of 18 with no contract
      violation; `--title-preview` captured with every layer present.

- [x] T261 [R245, R247 / V4, V5] — **Legibility pass; second integer scale; asset-map; suites.**
      Captured at 1280×720 (logical 640×360) and 1920×1080 (logical 952×520): title, emblem and all
      four options legible at both, no layer seam, plate undistorted. The second scale is what
      **found** the R245 defect — at 952×520 "Quit" landed on the one bright patch in the hall — so
      the apse was held down and the centre glow pool dimmed to 0.42 (it had been standing in for an
      altar the plate now paints itself). `asset_map --selftest` + `--check`, `title_assets
      --selftest`, `spec_status --check` all green. Suites untouched and green: server 362, shared
      65, tools 7. Diff scoped to `client/ specs/ docs/` — no `src/**` change (R247).

- [x] T263 [R245 / V4] — **Composition pass, on the author's review of the finished screen.** The
      positions were authored against labelled blockouts, and two of them fought the UI once real
      art landed: the centre banner sat directly behind **TESTAMENT**, and the censers flanked the
      title so closely at 0.383/0.617 that they read as part of it. The censers move **outboard** to
      0.292/0.708 over the aisle; the centre banner moves **up and deep** (0.360→0.086, w
      0.072→0.040) so it hangs from the frame's top edge and stops above the corona. The centre of
      the frame is now the UI's alone.
      A censer's position was written in **four** places — the prop, its glow pool, its incense
      emitter, and the plume baked into `smoke_overlay.png`. Three are now one constant
      (`CENSER_LX`/`CENSER_RX`/`CENSER_FIRE_Y`) and the fourth, being in Python, is a commented
      mirror; the overlay was re-rendered, or the hall would smoke from where nothing hangs.
      Test: **V4** — captured in both motion states; title, rule and all four options sit on dark
      nave with no layer behind them.

- [x] T264 [R241, R243 L2 / V2] — **The floor props stand in the perspective, and stop being
      mirrors.** Two faults, one pass. (1) Both racks and both braziers were the same file drawn
      twice, so the hall was symmetrical in a way the plate's own walls deliberately are not — each
      is now its own **seeded** variant (taper counts and heights, bowl proportions, leg spin, wax
      runs, wear), and the right-hand pair stands further down the nave: smaller, higher in frame.
      (2) They were drawn **plumb** in a scene whose camera is pitched up 15°, where every vertical
      converges on a zenith at fy ≈ −2.05 — so each prop is now sheared toward the zenith **its own
      floor position implies** (`lean_for`), between 6° and 13°. A shear, not a rotation: the foot
      stays where it was placed and only the height tilts, which is what perspective does to a
      standing object. `Canvas` pads the image for the shear and `gen_title_props.py` prints the
      `VESSELS` lines, so the rig's numbers stay derived. `FIRES` moved with the vessels — a fire
      burns *on* something. Slots 18 → 20.
      Test: **V2** — captured; the props now tilt with the piers above them rather than against
      them, and `title_assets --check` is green at 20 of 20 (it caught the two new files missing
      from the manifest, which is the check doing its job).

## Phase C — The overhaul (TD-075)

- [x] T265 [R241, R242-withdrawn / V1] — **The hall, re-authored as pixel art.** The author supplied
      two references with a precedence rule: composition from the concept art, **craft from the
      Contract Board**. Everything shipped since TD-073 failed that — a painterly 1920×1080 plate
      with per-pixel noise, drawn into a 640×360 viewport through a LINEAR filter. `gen_title_hall.py`
      authors at **640×360, drawn 1:1 through NEAREST**, every colour a ramp index, light in flat
      steps, depth banded **per bay** so tone changes land on pier edges, joints gated by distance.
      Camera pitched 15°→21° and the nave shortened to 58m, so the vault crowds the top and the
      sanctuary sits low — Reference A's composition, and it frees the frame's centre for the UI.
      Test: **`A.assert_on_palette`** passes — the same check the board's own art passes, which is
      what "matches the Contract Board" means in a form a machine can check. Captured.

- [x] T266 [R243 / V2] — **Cloth and furniture, re-authored at display size.**
      `gen_title_furniture.py` replaces the props and banners generators: three banners, censer,
      chandelier, two racks, two braziers, authored at **20–96px**, the size they are shown. Flat
      tones from shipped ramps, no form shading, no AA. All nine pass `assert_on_palette`.
      Test: **V2** — captured; `title_assets --check` green at 13 of 13.

- [x] T267 [R243 L4 / V2] — **Overlays re-cut at the internal resolution.** Dust motes are whole
      pixels (1px, the odd 2×2), the god ray is **three flat bands**, smoke is four alpha steps. A
      continuous falloff would need dithering, which the brief rules out.

- [x] T268 [R247 / V5] — **Retire what the brief supersedes.** `gen_title_plate.py`,
      `gen_title_arch.py` and the seven architecture slices are deleted — the cathedral is a bespoke
      hero environment and must not become reusable architecture. The camera drift is gone too: the
      brief makes the architecture static, and a 2px drift resampled a plate that must stay on whole
      pixels. Slots 20 → 13. DECISION_LOG **TD-075**.

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
