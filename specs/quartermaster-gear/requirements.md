# Requirements — The Gears, Hand-Shaded (TD-111)

> **R388+**, **T416+**. Author brief, 2026-08-10: the instruments must read as equipment from a
> Castlevania/Terraria inventory, not as flat pixel art.
> **Art only.** No data, no interaction, no `src/**`.

---

## The diagnosis, measured rather than guessed

**The reference image cannot be matched, and the arithmetic says so.**
`art/src/reference/quartermaster_reference.png` is a **1536×1024 painted render**, not pixel art: a
run-length scan finds **23,109 one-pixel runs against 1,042 two-pixel runs**, so nothing in it is
scaled. One lens in it occupies **70×70 px and 1,862 distinct colours**; the entire ten-icon sheet is
240×24 = 5,760 px with ~30 colours. *TD-110 measured those objects at ~21px and concluded 24px was
right. That was wrong, and it is why several passes diverged.*

**What actually held the art back was the METHOD, not the resolution.** Glyphs declared a MATERIAL
per pixel and a neighbour rule inferred the shade — "lit if nothing sits above-left". That can only
produce a bevel. Item sprites in the named games look as they do because an artist **places every
tone**: the highlight, the terminator, the core shadow, and the reflected light that keeps a shadow
side from reading as a hole.

**An image-generation MCP was considered and rejected on FITNESS, not canon.** AI generators emit
pixel-art-*looking* images at high resolution — soft edges, thousands of colours, non-integer pixels
— which is precisely what the reference is and precisely what cannot drop into a 24px slot on a fixed
palette. Aseprite, already installed and already driven from WSL (TD-057), is the right tool; the
change needed was in how it is used.

---

## R388 — Every tone is placed, none inferred

- AC: glyphs use **absolute tone letters** (brass 1–5, glass 6–9, wood q/w/e, iron a/s/d, bone z/x/c,
  ember v/V), and a glyph using them **skips the neighbour pass entirely**.
- AC: each instrument carries deliberate light modelling — highlight, terminator, core shadow, and
  reflected light on the shadow side.
- AC: **12–16 tones** per instrument. The hand-shaded lens measures **13**; the algorithmic sheet
  averaged 10 and could not exceed it, because a bevel has nowhere to put reflected light.
- AC: hand-placed in Aseprite; `.aseprite` and `.lua` sources kept in `art/src/`.

## R389 — The sheet ships whole or not at all

- AC: the live `gear_icons.png` is **not replaced until all ten are hand-shaded**. One detailed
  instrument beside nine bevelled ones reads worse than ten consistent ones — TD-110's finding, and
  the reason this spec is a single unit of work.
- AC: the derived contact shadows are regenerated from the finished sheet (P173).

## R390 — Gold is re-scoped, not re-broken

- AC: `#D6AE5C` (brightest gold) becomes **specular only** — a few pixels at a light's reflection.
- AC: `#B08A3E` becomes a legitimate **brass mid-tone**: a brass-ringed lens is partly *made* of
  brass, and rendering it honestly needs that stop.
- AC: `qm_budget.py`'s gold check is rewritten to that intent, selftest re-pinned. The rule being
  protected is TD-102's — **no instrument may read as the goldest object on screen**, which is what
  made `cantors-ear` look like a UI arrow.

## R391 (containment)

- AC: no `src/**`, no interaction change, no shared surface. The state machine, carry, packing,
  removal and seal rite are untouched — only the sprites change.

---

## Verification

- **V1 (R388):** tone audit — every instrument 12–16 tones.
- **V2 (R389):** the shipped sheet has ten hand-shaded glyphs and zero algorithmic ones; shadows
  regenerated from it.
- **V3 (R390):** `qm_budget.py` green with the re-scoped gold rule, each check proven to bite.
- **V4 (R391):** `--board-after-qm` green, budget within 220, `git diff` touches no `src/**`.

## Status

- [x] **T416 — the method, proven on one icon.** Tone system built; Ashen Lens hand-shaded at 13
      tones. The live sheet is deliberately untouched (R389).
- [x] **T417 — the remaining nine**, same treatment: Chirurgeon's Glass, Witness Prism, Tracker's
      Fetish, Cantor's Ear, Augur's Bead, Censer of Embers, Phial of Hoarfrost, Consecrated Salt,
      Lantern of the Creed.
- [x] **T418 — ship the sheet**: install, regenerate shadows, re-scope the gold rule, verify.

## Not part of this spec

**Resolution.** The hand-shading method works at the current 24px, proven. If the Quartermaster later
moves to a larger logical size, note that **1280×720 cannot be used**: at a 1920×1080 window it scales
**×1.5**, which is non-integer and destroys pixel alignment. The clean options are **960×540 (×2)** or
640×360 (×3). Separate decision, separate spec.
