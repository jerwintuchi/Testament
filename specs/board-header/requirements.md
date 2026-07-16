# Requirements — Contract Board Header redesign (institutional, handcrafted)

> Phase 5, Contract Board header pass. A client render-only redesign on the user's brief: the header
> should read as a **handcrafted institutional object** inside the Collegium HQ — an ancient expedition
> board maintained for generations — not a modern game UI. **Ecclesiastical grimdark** (Blasphemous,
> Darkest Dungeon, Diablo II, Castlevania; medieval church furnishings, illuminated manuscripts, carved
> cathedral woodwork).
>
> **Preserve the overall Contract Board composition + layout** — do NOT redesign the board. Only the
> **header block** (placard, the Collegium **emblem**, and the title text) is reworked; notices, scatter,
> the bottom bar, and the flanking banners keep their composition (the banners already carry the emblem
> imprint from TD-052).
>
> **User rulings (do not re-litigate):** the emblem is an **inset bronze seal** (a forged bronze/brass
> medallion set INTO the carved wood, emblem in raised relief, iron rim) — NOT a floating icon crowning
> the header; text hierarchy is **THE COLLEGIUM** (primary) over **Contract Board** (secondary) — the
> institution outranks the object; engraved, weathered lettering; materials limited to **aged wood /
> bronze / iron / aged brass / parchment**; warm **candlelit** ambience, soft highlights, edge wear, **no
> bloom / no gloss**.
>
> Client render + generated art only (I1/I2): NO server/shared change, no game logic. Numbering continues
> global: **R171+**, correctness **P98+**, tasks **T183+**. Logged **TD-053**. Verified by `--board-preview`
> captures (client-spec convention — no GDScript unit harness).

---

## The placard

**R171** (client/generator): the flat title bar is replaced by a believable **handcrafted placard**.
- AC: the placard reads as **carved oak / aged dark walnut**, **reinforced with forged iron or weathered
  bronze** (corner straps + bolts), slightly **worn from age**, and **physically mounted** onto the board
  (a soft contact shadow so it sits proud of the wood, warm candlelit key from the upper-left).
- AC: it feels **utilitarian and institutional**, not decorative or luxurious — no polished/modern surfaces.

## The emblem — inset bronze seal

**R172** (generator/client): the Collegium emblem is an **embossed inset bronze seal**, part of the board.
- AC: the emblem no longer floats above the header as a cutout icon; it is a **forged bronze/brass
  medallion** — the emblem in **raised relief** on a bronze disc, an **iron rim**, and an outer **socket
  shadow ring** so it reads as physically **set into the wood** (embossed, not pasted). No glow.
- AC: the crowning `_board_crest` overlay is **retired**; the seal lives within the header object.

## Text hierarchy + typography

**R173** (client): the title establishes an institutional hierarchy in **engraved** lettering.
- AC: **THE COLLEGIUM** is the **primary** line (largest, dominant); **Contract Board** is the
  **secondary** line (smaller, subordinate). The institution always outranks the object.
- AC: lettering reads as **engraved / carved cathedral signage** — an incised dark cut + a soft lit
  bevel, slightly **weathered** (not a flat modern label), in aged gilt/bronze on the recessed field.
- AC: **vertical breathing room** separates the seal, the Collegium line, and the subtitle; the seal +
  both lines read as **one cohesive, centered object**.

## Composition preserved

**R174** (client): the redesign is contained to the header.
- AC: the notice **scatter, the bottom bar, and the flanking banners keep their composition** — only the
  header band grows and the top reserve (`TOP_RESERVE_FRAC` / `placard_rect`) is adjusted so notices sit
  below the taller header; the keep-out self-check still passes (all live notices placed, disjoint) (P99).

## Materials + lighting

**R175** (art): materials + light stay in register.
- AC: only **aged wood, bronze, iron, aged brass, parchment** — no polished/modern/glossy surfaces; warm
  candlelit key, soft highlights, subtle edge wear; **no bloom, no glossy reflections** (P100 register).

## Containment

**R176** (standing I1/I2): client render + generated art only.
- AC: no `src/server` / `src/shared` change, no game logic; the header renders static asset data and emits
  nothing. Dependency map regenerated for the new/changed asset edges.

---

## Verification (capture-based, client-spec convention)

No Vitest. Verified via `--board-preview` captures read back + the preview artifact:
- **V1 (R171):** a capture shows the carved-wood placard with iron/bronze reinforcement, worn + mounted
  (contact shadow), institutional not luxurious.
- **V2 (R172):** the emblem reads as an inset bronze seal (disc + iron rim + socket shadow), embossed into
  the board — no floating crest overlay remains.
- **V3 (R173):** THE COLLEGIUM dominates; Contract Board is subordinate; lettering reads engraved +
  weathered; the seal + two lines are one centered object with clear vertical spacing.
- **V4 (R174 / P99):** a board capture shows the notices/bar/banners composition unchanged; the keep-out
  self-check logs all live notices placed + disjoint below the taller header.
- **V5 (R175):** materials/lighting in register (wood/bronze/iron/brass; candlelit; no bloom/gloss).
- **V6 (R176):** `git diff --name-only` touches only `client/ art/ specs/ docs/ CLAUDE.md`; server +
  shared Vitest suites remain green (untouched); `asset-map.md --check` passes.
