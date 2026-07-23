# Tasks — The title screen: a matte-painted Collegium (TD-073)

> T# continues global from T254. Client render + art pipeline; the named test is a capture.
> Ordered so the screen looks right immediately (matte first), then gains life layer by layer.

## Phase A — The matte

- [ ] T255 [R241, R242 / V1] — **Import the concept art.** Copy to `art/src/collegium_hall_src.png`;
      `gen_title_matte.py` crops 1536×1024 → 16:9 by area-averaging (no distortion) and writes
      `assets/ui/title/collegium_hall.png`. Retire the generated `title/nave.png` from the client
      (keep `gen_nave.py` — its measured camera is reusable for field work).
      Test: **V1** — `--title-preview` shows the matte, undistorted, with the UI legible over it.

## Phase B — Life, layer by layer (each its own commit)

- [ ] T256 [R243 L3, L5 / V2] — **Fire + light.** A `PointLight2D` at each painted flame in the
      matte, warm, with **seeded non-synchronised flicker**; a slow "breathing" bloom/vignette
      overlay. This is the highest life-per-effort layer: the flames are already painted, so the
      lights simply make them live.
      Test: **V2** — `--lights-off` visibly removes their contribution; no two flames pulse together.

- [ ] T257 [R243 L4 / V2] — **Atmosphere.** `CPUParticles2D` for dust, ash and slow embers: large,
      low-opacity, very slow, drifting through the light. Never crosses the menu's reading area.
      Test: **V2** — capture; particles read at the edges of vision, not as snow.

- [ ] T258 [R243 L1, L2 / V2] — **Cloth + hanging props.** The banners and censers are *painted into
      the matte*, so animating them needs them cut out and the hole behind them filled. Cut
      `banner_l/r.png` and `censer_*.png` from the source, inpaint the matte beneath, and re-place
      them as sprites with a slow sway / randomized-phase pendulum.
      Test: **V2** — the cut edges are invisible against the matte; sway is imperceptible frame to
      frame but obvious over ten seconds.

- [ ] T259 [R244 / V3] — **Reduced motion.** F9 freezes every layer to a fully-lit static frame.
      Test: **V3** — captures with and without; the frozen frame loses no information.

## Phase C — Verify

- [ ] T260 [R245, R247 / V4, V5] — Legibility; second integer scale; asset-map `--selftest` +
      `--check`; diff scoped; suites green; DECISION_LOG TD-073 (including the TD-055 exception);
      CLAUDE.md.

## Blocked

- [ ] T262 [audio] — **Ambient audio.** BLOCKED: no audio assets, no audio pipeline, and no
      sanctioned audio tool (the toolchain is a closed list; adding one needs explicit approval).

## Notes

- **Do not procedurally reconstruct architecture.** Two attempts are on record (TD-072's plate; this
  spec's first draft). Modular architecture is reserved for procedural *expedition* environments,
  where replayability makes it pay.
- **Do not quantize the matte** to the Ash & Ember ramps — it is a painted environment exception to
  TD-055, and quantizing would destroy exactly the atmosphere it is here to preserve.
- Parallax is **off** by default (R246): the matte is one flat image and offsetting it would reveal
  that.
