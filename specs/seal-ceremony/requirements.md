# Requirements — The seal ceremony (stamped wax, the empty socket, the slow press, CONTRACT SEALED)

> Phase 5, Contract Board polish on the user's playtest review of TD-062 (TD-063). Asks: the press
> animation is **too fast** — slower, heavier; the animation **displaced the caption text** (the
> wax flash was added as a CHILD OF THE HBOX ROW, so layout shoved the seal + caption sideways,
> and the sheet-thump moved everything vertically); the faint ring is **off-centre** (the disc
> sits off-centre in its texture), too opaque, and should be **broken (dashed) lines** with the
> **ghost wax removed entirely**; the stamped seal should read as **convincing pressed wax**
> (edge deformations from stamping pressure) in **crisper pixel art**; and a **souls-like centre
> banner** should mark the stamp.
>
> **User rulings (do not re-litigate):** unsealed = a low-opacity **dashed circle only** (no
> faint wax); the stamped seal has **pressure-deformed edges** and is **more pixelized**; the
> banner reads **"CONTRACT SEALED"** over a subline naming the target, is shown **party-wide**,
> and **replaces** the top toast for stamps (lifting keeps the quiet toast; errors keep the toast).
>
> Client render + generated art only (I1/I2). Numbering continues global: **R202+**, correctness
> **P116+**, tasks **T213+**. Logged **TD-063**. Verified by `--board-preview` captures + author
> playtest (motion).

---

## The wax

**R202** (generator/client): the stamped seal reads as **pressed wax, in pixels**.
- AC: `seal_collegium.png` is re-authored as crisp pixel art (no supersample smoothing): an
  **irregular, pressure-deformed rim** (seeded squeeze-out lobes and per-angle jitter — never a
  perfect circle), a raised outer bulge catching the key light, a flat pressed field, and the
  Collegium device debossed with a hard lit lip; shading in **posterized bands**, not smooth
  gradients; the disc **centred** in its canvas so overlays align.
- AC: oxblood register kept; candlelit, no bloom/gloss (R175 heritage).

**R203** (client): the unsealed state is an **empty socket** — a dashed circle, nothing else.
- AC: `wax_seal.gd` faint state draws **only** a low-opacity **broken (dashed) circle**, centred
  on the control (where the wax will land) — the ghost wax texture is gone; the firm state is the
  full stamped texture, unchanged in placement.

## The press

**R204** (client): the press is **slower and heavier**, and displaces **nothing**.
- AC: the stamp timeline gains a wind-up hover and a longer drop (total ≈0.7–0.9s vs the old
  ≈0.27s), with a deeper squash and a slower settle; the lift slows to match.
- AC: the wax flash is parented to the **seal itself** (never the HBox row) and the **sheet-thump
  is removed** — no caption, prose, or sheet pixel moves during the ceremony; layout is
  byte-identical before/after (the flash renders behind the seal, ignores mouse, and frees
  itself).
- AC: reduced-motion still skips straight to end states (P115 heritage).

## The banner

**R205** (client): a stamped charge raises the **CONTRACT SEALED** banner, party-wide.
- AC: on `CONTRACT_SELECTION { accepted: true }` every client shows a souls-like centre-screen
  banner — a wide dark band with big gilt letter-spaced **"CONTRACT SEALED"** over a smaller
  subline naming the target — fading in, holding, fading out (≈2.2s total); it **replaces** the
  top toast for stamps. `accepted: false` (lift) keeps the existing quiet toast; `LOBBY_ERROR`
  keeps the toast. Reduced-motion shows the banner statically (the information is load-bearing,
  the motion is not).
- AC: the banner is pure display (IGNORE mouse, frees itself, emits nothing) and derives only
  from the broadcast payload (P64 heritage); a debug `--rite-banner` preview flag shows it for
  captures.

## Cross-cutting

**R206** (containment): client render + generated art only.
- AC: no `src/**` change; stamping still sends only the existing intents; diff scope
  `client/ specs/ docs/ CLAUDE.md`; suites untouched-green; asset-map `--check` passes.

---

## Verification (`--board-preview` captures + author playtest)

- **V1 (R202):** a `--sealed` reader capture shows the deformed-rim pixel wax (no perfect circle,
  banded shading, device legible).
- **V2 (R203):** an unsealed reader capture shows only the centred low-opacity dashed circle — no
  ghost wax.
- **V3 (R204):** author playtest — the press reads slow/heavy; the caption and sheet never move.
  (Static check: unsealed/sealed captures show identical caption geometry.)
- **V4 (R205):** a `--rite-banner` capture shows the CONTRACT SEALED banner over the board;
  author playtest confirms it fires party-wide on a stamp and the stamp toast is gone (lift toast
  remains).
- **V5 (R206):** diff scope; suites green; asset-map current.
