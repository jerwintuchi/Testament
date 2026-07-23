# Requirements — take-down/return without rebuilding the board (TD-068)

> On the author's playtest: taking a writ down to read, and putting it back, visibly re-renders the
> whole Contract Board. This is the **same defect TD-065 fixed for the seal stamp**, still living on
> the open/close path — TD-065 explicitly left it ("Grid-view updates keep the full rebuild").
>
> Client render only. Behavior-preserving: the board must end up exactly as the rebuild left it
> (I1/I2 hold; no server/shared change). Numbering continues global: **R221+**, correctness
> **P123+**, tasks **T232+**. Logged **TD-068**. Verified by `--board-preview` captures + a build
> counter in the client log.

---

**R221**: taking a writ down / returning it **does not rebuild the board**.
- AC: `_select_board_card` swaps only the `ReaderOverlay`; the canvas, plank backing + its surface
  shader, all live writs (and their `_fit_writ` measuring), the flavor scraps, the decay props, the
  vignette, the legend bar, the placard, and `add_torches`' `CPUParticles2D` are **left untouched**.
- AC: the board is built **exactly once** across an open→close cycle — the client's existing
  `board live=<n>` line appears once for the whole run (it is emitted per `_build_contract_board`).
- AC: a missing/invalid `_board_canvas`, or a non-`CONTRACT_BOARD` popup, still falls back to the
  full `_rebuild_popup_body` — the optimization is an added fast path, never the only path.

**R222**: the round trip is visually indistinguishable from the rebuild it replaces.
- AC: with the reader open, the sheet renders identically to pre-change (pixel-identical outside the
  torch gutters, whose particles are nondeterministic run to run).
- AC: after a close, every writ is back at its **seeded lean and rest scale** — in particular the
  writ that was hover-lifted (1.05) at the moment it was clicked does not stay swollen, because the
  old path discarded that node and this one keeps it.
- AC: closing returns keyboard focus to the wall (`_focus_first_notice`), as the rebuild did.
- AC: the open still fades in and the close still fades out on the same durations (0.12s / 0.07s) —
  but on the **overlay alone**, so the board behind no longer blinks out and back.

**R223** (containment): client render only.
- AC: no `src/**` change; server + shared suites untouched-green; dependency map regenerated.

---

## Verification

- **V1 (R221):** `--board-preview --reader` logs `board live=` **once** (pre-change: twice), and
  `--board-preview --reader-cycle` (open **and** close) logs it **once** for the whole run.
- **V2 (R222):** a `--board-preview --reader` capture diffed against a stashed pre-change build is
  identical inside the sheet (differences confined to the torch gutters); a
  `--board-preview --reader-cycle --capture` shows the wall intact after the return — eight writs at
  their leans, none swollen, focus reticle on the first writ.
- **V3 (R223):** `git diff --name-only` is only `client/ specs/ docs/`; asset-map `--check` passes;
  server + shared suites green.
