# Design — Board Banner, Crest & Placard pass

> Satisfies R165–R170. Client render + generated art only; no server/shared/logic change (I1/I2).
> Logged TD-052. Verified by `--board-preview` captures (client-spec convention).

---

## R165 — Crest sizing (`board_decor.board_crest`)

The only lever is the display `cs` (base pinned at the nameplate, so height sets the crown rise,
aspect fixed 0.60). Reduce `cs` 51×84 → **~40×66** (iterate on capture). Shadow + LINEAR filter
unchanged. No other consumer touched.

## R166/R167 — Banner cloth + bone-dye imprint (`gen_banner.py` rewrite)

Rewrite the generator from a narrow frayed strip into a **proper banner** and bake the emblem in.

**Canvas:** widen the aspect to a heraldic proportion — **`W,H = 180, 360`** (was 74×474). Keeps a
single Sprite2D consumer; `add_torches` scale math is re-derived from the new size (R168).

**Cloth (baked value, dungeon-dark key):**
- Crimson ramp `C_DEEP→C_HI` as today, dim for the near-black board.
- **Vertical fold value:** a few soft sine-driven fold columns (baked light-agnostic value), plus a
  gentle horizontal AO top→bottom.
- **Top hem:** a solid darker hem band (~8px) with a thin lit top edge — the baked "pole sleeve",
  so no separate rod is needed.
- **Bottom = swallowtail:** cut the lower edge into a symmetric **V-notch** (two tails), alpha 0
  outside the cloth silhouette — a defined banner hem, not a torn deckle. A thin darker border traces
  the whole silhouette (selvage).

**Imprint (bone dye, P97):**
- `from PIL import Image`; load `collegium_logo.png` (132×220, the extracted emblem).
- Recolor to **bone**: for each opaque emblem pixel, output `bone_shade = lerp(BONE_DK, BONE_LT, lum)`
  where `lum` is the source pixel luminance (keeps the device's internal relief), alpha = source alpha
  × `IMPRINT_A` (~0.82) so the crimson weave shows through → a printed, dyed look (not a decal).
- Scale the emblem to ~**0.62·W** wide, center it horizontally, seated in the **upper cloth** (above
  the swallowtail notch). Composite over the baked cloth. The result is baked into `banner_v1.png`.
- `BONE_DK ≈ (150,140,120)`, `BONE_LT ≈ (232,224,200)` — off-white, warm, reads on crimson.

Because the imprint is baked, it drapes + dims with the cloth (`modulate`) for free (P97). The
generator now **consumes `collegium_logo.png`** as an input — an edge the asset-map scanner can't see
(it only tracks `write_png` for `.py`), so a **provenance header** records it (`@consumes`, `@why`).

**Filter note:** the emblem is authored at 132×220 and drawn into a ~112px-wide slot (downscale) →
sample with `Image.LANCZOS` for a clean printed edge.

## R168 — Placement + lighting coherence (`board_decor`)

**Shared gutter centre.** Introduce a helper the two functions share, so the light never desyncs
(P95):
```
const GUTTER_CX := [0.065, 0.935]   # true midpoint of each ~13% gutter (inner=0.74 ⇒ flank 0.13)
```
`torch_rig` and `add_torches` both read `GUTTER_CX` for the flank x (replacing the inline 0.06/0.94).
The shift is ~0.005·vp — the wall light barely moves, staying under the banner.

**Widen.** Target on-screen banner width ≈ **`vp.x·0.15`** (fills the ~0.13 gutter and spills a little
past the screen edge, which the viewport clips — the user OK'd overflow). `bs = target_w / W`;
`target_h = bs·H`. Re-check the foot still ends above the sconce cup (`vp.y·0.71`) with a gap; if the
taller cloth reaches the cup, cap `bs` by the height budget (`min(target_w/W, (vp.y*0.60)/H)`).

**Retire the hardware.** Delete the `rod` `Panel` + nail-head `Panel`s (R166). The baked hem is the
mount. Keep the contact shadow (offset down-right — the ONE-light convention) and the sconce/flame/glow
block unchanged except reading `GUTTER_CX`.

## R169 — Refined carved-wood placard

`_notice_placard` renders `board_nameplate.png` (9-slice, from `gen_heraldry.nameplate_px`) + the gilt
line. Re-cut **`nameplate_px`** in `gen_heraldry.py`: deepen the routed recess (stronger inner AO +
bevel), warm the plank value, and firm the gilt inner edge — a cleaner carved sign at the same 9-slice
margins (so `_notice_placard`/`placard_rect` are unchanged). If the plate proportion needs a nudge for
"cleaner", adjust only the generated texture, not the layout. Iterate on capture.

## Correctness Properties

- **P95 (lighting coherence, R168):** `torch_rig` and `add_torches` read ONE `GUTTER_CX`; the sconce,
  flame, glow and shader torch uniforms stay aligned under the banners after repositioning.
- **P96 (render-only, R170):** no `src/**` change, no game state; the scene renders snapshot/asset data
  and emits nothing.
- **P97 (imprint is baked, R167):** the bone device is composited into `banner_v1.png` at generate
  time — one source of truth — so it drapes/dims with the cloth and cannot desync from the banner.

## Files touched

Edited: `client/assets/ui/gen_banner.py` (rewrite: banner + imprint), `client/assets/ui/gen_heraldry.py`
(`nameplate_px` re-cut), `client/scripts/ui/board_decor.gd` (crest size, `GUTTER_CX`, widen, retire
rod/nails), regenerated `banner_v1.png` / `board_nameplate.png` / `collegium_logo.png` (unchanged) and
`docs/technical/asset-map.md`. New: `specs/board-banner/*`, `docs/DECISION_LOG.md` TD-052.
No `src/server` / `src/shared` change.
