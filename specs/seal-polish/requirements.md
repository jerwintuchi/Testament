# Requirements — Seal polish (unclipped flash, hitch-free rebuild, stamp cooldown)

> Phase 5, Contract Board polish on the user's playtest review of TD-063 (TD-064). Three asks: (1)
> the wax flash is **clipped by the contract sheet** — it lives inside the reader's ScrollContainer
> (`clip_contents`), so its radius is trapped and it reads as an awkward glow pinned to the writ's
> lower-left; it should render **above the board, unclipped**; (2) a **brief stutter** when the seal
> stamps/lifts — the whole popup rebuilds and regenerates its board textures synchronously as the
> animation begins; (3) a **cooldown window** so stamping/lifting can't be **spam-clicked**.
>
> **User rulings:** the flash must sit **higher than the contract board** and show its full radius
> **without breaking the existing visuals**; the press already looks good (leave its timing); add an
> **interaction lockout** after a stamp/lift.
>
> Client render only (I1/I2) — no server/shared change; stamping still sends the same intents (P66).
> Numbering continues global: **R207+**, correctness **P118+**, tasks **T218+**. Logged **TD-064**.
> Verified by `--board-preview` captures + author playtest.

---

## The flash

**R207** (client): the wax flash renders **above the board and unclipped**.
- AC: the impact flash is drawn on a dedicated **overlay above the popup** (not inside the reader's
  clipped ScrollContainer), centred on the seal's on-screen position, so its full radius is visible
  and never cut off at the sheet edge.
- AC: it tracks the seal's screen position (integer-scale/logical-space correct via the canvas
  transform), frees itself when the bloom ends, and survives a snapshot rebuild that frees the seal
  (independent lifecycle) without leaking a layer. It stays additive/warm — no change to the seal,
  the caption, or any board pixel (the existing visuals are untouched, R204/P116 heritage).

## The rebuild

**R208** (client): stamping/lifting the seal does **not hitch**.
- AC: the deterministic board textures regenerated on every popup rebuild —
  `wood_grain_texture` (a 96×96 GDScript pixel loop), `vignette_gradient`, `curl_gradient`,
  `backlight_gradient`, `additive_material` — are **memoized** in `BoardGeo` so a rebuild reuses
  them instead of rebuilding them; the seal stamp/lift rebuild is visibly smooth.
- AC: the cached textures are identical to the freshly-built ones (same visual result); the cache
  is process-lifetime (they never change), render-only, and holds no game state (P118).

## The cooldown

**R209** (client): the stamp/lift affordance has an **interaction lockout**.
- AC: after a stamp or lift, the seal button is **disabled for a short window** (≈ the press
  length, so the ceremony can't be interrupted or spam-fired); a rebuild landing during the window
  keeps it disabled and it re-enables itself when the window elapses.
- AC: the lockout is **local affordance only** (P66/P119): it never substitutes for the server
  check — a raced `NOT_LEADER`/`WRONG_PHASE` etc. still surfaces; non-leaders are unaffected (their
  seal was already read-only).

## Cross-cutting

**R210** (containment): client render only.
- AC: no `src/**` change; diff scope `client/ specs/ docs/ CLAUDE.md`; suites untouched-green;
  asset-map `--check` passes.

---

## Verification (`--board-preview` captures + author playtest)

- **V1 (R207):** author playtest — the stamp flash blooms at full radius over the board, not cut at
  the sheet edge. (Static: a `--flash-preview` capture holds the flash mid-bloom, visibly extending
  past the sheet.)
- **V2 (R208):** author playtest — stamping/lifting is smooth, no hitch; a `board live=…` rebuild
  log shows no regeneration cost spike (eyeball). Captures of the board are visually identical to
  pre-change (textures unchanged).
- **V3 (R209):** author playtest — rapid clicking the seal fires at most one action per window; the
  button re-enables after ~the press length.
- **V4 (R210):** diff scope; suites green; asset-map current.
