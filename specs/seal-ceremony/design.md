# Design — The seal ceremony (TD-063)

> Satisfies R202–R206. Client render + generated art only. Verified by captures + author playtest.

---

## R202 — pressed wax, in pixels (`gen_emblems.make_collegium_seal` rewrite)

The TD-060 seal was painterly (SS=3 smoothing, perfect circle, smooth lambert) — it read as a
sticker. The rewrite makes it a **stamped object in pixel art**:

- **SS=1** (hard pixel edges, no supersample blur), 48×48, disc centred (`cx=cy=23.5`).
- **Deformed rim:** `R(θ) = 16.5 + Σ lobes + jitter` — 3 seeded gaussian squeeze-out lobes
  (amp ~1.6–2.6px, where pressure pushed wax out) + per-angle-bucket hash jitter (±0.7px) + a
  slight pressed-ellipse bias. Never a perfect circle.
- **Stamped structure:** an outer **bulge band** (`0.80R..R`) of displaced wax — lit top-left,
  shadowed bottom-right (the raised ring a matrix leaves); inside it the **pressed field**, a
  half-tone darker (flattened wax); the **device debossed** into the field (recess to deep, a
  1px lit lip on the lower-right walls).
- **Posterized shading:** the dome/lambert value is quantized to 4 bands (hi / base / deep / rim)
  before colour lookup — banded pixel-art shading, not gradients; grain speckle quantized too.
- **Shadow:** a hard 2px-offset contact shadow (alpha-stepped, not gaussian).

Emblem mask read unchanged (PIL, thresholded alpha). Same oxblood `COLLEGIUM_WAX`.

## R203 — the empty socket (`wax_seal.gd`)

The faint state stops drawing the texture entirely. It draws a **dashed circle**: 12 arcs of ~16°
with ~14° gaps, radius `s*0.5 - 2`, centred at `size*0.5`, in `RIM` at **alpha ≈ 0.30**, width
1.5 — a quiet socket marking where the wax will land. (This also retires the off-centre-ring
problem: there is no wax to disagree with, and the new texture centres its disc anyway.) The firm
state draws the texture in the centred square as before. `set_faint` API unchanged.

`_seal_block` alpha bookkeeping simplifies: the dash carries its own opacity, so the control's
modulate stays 1.0 for every role (leader/non-leader differ only by the affordance, as before).

## R204 — the slow heavy press, displacing nothing

Two displacement bugs die:
- the **flash** becomes a child of the **seal** (`show_behind_parent = true`, centred in the
  seal's local space) — the old code childed it to the HBox row, which laid it out as a box item
  and shoved the seal + caption sideways;
- the **sheet-thump tween is removed** — weight is expressed in the timeline, not by moving the
  prose under the reader's eyes.

New stamp timeline (`_animate_seal`, total ≈0.82s):

| phase   | t      | motion |
|---------|--------|--------|
| hover   | 0.10s  | wax fades in at scale 2.2, alpha 0→0.85 (held above the sheet) |
| drop    | 0.30s  | scale 2.2→1.0, alpha→1.0, `TRANS_CUBIC EASE_IN` (accelerating fall) |
| impact  | 0.09s  | squash to (1.22, 0.80); the flash blooms **here** |
| settle  | 0.28s  | `TRANS_BACK EASE_OUT` recover to 1.0 (heavy wobble) |

Flash: interval 0.40s (hover+drop), then alpha 0.85 in 0.04s, scale 0.6→1.9 over 0.42s, fade
0.30s, free. Lift slows to 0.28s (rise + fade), then snaps to the dashed socket. Reduced-motion:
end states only (unchanged).

## R205 — CONTRACT SEALED (the rite banner)

New `_show_rite_banner(title, sub)` in `main.gd` (render-only): a full-width `Control`
(MOUSE_IGNORE, high z, added to the popup layer) centred vertically at ~0.38·vp; a horizontal
**dark band** (GradientTexture2D: transparent → near-black 0.82 → transparent) behind a centred
`VBox`: **CONTRACT SEALED** in gilt Cinzel (~28px, letter-spaced via the FontVariation) over the
target subline (~13px, parchment tone). Timeline: fade in 0.30s (title drifts scale 1.05→1.0),
hold 1.30s, fade 0.60s, `queue_free`. Reduced-motion: visible immediately, timer 1.8s, free — no
tweens.

Ingest change (`CONTRACT_SELECTION`): `accepted: true` → `_show_rite_banner("CONTRACT SEALED",
targetName)` (party-wide — the message is already broadcast to the room) and **no toast**;
`accepted: false` → the existing "lifted the seal" toast, unchanged. Errors untouched.

Debug: `--rite-banner` in `_board_preview` raises the banner once for captures.

## Correctness Properties

- **P116 (ceremony displaces nothing, R204):** no node outside the seal's own subtree changes
  position/size during the press or lift — the flash lives under the seal, and no sheet tween
  exists; captions render at identical geometry in both end states.
- **P117 (banner is broadcast-driven display, R205):** the banner renders only
  `CONTRACT_SELECTION` payload fields, fires for every room member from the same broadcast,
  ignores input, frees itself, and emits nothing; the stamp toast is removed, the lift/error
  toasts unchanged.

## Files touched

Edited: `client/assets/ui/gen_emblems.py` (pixel-wax rewrite), `client/scripts/ui/wax_seal.gd`
(dashed socket), `client/scripts/main.gd` (animation rework; banner; ingest; `--rite-banner`),
`docs/DECISION_LOG.md` (TD-063), `CLAUDE.md` (active spec). Regenerated: `seal_collegium.png`.
New: `specs/seal-ceremony/*`. No `src/**` change.
