# Design — Contract Board Header redesign (institutional, handcrafted)

> Satisfies R171–R176. Client render + generated art only; no server/shared/logic change (I1/I2).
> Logged TD-053. Verified by `--board-preview` captures (client-spec convention).

---

## The shape of the change

Today the header is **two disjoint objects**: a `NinePatchRect` of `board_nameplate.png` with one gilt
label (`main.gd::_notice_placard`), and a **separate crest overlay** (`_board_crest`) that floats above
it — parented to the popup centre at `z_index = 7` and chased every frame in `_process` so it tracks the
placard's global rect. The brief kills that arrangement: the emblem must be *part of* the object, not
hovering over it.

So the header becomes **one cohesive object**: a taller carved plaque whose upper field holds an **inset
bronze seal**, with the two title lines stacked beneath it. The overlay + its `_process` chase are
retired (R172), which also removes a per-frame cost and the clip-escape hack that justified it.

Everything below the header — the notice scatter, the bottom bar, the flanking banners — is untouched
(R174). Only the header band's *height budget* grows.

## R171/R172 — New generator `gen_header.py`

A new generator (not an edit of `gen_heraldry.py`, whose `nameplate_px` is the TD-052 placard we are
superseding — see "Retired art" below). Two outputs:

### `board_header.png` — the carved plaque (9-slice)

`HW, HH = 144, 96`; margins `HMX, HMY_T, HMY_B = 26, 30, 18` — the top margin is deep so the **iron
corner straps** and the seal's socket live in the fixed corners and never smear when the centre stretches
to width.

- **Timber:** aged dark walnut over oak — `A.RAMP["wood"]` ramp keyed warm, with a vertical grain
  (`A.noise` streaked along x, low amplitude) and a few darker **age bands**. Utilitarian, not polished:
  value range stays narrow and dim (this sits on a near-black board, TD-048 key).
- **Routed field:** a recessed inner panel (the double-bevel + groove idiom proven in
  `gen_heraldry.nameplate_px` — carry it over rather than re-derive): a dark cut channel ringing a field
  darkened ~0.36 toward `wood[0]`, lit lip along the top edge, occlusion along the bottom.
- **Iron reinforcement:** forged **corner straps** — L-shaped iron plates (cool-shifted dark grey, hammered
  via low-frequency noise) inset from each corner, each carrying two **bronze bolt** heads (a small warm
  disc, lit upper-left, with a hard down-right AO crescent). No chamfered/mirrored "modern" edges.
- **Wear:** the outer silhouette edge is eroded — a per-pixel noise threshold nibbles ~1px of the rim and
  lightens exposed grain along the top edge (centuries of hands). Corners lose a little more.
- **Mounting:** the plaque's contact shadow is drawn **in Godot** (a black `NinePatchRect` copy offset
  down-right at low alpha), not baked, so it reads at any stretched width.

### `board_seal.png` — the inset bronze medallion

`SW = SH = 72`, drawn as a **socket + disc** so it reads inset wherever it's placed (no need to bake it
into the stretched centre of the 9-slice — that would smear):

1. **Socket ring** (outermost): a dark AO annulus fading to transparent, so the seal appears to sit *in* a
   hole routed through the wood. This is what sells "embossed into the board" (R172).
2. **Iron rim**: a forged ring, dark and cool, lit upper-left / occluded lower-right.
3. **Bronze disc**: aged bronze/brass field — warm, matte, with verdigris-ward patina mottle (noise) and a
   subtle radial value falloff. **No specular hotspot** (no gloss, R175).
4. **Emblem in raised relief**: read `collegium_logo.png` (PIL, as `gen_banner.py` does), and instead of a
   flat recolor, emboss it — the emblem's **alpha mask** is the relief; a lit **upper-left edge**
   (`BRONZE_LT`) and an **occluded lower-right edge** (`BRONZE_DK`) are derived by sampling the mask
   offset by ∓1px, with the mask's interior filled at `BRONZE_MID` warmed by source luminance. The result
   is a struck medal: the device catches the candle on one side and shadows on the other, with **no glow**.

`BRONZE_DK ≈ (58,40,22)`, `BRONZE_MID ≈ (126,88,44)`, `BRONZE_LT ≈ (196,150,80)`, `IRON ≈ (52,50,50)`.

Both PNGs go through `A.write_png` so the asset-map scanner sees the producer edges; the generator
**consumes `collegium_logo.png`**, an edge the scanner cannot see → **provenance header**
(`@produces`, `@consumes`, `@why`), same convention as `gen_banner.py`.

## R173 — Engraved hierarchy in Godot

`_notice_placard(title)` is replaced by **`_board_header()`** (no argument — the strings are the
institution's, not a caller's):

```
 ┌──────────────────────────────────────────┐  ← iron straps + bronze bolts (baked)
 │              ( bronze seal )             │  ← inset, centered, top of the routed field
 │             THE  COLLEGIUM               │  ← primary: size 20, letter-spaced, aged gilt
 │              Contract Board              │  ← secondary: size 12, dimmer bronze
 └──────────────────────────────────────────┘
```

- **Layout:** a `VBoxContainer` inside the routed field's inset, so the seal + both lines are one centered
  stack (R173 AC "one cohesive object"). Vertical rhythm: seal, `+10px`, primary, `+4px`, secondary. The
  seal is a plain `TextureRect` (LINEAR, 44×44 displayed from the 72px master — the medallion is soft
  baked relief, not pixel art, so the TD-050 NEAREST-1:1 rule does not apply; same reasoning as the crest).
- **Engraved lettering** (R173): each line is a **stacked pair** of `_card_label`s in the same rect —
  a dark **incised cut** (`Color(0.06,0.03,0.01,0.9)`) offset `(0,-1)` beneath a **lit face** offset
  `(0,+1)`; the face carries a soft down-right font shadow. That reads as a cut into the plank rather than
  ink laid on it. Primary face is aged gilt `Color(0.86,0.72,0.42)`; secondary is dimmer, cooler bronze
  `Color(0.62,0.50,0.30)` at size 12 — subordinate, so the institution outranks the object.
- **Weathering:** the primary line gets a slight `letter_spacing` and both lines sit at ~0.94 alpha, so the
  gilt reads worn rather than freshly leafed. (Per-glyph jitter is out of scope — a Godot `Label` cannot do
  it without an authored font atlas.)

## R174 — Composition preserved

The only layout levers move, and both live in `board_geometry.gd`:

- `placard_rect(inner)`: height `inner.y * 0.098` → **`inner.y * 0.165`** (the plaque must hold a seal +
  two lines), width `inner.x * 0.56` → **`0.50`** clamped ≥ 300 (a squarer, more object-like plate; a
  full-width band reads as a UI bar).
- `TOP_RESERVE_FRAC`: **0.205 → ~0.27** so `live_bounds` (already derived from `placard_rect.end.y + 8`)
  keeps the scatter clear of the taller header.

Both are capture-iterated. The keep-out self-check (`keepout live=N ok=<bool>`) must still log `ok=true`
with every live notice placed (P99) — that is the guard that the scatter survived the reserve growth.

Nothing else in `main.gd`'s board build changes; `add_torches`, `GUTTER_CX`, the banners and the bottom
bar are untouched.

## Retired

- **`_board_crest`** (`main.gd:82` decl, `:254` build, `:683-689` `_process` chase) and
  **`BoardDecor.board_crest()`** — the seal supersedes the floating crest (R172).
- **`gen_heraldry.py`** loses `crest_px`/`crest_v1.png` (already dead art — the asset map flags it, and
  `gen_emblems.py` writes the same path: the latent double-producer conflict TD-051 surfaced) and
  `nameplate_px`/`board_nameplate.png` (superseded by `board_header.png`). If the file empties out, it goes
  with them.

## Correctness Properties

- **P98 (seal is part of the object, R172):** the emblem renders inside the header's own subtree — no
  overlay, no `z_index` escape, no `_process` position chase. Moving the header moves the seal for free.
- **P99 (scatter survives, R174):** after the header grows, the keep-out solver still places every live
  notice disjointly below it (`keepout ok=true`, `hit_ok=true`) — the growth is a reserve change, not a
  scatter change.
- **P100 (register, R175):** every generated pixel is on the wood/iron/bronze/brass ramp; no additive/VFX
  layer, no specular hotspot, no bloom (the seal is lit by baked relief only).
- **P101 (render-only, R176):** no `src/**` change, no game state; the header renders static asset data and
  emits nothing.

## Files touched

New: `client/assets/ui/gen_header.py`, `client/assets/ui/board_header.png`, `client/assets/ui/board_seal.png`,
`specs/board-header/*`. Edited: `client/scripts/main.gd` (`_board_header`, retire `_board_crest`),
`client/scripts/ui/board_decor.gd` (retire `board_crest`), `client/scripts/ui/board_geometry.gd`
(`placard_rect`, `TOP_RESERVE_FRAC`), `client/assets/ui/gen_heraldry.py` (retire crest + nameplate),
`docs/technical/asset-map.md` (regenerated), `docs/DECISION_LOG.md` (TD-053), `CLAUDE.md` (active spec).
Deleted: `client/assets/ui/board_nameplate.png`, `client/assets/ui/crest_v1.png` (+ `.import`).
No `src/server` / `src/shared` change.
