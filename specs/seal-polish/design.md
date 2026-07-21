# Design — Seal polish (TD-064)

> Satisfies R207–R210. Client render only. Verified by captures + author playtest.

---

## R207 — the flash on an overlay above the board

The flash was a child of `seal`, which lives inside `ReaderScroll` (`clip_contents = true`), so its
radius was clipped to the sheet. It moves to a **dedicated `CanvasLayer`** (the `_show_rite_banner`
pattern — a top layer renders above the popup, unclipped) positioned at the seal's on-screen centre.

- The game runs `stretch/mode = canvas_items`, so every CanvasLayer with identity transform renders
  in the same logical space (PixelScale sets `content_scale_size`). The seal's centre in that space
  is `seal.get_global_transform_with_canvas() * (seal.size * 0.5)`; the flash size scales by
  `gt.get_scale()` so it is correct on any integer factor.
- `_spawn_seal_flash(seal)` (called from `_animate_seal` on stamp): make a `CanvasLayer` (layer 95,
  above the popup's dim/reader and the rite banner is 90 — the flash sits topmost briefly), add a
  `TextureRect` (`backlight_gradient`, `additive_material`, IGNORE mouse) centred at the computed
  point, and run the SAME bloom tween as today (interval to impact → alpha up + scale out → fade),
  ending in `layer.queue_free`. It is not a child of the seal, so a rebuild that frees the seal
  leaves the bloom to finish and free its own layer (no leak, no orphan).
- The seal's own drop/squash/settle tween is unchanged (the seal stays in the reader). Only the
  flash relocates — the seal, caption, and board pixels are untouched (P116 preserved).

Debug: `--flash-preview` in `_board_preview` opens the reader and spawns one flash for a capture.

## R208 — memoize the board textures

`BoardGeo`'s five deterministic generators gain a static cache (built once, returned thereafter):

```gdscript
static var _wood_grain: ImageTexture
static func wood_grain_texture() -> ImageTexture:
    if _wood_grain == null: _wood_grain = _build_wood_grain()
    return _wood_grain
```

Same for `vignette_gradient`, `curl_gradient`, `backlight_gradient`, and `additive_material`
(the material is shared read-only across every additive sprite — it already carried no per-node
state). The bodies move verbatim into `_build_*` privates. The textures/material are immutable and
reused by reference; nothing that mutates them exists, so sharing is safe. This removes the
per-rebuild regeneration — chiefly the 9 216-iteration `wood_grain` loop — that caused the hitch.

## R209 — the stamp cooldown

A process-time lockout on the stamp affordance:

- `const SEAL_COOLDOWN_MS := 900` (≈ the 0.82 s press, so a stamp can't be interrupted or spammed).
- `var _seal_cooldown_until := 0` (msec, `Time.get_ticks_msec()`).
- On stamp/lift press: `_seal_cooldown_until = Time.get_ticks_msec() + SEAL_COOLDOWN_MS` (plus the
  existing immediate `stamp.disabled = true` + send).
- In `_seal_block`: `var cooling := Time.get_ticks_msec() < _seal_cooldown_until;
  stamp.disabled = (not leader) or cooling`. When the block is rebuilt during the window (the
  snapshot lands fast), it stays disabled and schedules its own re-enable:
  `get_tree().create_timer(remaining).timeout.connect(re_enable)` (guarded by `is_instance_valid`).
- Affordance only (P119): the server still authorises; a raced `NOT_*`/`WRONG_PHASE` surfaces as
  today. Non-leaders unaffected.

## Correctness Properties

- **P118 (cache is render-only, R208):** the memoized textures/material are immutable, identical to
  the freshly-built ones, hold no game state, and are shared by reference; visuals are unchanged.
- **P119 (lockout ≠ authority, R209):** the cooldown only disables a local control; it never
  authorises and never replaces the server gate — a raced rejection still surfaces (P66 heritage).

## Files touched

Edited: `client/scripts/ui/board_geometry.gd` (memoize 5 generators),
`client/scripts/main.gd` (flash overlay; stamp cooldown; `--flash-preview`),
`docs/DECISION_LOG.md` (TD-064), `CLAUDE.md` (active spec). New: `specs/seal-polish/*`.
No `src/**` change.
