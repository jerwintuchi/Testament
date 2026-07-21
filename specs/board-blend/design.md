# Design — Contract Board blend pass (banner relight + header tone)

> Satisfies R177–R182. Client render + generated art only; no server/shared/logic change (I1/I2).
> Logged TD-059. Verified by `--board-preview` captures (client-spec convention).

---

## The shape of the change

Today the banner is a **flat baked Sprite2D**: `banner_v1.png` (180×360, LINEAR), `modulate ≈
(0.90,0.86,0.86)`, centred at `GUTTER_CX` so a `0.15·vp`-wide banner **spills off the screen edge**,
with all fold value + a bright bone emblem **baked into the diffuse** and read "by its own value"
(light-agnostic) — the one board surface that opts out of `board_surface.gdshader`. The brief kills
that arrangement on every axis: too bright, mis-placed, smooth, and unlit.

So the banner **joins the torch-lit surfaces**: a dimmer, flatter, crisp-pixel diffuse + a companion
normal map, lit by the same rig as the stone/frame/backing — warm where the foot sconce reaches,
dark up top. It is re-cut narrower to sit fully in the gutter, NEAREST-filtered, and heavily
tattered. The header wood is pulled down in value so the sign recedes with it. Nothing else on the
board moves (composition, notices, bar, torches, `GUTTER_CX` coupling all preserved).

## R177/R178/R179 — `gen_banner.py` rewrite

The generator is re-authored to emit **two** PNGs (crisp per-pixel, no LANCZOS on the cloth):

### `banner_v1.png` — the diffuse (64×176)

Authored at ~display size (`W,H = 64,176`) so NEAREST shows it near-1:1 (deterministic at 640×360).

- **Silhouette + heavy tatter (R177):** the cloth is full down to `SOLID ≈ 0.80·H`; below that the
  hem is **ragged** — a per-column worn depth from a hash so the bottom is uneven — with a few
  **worn-through holes** (transparent blobs seeded near the foot) and, in the lowest band, sparse
  **loose threads**: 1–2px-wide vertical strands that survive to random depths while the cloth
  between them is gone. Threads + holes are alpha, so the torn cloth reads against the wall.
- **Dim crimson (R178):** a **darker, lower-contrast** crimson ramp than TD-052 (the shader now
  supplies fold warmth, so the diffuse no longer bakes bright fold crests). A **gentle** baked fold
  value + fine weave remains so the unlit cloth isn't a flat rectangle, but the absolute value stays
  **below the parchment/frame key** (dungeon-dark, P103).
- **Subdued emblem (R178):** the Collegium device is imprinted in the upper cloth as before, but the
  bone-dye ramp is pulled **dim + desaturated** and the imprint alpha lowered, so it reads only
  faintly through the weave — a printed device, never a bright sigil. (Still PIL-read from
  `collegium_logo.png`, recolored to a dim bone; the emblem sits in the banner's darker upper region,
  which reinforces the subdued read.)
- **Top hem** (pole sleeve) kept — a darker band + thin lit lip — so it still hangs like a standard.

### `banner_v1_n.png` — the normal map (64×176)

A companion **tangent-space normal** so `board_surface.gdshader` gives the cloth real fold relief
(R179). Derived from the banner's **own height field** `Hf(x,y)` (fold sine + finer creases + hem
bump), not from luminance — one source of truth for the relief, independent of how dim the diffuse
is. Sobel `Hf` → packed normal (the exact convention `gen_normals._normal_pixel` uses: `flat =
(128,128,255)`, `FLIP_G=False`). **Flat (128,128,255) where the cloth is transparent** (outside the
silhouette / holes / between threads) so torn gaps don't rake light. Vertical folds ⇒ the normal
tilts across **x**, so a torch off to the side rakes across the drapes.

Both PNGs go through `A.write_png` (asset-map producer edges hold). The generator still **consumes
`collegium_logo.png`** (PIL) → provenance header (`@produces`, `@consumes`, `@why`), as today.

## R179/R180 — `board_decor.add_torches` + `main._surface_material`

`add_torches` gains a `banner_mat: ShaderMaterial` parameter (built by the caller so the rig-uniform
packing stays in one place — `main._surface_material`). The banner block changes:

- **Lit, not flat (R179):** the banner `Sprite2D` gets `material = banner_mat` (from
  `_surface_material("res://assets/ui/banner_v1_n.png", ambient≈0.36, diffuse_gain≈1.05,
  radius_scale≈2.4)`), filter **NEAREST**, and `modulate = Color(1,1,1)` — brightness now comes from
  the shader (as `_stone_bg` already does), not a baked-dim modulate. The shadow copy is NEAREST too.
  The rig **positions + colours are unchanged** (same `torch_rig`); `_surface_material` grows one
  optional `radius_scale` that widens only THIS surface's per-torch *reach* — the board's tight 0.24
  halo keeps the wall dungeon-dark, but the banner hangs above its foot sconce, so without more reach
  the throw dies before it climbs the cloth and the torch-lit gradient is invisible. At 2.4× the
  sconce's warmth **climbs into the tattered foot** and fades to ambient dark up top — the wanted
  gradient. This is a per-material render choice, not a second light or a new coupling (P102).
- **Clear of the board frame (R180):** the carved board frame's outer edge is at `≈0.09·vp.x` (the
  frame texture extends ~52px proud of the 0.13·vp inner content), so the gutter (screen edge →
  frame) is **narrower than the banner** — the banner cannot sit fully inside it without either
  overlapping the frame or clipping the emblem. So (TD-059b, author review) the whole assembly is
  pushed **outward**: `GUTTER_CX` `0.065 → 0.036` and the banner narrowed `0.10 → 0.078·vp.x`. The
  left banner now spans `≈[-0.003, 0.075]·vp.x` — inner edge (0.075) clears the frame (0.09) with a
  gap, emblem (centred, 0.60·W) fully on-screen, outer edge a few px off-screen (viewport clips,
  OK'd). Moving `GUTTER_CX` moves banner + sconce + flame + the banner's own light + the wall hotspot
  **together** (that is what `GUTTER_CX` couples — P95 preserved, just re-valued to the outer gutter,
  which matches the original "banner at the OUTER edge of the masonry gutter" intent). Height budget
  still caps `bs` above the sconce cup.
- **Torch decoupled (TD-059e, author review):** dragging the torch out with the banner left the
  carved frame lit by a disconnected mid-side glow (~74px off the frame) with the visible flame
  nowhere near it. The constant is split: `GUTTER_CX` (0.028/0.972) is **banner placement only**; a
  new **`TORCH_CX`** is what the sconce, the flame, AND `torch_rig` read — so the flame hangs on
  the wall beside the frame and visibly lights it, while fixture + shader light still share one
  constant (P95's real invariant, re-homed). The banner still catches the same rig's climb
  (radius_scale 2.4). First cut 0.072 leaned against the frame; **TD-059f** (author review) centres
  the fixture in the wall gutter (screen edge → frame ≈ 0.09·vp): `TORCH_CX` **0.072 → 0.045**.

`main.gd` builds `banner_mat` once and passes it: `BoardDecor.add_torches(_stone_bg, vp,
_reduced_motion, _surface_material("res://assets/ui/banner_v1_n.png", …))`.

## R183 — the placard joins the lighting model (TD-059d)

The header sign was the last board object still rendered as a **flat baked `NinePatchRect`** on a
shader-lit wall — hence it read as pasted-on/self-lit. It now takes the same `board_surface.gdshader`
material as every other surface:

- `gen_header.py` emits a companion **`board_header_n.png`** from an explicit **height field** `_hf`
  that mirrors `header_px`'s carved form (raised iron straps + domed bolts, top rail, routed
  bottom-rail channel, outer bevel stepping to the worn rim), Sobel → packed tangent-space normal
  (gen_normals convention; flat + transparent at the worn-rim holes).
- `main._board_header` gives the sign `_surface_material("…board_header_n.png", ambient≈0.86,
  diffuse_gain 1.0, radius_scale 1.6)`. The **shadow copy stays a flat black silhouette** (no shader).
- Because the header is top-centre and the sconces are bottom-corner (~1.0 uv away, unreachable by
  any sane radius), the header sits in the shader's **cool ambient** (`ambient_tint ≈ 0.82,0.85,0.95`)
  — which is exactly the cool-dark the top of the frame beside it already sits in. So "lit by the
  scene" here means *rendered by the same ambient/falloff model as the wall*, not literally warmed by
  a torch. A `--lights-off` capture is ~unchanged (ambient-dominated), which is the honest tell. The
  normal is included for pipeline consistency (it rakes if light ever reaches; the ambient term is
  flat). The **gilt title is a separate Godot Label**, so the wood can go as dim as the blend wants
  without touching legibility (P105/P106).

## R181 — `gen_header.py` tone

The header wood ramp is **darkened** (`WALNUT` + the wood lip/field values pulled down, blended
further toward the near-black board) so the sign recedes — "darker but not so much". The engraved
title is drawn in Godot in gilt (`Color(0.86,0.72,0.42)` / `0.62,0.50,0.31`); a darker wood *raises*
its contrast, so legibility only improves (P105). Iterated by capture for the balance. `board_header.png`
re-emitted; iron straps + bronze bolts keep their (already dim) values.

## Correctness Properties

- **P102 (one rig, R179):** the banner reads `BoardDecor.torch_rig` through `_surface_material`; no
  second light. **TD-059e re-homes the P95 coupling:** `GUTTER_CX` is banner placement only; a new
  `TORCH_CX` (inboard, between banner and frame) is the ONE constant the sconce, flame, and
  `torch_rig` (hence every shader consumer) read — fixture + light still can never desync.
- **P103 (blend / register, R178):** every generated banner pixel sits **below the parchment/frame
  key**; no additive/VFX layer on the cloth; the emblem never out-glows the weave. `--lights-off`
  shows dim flat cloth (proof the brightness is the shader's, not baked).
- **P104 (render-only, R182):** no `src/**` change, no game state; header + banner render static
  asset data and emit nothing.
- **P105 (header legible, R181):** the gilt title on the darkened wood stays clearly readable (the
  darker ground raises contrast).
- **P106 (placard in the lighting model, R183):** the header is rendered by `_surface_material` (the
  one rig, P102 heritage) with a real normal — no baked phantom highlight implying a light the scene
  lacks; render-only, emits nothing.

## Files touched

Edited: `client/assets/ui/gen_banner.py` (rewrite: crisp/dim/tattered diffuse + normal map),
`client/assets/ui/gen_header.py` (darken wood), `client/scripts/ui/board_decor.gd` (`add_torches`
banner: NEAREST + material + gutter fit), `client/scripts/main.gd` (build + pass `banner_mat`),
`docs/technical/asset-map.md` (regenerated — new `banner_v1_n.png` edge),
`docs/DECISION_LOG.md` (TD-059), `CLAUDE.md` (active spec). New: `client/assets/ui/banner_v1_n.png`,
`specs/board-blend/*`. Regenerated: `client/assets/ui/banner_v1.png`, `board_header.png`.
No `src/server` / `src/shared` change.
