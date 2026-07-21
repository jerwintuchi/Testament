# Requirements — The contract read: pips retired, the petitioner's dread, fitted writs, the quill-line scrollbar

> Phase 5, Contract Board polish on the user's playtest review (TD-061). Three asks + one design
> ruling: (1) the **threat pips go** — "knowledge is not a number" applies to the Collegium's own
> paperwork too; (2) long site names ("at Hollowmere Crossing") **overflowed the compact writ**;
> (3) the reader's text should **consume the sheet** (no glyph outside the parchment) with the
> **scrollbar moved outside** the sheet and restyled to the user's ornament reference (thin line,
> dot finials, diamond thumb); (4) writs are **deliberately non-uniform** — "show the variability
> and uniqueness of each contract", with spacing still sophisticatedly handled (no overlap).
>
> **User rulings (do not re-litigate):** pips removed; threat survives only as **prose in the
> petitioner's own voice** (decided for immersion — the fear in the plea, never a meter; high-tier
> contracts need no label because the dread does the work); the ornament scrollbar is
> **interactive**; writ sizes **vary per contract** (content + seed), never uniform.
>
> Client render + generated art only — no server/shared change (I1/I2). Numbering continues
> global: **R190+**, correctness **P110+**, tasks **T201+**. Logged **TD-061**. Verified by
> `--board-preview` captures (client-spec convention).

---

## The threat

**R190** (client): the **threat pips are retired** from every surface.
- AC: the reader carries no "Threat" row, no pips, no tier label anywhere; `threat_pips.gd` is
  deleted (git history is the archive) and its preload removed. The wall already withheld threat.
- AC: `tier` remains wire intel (it gates generation server-side) — it is simply never rendered
  as a scale (Pillar: no knowledge as a number).

**R191** (client): danger reads as the **petitioner's dread** — prose, in their voice.
- AC: `notice.gd` gains `plea(intel)`: one seeded sentence in the requester's register, banded by
  `tier` — APPRENTICE reads routine/unquiet, JOURNEYMAN reads worried, MASTER reads frightened
  (people lost, places forsaken). Deterministic per `contractId` (same contract → same plea).
- AC: the plea joins the reader's prose (with the preamble, before the charge) where the threat
  row used to sit; it is words only — no icons, counts, or scales — and derives only from intel
  (`tier`, requester, site; P64 heritage).

## The writ

**R192** (client): writs are **sized to their content, non-uniform, and never overflow**.
- AC: each live writ's size derives from its own text (target + site wrapped at the writ's width,
  measured, plus corner-furniture headroom) **plus a seeded variation**, so no two writs read as
  stamped-out copies and long site names ("at Hollowmere Crossing") fit entirely inside the
  parchment — nothing clips at or escapes the sheet edge.
- AC: spacing is still solver-guaranteed: every writ stays within its grid cell (the cell is the
  ceiling; content beyond it steps the fonts down one size as a last resort), footprints stay
  disjoint (`keepout ok=true`), and the ≥44px hit-target floor holds.

## The reader

**R193** (client): the reader's text **consumes the sheet**.
- AC: the text block widens/deepens into the parchment (side + vertical insets reduced) while the
  clip boundary keeps every glyph inside the solid sheet (R189 heritage — nothing rides the torn
  edge); the internal scrollbar no longer occupies sheet width.
- AC: at-rest reading opens at the headline as today; wheel scrolling unchanged.

**R194** (client): the scrollbar sits **outside the sheet**, styled as the user's ornament.
- AC: a new render-only control draws the reference's form to the right of the parchment, clear of
  the sheet: a thin vertical line with a **dot finial** at each end and a **diamond thumb** (an
  outlined lozenge with inner chevrons) riding it; in-register colours (aged brass/iron on the dark
  board), no bloom/gloss.
- AC: it is **interactive**: the diamond drags, clicking the line jumps the scroll, and it tracks
  wheel scrolling; it mirrors the reader's `ScrollContainer` state both ways and hides when the
  writ fits without scrolling. Pure display + input forwarding — no game state, emits nothing.

## Cross-cutting

**R195** (containment): client only.
- AC: no `src/**` change; `git diff --name-only` touches only `client/ specs/ docs/ CLAUDE.md`;
  server + shared suites untouched-green; asset-map `--check` passes (pips preload edge gone).

---

## Verification (`--board-preview` captures)

- **V1 (R190):** a `--reader` capture shows no Threat row/pips anywhere; grep shows no
  `threat_pips` reference.
- **V2 (R191):** reader captures across fixtures show the plea sentence varying with tier band and
  seed; same contract → identical plea across reopens.
- **V3 (R192):** a board capture shows visibly varied writ sizes with every target/site fully
  inside its parchment (incl. "at Hollowmere Crossing"); `keepout ok=true`, `hit_ok=true`.
- **V4 (R193/R194):** a `--reader` capture shows the widened text block inside the sheet and the
  ornament scrollbar outside the right edge (line + dots + diamond); `--reader-foot` still clips
  cleanly (R189); the ornament reflects the scrolled position.
- **V5 (R195):** diff scope client/specs/docs/CLAUDE.md only; suites green; asset-map current.
