# Tasks — Contract Board blend pass (banner relight + header tone)

> T# continues global from T187 (board-header). Client render / generated art only — the named test
> is a `--board-preview` capture read back (client-spec convention; no Vitest). Order: art first (the
> new diffuse + normal must exist before the material can light them), then the wiring, then the
> header tone, then verify. Nothing is done without its capture check. Containment: no `src/**` (P104).

## Art

- [x] T188 [R177, R178 / P103 / V1, V2] — **`gen_banner.py` — crisp, dim, heavily tattered diffuse.**
      Rewrite to emit `banner_v1.png` at 64×176, per-pixel (no LANCZOS on the cloth): a darker
      lower-contrast crimson ramp + gentle baked fold value + fine weave (below the parchment/frame
      key); a **heavily tattered** silhouette (ragged per-column hem, a few worn-through holes near
      the foot, sparse loose threads — all alpha); a kept top hem; the Collegium emblem imprinted
      **subdued** (dim/desaturated bone ramp, lowered alpha). Provenance header (`@consumes
      collegium_logo.png`).
      Test: **V1/V2** — a board capture shows crisp NEAREST cloth with a ragged, holed, threaded hem,
      dim + blended, the emblem a faint printed device.

- [x] T189 [R179 / P102 / V3] — **`gen_banner.py` — the normal map.** Emit `banner_v1_n.png` (64×176)
      from the banner's own height field `Hf` (fold + creases + hem bump), Sobel → packed tangent-space
      normal (`gen_normals` convention, flat = 128,128,255, `FLIP_G=False`); **flat where the cloth is
      transparent** (outside silhouette / holes / between threads). Import both new/changed PNGs via
      `godot --headless --import`.
      Test: **V3** — with the material wired (T190) a capture shows the fold relief raking to the foot
      sconce; torn gaps don't light.

## Wiring

- [x] T190 [R179, R180 / P102 / V3, V4] — **Light + place the banner.** `board_decor.add_torches`
      gains a `banner_mat` param: the banner `Sprite2D` gets `material = banner_mat`, filter
      **NEAREST**, `modulate = Color(1,1,1)` (brightness from the shader), and the shadow copy NEAREST.
      Display width `≈0.10·vp.x` centred at `GUTTER_CX` so it sits **fully in the gutter** (clear of
      screen edge + board frame), height still capped above the sconce cup. `main.gd` builds
      `banner_mat` via `_surface_material("res://assets/ui/banner_v1_n.png", …)` and passes it.
      **Do NOT touch `GUTTER_CX`, `torch_rig`, or the sconce/flame placement** (P95).
      Test: **V3/V4** — a normal capture shows the banner warm at the foot / dark up top and fully
      on-screen inside both gutters (nothing clipped); a `--lights-off` capture shows it flat/dim.

## Header

- [x] T191 [R181 / P105 / V5] — **Darken the header wood.** In `gen_header.py`, pull the wood ramp
      (`WALNUT` + lip/field values) down toward the near-black board — "darker but not so much" —
      keeping the iron/bronze fittings. Re-emit `board_header.png`; import.
      Test: **V5** — a board capture shows the sign receded/darker while the gilt title stays clearly
      readable (capture-iterated for the balance).

## The placard (TD-059d)

- [x] T193 [R183 / P106 / V5] — **Light the placard through the scene shader.** `gen_header.py` emits
      `board_header_n.png` from an explicit height field (`_hf`: raised straps + domed bolts, top rail,
      routed bottom-rail channel, outer bevel), Sobel → tangent-space normal (flat + transparent at
      the worn rim). `main._board_header` gives the sign `_surface_material(board_header_n.png, ambient
      0.86, …)` (shadow copy stays flat). Import; regenerate asset-map.
      Test: **V5** — a board capture shows the header taking the scene's cool ambient (matching the top
      of the frame), its carved relief defined, the gilt title still legible; a `--lights-off` capture
      is ~unchanged (ambient-dominated — the placard is in the lighting model, not baked-self-lit).

## The torch (TD-059e)

- [x] T194 [R179, R180 / P102 / V3, V4] — **Decouple the torch from the banner.** TD-059b/c walked
      `GUTTER_CX` outboard for banner placement and dragged the sconce/flame/light rig with it, so
      the carved frame read as lit by a disconnected mid-side glow. Split the constant in
      `board_decor.gd`: `GUTTER_CX` = banner placement only; new `TORCH_CX` (inboard, between banner
      and frame) read by the sconce, the flame, AND `torch_rig` — fixture + shader light still share
      one constant (P95 re-homed). TD-059f (author review): `TORCH_CX` 0.072 → **0.045/0.955** —
      centred in the wall gutter (screen edge → frame ≈ 0.09·vp), not leaning on the frame.
      Test: a `--board-preview` capture shows the flame beside the carved frame edge, visibly
      lighting it, banners still symmetric + lit by the same rig; `--lights-off` drops the warmth to
      flat dim cloth.

## Verify

- [x] T192 [R177–R182 / P102–P105 / V6] — **Verification pass.** Regenerate `asset-map.md` + `--check`
      (the new `banner_v1_n.png` producer/consumer edge resolves); confirm V1–V5 green by eyeball on a
      board + a `--lights-off` capture; confirm `git diff --name-only` is only `client/ art/ specs/
      docs/ CLAUDE.md`; server + shared Vitest suites still green (untouched); refresh the board
      preview artifact; append DECISION_LOG TD-059; swap the active spec in CLAUDE.md.
      Verify: **V1–V6** green; diff scoped; suites green.

## Notes

- The banner is a `Sprite2D` in `_stone_bg` (world/viewport layer), so `board_surface.gdshader`'s
  `SCREEN_UV` torch sampling works on it directly — unlike the Control-node surfaces, no Light2D
  question arises. It joins the rig purely as another normal-mapped surface (P72 heritage).
- Keep the relief in the **normal map**, not the diffuse: a dim flat-ish diffuse + a real normal is
  what lets `--lights-off` fall to flat cloth (P103), proving the light is the shader's.
- Header height / `placard_rect` / `TOP_RESERVE_FRAC` are **unchanged** — this is a tone pass on the
  wood only (TD-058 already set the geometry). Composition, notices, bar, torches untouched (R174/R180).
