# Requirements — Board Heraldry (ornate crest + carved nameplate)

> Phase 5, visual. Replaces the Contract Board's header — the radiant-star medallion
> (`crest_v1.png`) and routed placard (`board_placard.png`) — with a **Blasphemous-idiom
> heraldic header** in the canonical hand-painted raster register (TD-046): a gilded-bronze
> emblem (upright **sword** + encircling **ring** + **laurel wreath** + **filigree
> scrollwork**) crowning a **carved-plank nameplate** with **iron corner brackets** and a
> **two-line gilt title**. Reference-driven (a Prototype-v1-family carved header). Continues
> the dungeon-dark grade (TD-048): the header is baked + tonally matched, an accent on the
> dark, never a bright slab.
>
> **User ruling (2026-07-13):** "the crest and placard should look like this — not exactly,
> but the design itself." So the *design language* is binding (blade-and-laurel crest;
> carved nameplate with iron corner brackets; big title + subtitle), the exact pixels are not.
>
> Numbering continues global: **R147+**, correctness **P82+**, tasks **T163+**. Trust boundary
> unchanged — **client render only** (I1/I2): no server/shared change, no wire message, no
> game state, no board-behaviour change. Canon: hand-painted raster 2D pixel art, in-engine
> lighting a pillar (DECISION_LOG TD-043/TD-046/TD-049).

---

## Crest

**R147** (client): the crest is an **ornate heraldic emblem** — a gilded-bronze **upright
sword**, set against an **encircling ring**, flanked by a **laurel wreath**, crowned with
symmetric **filigree scrollwork** — replacing the radiant-star medallion.
- AC: the emblem reads as **layered ornate metalwork** — the sword (blade + crossguard +
  grip + pommel), the ring behind it, the two laurel branches sweeping up the sides, and the
  top scroll flourishes are each distinguishable — not a flat disc or a single silhouette.
- AC: it is a **generated raster PNG** (`gen_heraldry.py`), lit from the upper-left key, with
  a raised/lit rim on light-facing edges and recessed shadow on the away side, and a mounted
  **cast shadow** so it reads proud of the wood (heritage of `board_crest`).
- AC: **Origin-neutral** — the device is the **Collegium's** (the blade of inquiry + the
  laurel of the scholar), **not** a trait/Origin sigil; it carries none of the
  Belief/Sin/Relic marks (eye / inverted-cross / diamond) (P84).
- AC: tonally matched to the **dungeon-dark** board — dim gilded bronze that catches the eye
  by ornament + a little gilt, not by being a bright shape (heritage TD-048 / R139).

## Nameplate

**R148** (client): the header sign is a **carved-wood nameplate** — a wide weathered plank
with **beveled edges** and **iron corner brackets** (bolted L-fittings at the four corners),
replacing the routed placard.
- AC: a generated raster (`board_nameplate.png`) built **9-slice-safe** so it stretches to
  the title width without smearing the corner brackets (the brackets live in the fixed 9-slice
  corners; the plank field + bevel tile across the edges/centre).
- AC: the four corners each carry an **iron bracket + at least one bolt/rivet head**, lit
  top-left; the plank field carries horizontal wood grain + a lit top bevel and a darker
  **recessed title field** so the gilt letters read against it.
- AC: tonally matched to the board (deep warm wood, dungeon key); baked (no dynamic shader —
  same reach ruling as the crest/placard, TD-048).

## Title

**R149** (client): the nameplate carries a **two-line gilt title** — a large headline over a
smaller letter-spaced subtitle — drawn by Godot over the nameplate.
- AC: line 1 **"THE COLLEGIUM"** in a large gilt serif; line 2 **"CONTRACT BOARD"** in a
  smaller, letter-spaced gilt caps subtitle; both centred, with a dark drop shadow.
- AC: the title is **unlit gilt ink on top** (Controls' text isn't lit), so its legibility is
  independent of the baked nameplate lighting (P85, heritage of the parchment floor T156).
- AC: (design ruling) the wording moves from the old "PETITIONS BEFORE THE COLLEGIUM" to the
  reference's **"THE COLLEGIUM / CONTRACT BOARD"** signage — on-canon (the order + the station
  name); trivially adjustable if the diegetic petition-line is preferred later.

## Layout

**R150** (client): the header is **resized + repositioned** so the taller crest **crowns**
the wider nameplate, as in the reference.
- AC: the nameplate widens (from ~42% to a header-spanning fraction of the board inner width);
  the crest sits **above and overlapping** the nameplate's top-centre (the emblem breaks the
  top edge of the plate), not floating clear of it.
- AC: the header still occupies only the reserved **top band** — it never overlaps or occludes
  the live notices below (the notice keep-out / scatter is unchanged); z-order keeps a
  taken-down writ (reader) above the header.

## Cross-cutting

**R151** (containment, standing I1/I2): nothing here crosses the trust boundary — no
server/shared file changes, no new wire message, no game-state read/write. Board behaviour
(select/deselect/deploy, notice legibility, torch lighting) is untouched.

---

## Verification

No GDScript unit harness (client-spec convention). Each requirement is verified by the
**DebugCapture** pipeline (`--board-preview`) + a headless parse:
- **V1 (R147/P84):** the capture shows the layered blade-and-laurel-and-scroll crest crowning
  the header; a component read confirms sword + ring + wreath + filigree are each present; no
  Origin sigil appears.
- **V2 (R148):** the capture shows the carved nameplate with iron corner brackets + bolts and
  a beveled plank field; the plate stretched to the title width shows no smeared/streaked
  corner (9-slice holds).
- **V3 (R149/P85):** the capture shows "THE COLLEGIUM" over "CONTRACT BOARD" in gilt, centred,
  legible against the recessed field (measured ≥ the contrast floor at the title, unlit).
- **V4 (R150):** the capture shows the crest crowning + overlapping the wider nameplate at
  top-centre; the notices below are un-occluded (the `keepout ok=true` self-check still logs).
- **V5 (R151):** `git diff --name-only` shows client/docs/specs only; `--headless` parses
  clean (no SCRIPT/shader error); server + shared Vitest suites remain green (untouched).
- **V6 (design fidelity):** the capture, placed beside the reference, reads as the same design
  language (ornate blade-and-laurel crest + carved nameplate + big title/subtitle) — the
  binding bar (not pixel-identity).
