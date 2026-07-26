# Requirements — Title screen polish: fog, register, marker, arrival (TD-077)

> The author's brief, after signing off the stripped title screen: parallax smoke to sell the depth,
> a pixelised Cinzel if it stays readable, a larger marker drawn from the Collegium's own heraldry,
> and four scene improvements chosen from a list.
>
> **R263+**, **P132+**, **T281+**.

---

## R263 — Parallax fog sells depth without revealing the plate

- AC: **three** fog banks at different apparent depths — far (thin, high, slow), mid, near (heavy,
  low, fast) — each drifting horizontally at its own speed with a slight vertical breath.
- AC: the parallax is **between the fog layers only**. Nothing ever moves relative to the
  architecture, so R246's standing rule holds: the flat plate is never revealed, because the depth
  cue lives entirely in the smoke.
- AC: each sheet is **wider than the frame** so a drifting edge can never enter it.
- AC: alpha-only greyscale, banded (no dithering), tinted at runtime — the overlay convention.
- AC: F9 reduced motion pins them still, fully visible, losing no information.

## R264 — Cinzel is hard-edged, everywhere (the author's ruling)

- AC: antialiasing **off** and subpixel positioning **disabled** on the Cinzel face, project-wide —
  not scoped to the title screen. One register across the whole game.
- AC (the risk, to be checked not assumed): `fonts.gd` records Cinzel as a deliberate AA exception
  because "its fine serifs shatter at this size". Measured on the title screen at 3×, that does not
  hold — the title is markedly better and 13px options stay readable. **The Contract Board and the
  stations must be re-captured before this lands**, and if their smaller text does degrade, that is
  reported rather than absorbed.

## R265 — The marker is the Collegium's laurel, curving outward

- AC: the selection mark is a **laurel branch** taken from the order's device, one either side of the
  option, **rooted at the bottom inner edge and curving up and away** from the word — the two
  branches of the crest's wreath, meeting at the base and opening outward (the author's sketch:
  `\ word /`).
- AC: **roughly twice** the current mark's size, and legible as leaves rather than as a blob.
- AC: authored at the hall's grain, hard-edged, on the Ash & Ember ramps; `assert_on_palette` passes.
- AC: it keeps its space when unlit, so marking an option never shifts the lettering; exactly one
  option is ever marked; the first option is marked on arrival.

## R266 — The scene gains depth, sparks, light and arrival

*(all four selected by the author)*

- AC: **depth haze** — a warm band at the sanctuary so the nave recedes rather than stopping.
- AC: **altar embers** — sparks rising off the one fire in the frame, which currently throws none.
- AC: **two more god-rays** from the clerestory either side, breathing **out of phase** with the
  existing shaft.
- AC: **arrival** — the device and title settle in over ~0.6s on first show, the options staggering
  after; the sigils **ease** rather than snap; the selected option's letters warm slightly.
- AC: **version string**, bottom-right, small and dim — the space the original brief reserved. It
  reads the project's configured version so it cannot go stale.
- AC: every one of these is skipped or pinned under F9 reduced motion, and the still frame stays
  fully lit.

## R267 — No camera drift (recorded as a decision, not an omission)

- AC: the plate is **not** panned, drifted or zoomed. At 1:1 device pixels any sub-pixel move
  resamples the whole image and an integer-only move visibly jumps. The fog supplies the life
  instead. This is the same finding TD-075 recorded when the drift was first removed.

## R268 (containment) — client render + generated art only

- AC: no `src/**` change, no wire change; asset map and manifest regenerated; `title_assets --check`
  green; suites green.

---

## Correctness Properties

- **P132 (parallax never touches architecture):** no layer that contains architecture moves, ever.
  Only fog, particles, rays and UI animate. This is what keeps a flat plate from being exposed.
- **P133 (marked space is reserved):** the marker occupies its footprint whether lit or not, so
  selection changes nothing about where the lettering sits.
- **P134 (reduced motion loses nothing):** F9 removes movement, never content — every fog bank, ray
  and glow is still present and still lit in the still frame.

## Verification

- **V1 (R263/P132):** capture in motion and under F9; fog reads at three depths, no edge enters frame.
- **V2 (R264):** title screen **and Contract Board** captured before/after at 3×; the board's text is
  judged explicitly, not assumed.
- **V3 (R265/P133):** the laurel reads as leaves at 1:1; lettering does not shift when selection moves.
- **V4 (R266):** captures show haze, embers, three rays, the arrival sequence and the version string.
- **V5 (R268):** `title_assets --selftest`+`--check`, `asset_map`, `spec_status`, suites, scoped diff.
