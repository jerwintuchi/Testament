# Tasks — The Quartermaster, to the Reference (TD-110)

> T# continues global from T406. Art + presentation only; no `src/**`.
> **Partly shipped.** What is done is marked done; what is not is left open rather than implied.

## Shipped

- [x] T407 [R383, P176 / V2] — **The altar cloth, and it is the inspection surface.** Crimson with
      gold crosses, folds at the sides, a fringed hem of loose threads. `Counter.rest_point()` is
      **derived from `Room.cloth_rect()`**, so the chosen instrument cannot land beside the thing it
      is meant to be set down on — the coupling TD-105 needed for the candle and its light. The old
      dark mat is deleted: the cloth *is* the mat.
      **Three failures on the way, all the same family — stretching art that must not stretch:**
      (1) shipped as a **9-slice**, which stretches the CENTRE, and the crosses live there — they
      smeared into gold streaks. Re-authored at **display size and drawn 1:1** (TD-050/TD-055).
      (2) The first fix looked half-size because Godot was still serving the **cached 48×40**
      texture — regenerating a PNG needs a re-import before its new dimensions exist.
      (3) The tone was pillar-box red; the reference's cloth is nearly brown in the folds and only
      the gold lifts it.

- [x] T408 [R384 / V3] — **The record is a filed document.** Cross-ornamented dividers between the
      quote, the body and the warning, and a **QUARTERMASTER RECORD** heading. Every word still from
      `lore.gd`.
      **The divider cannot be a 9-slice, and that is the lesson.** A 9-slice stretches its centre,
      and a centred ornament is *by definition* in the centre — the first attempt smeared the cross
      into a heavy bar across the sheet. It is now a stretching rule with a glyph laid over it: two
      nodes, and correct. `qm_rule.png` is retired rather than left unused.

- [x] T409 [R385] — **The pack is issued equipment.** An **EXPEDITION PACK plaque** in the shelves'
      own crimson-and-gold signage — restoring the object TD-107 removed, because what was redundant
      then was the *words*, not the plaque — and slots **numbered 1–4** with a cross watermark, both
      hidden the moment an instrument lands.

## Open — not started, and not implied

- [ ] T410 [R382 / V1] — **The instruments at reference density.** 8–12 tones each on the same 24px
      canvas: brass collars, glass rims, banding, a foot to stand on. The ban on bright gold stands
      (P177). Aseprite, `.aseprite` source kept.

- [ ] T411 [R383] — **The rest of the bench.** Open ledger with a cross on the page, quill standing
      in the inkwell, wax-sealed envelope, brass balance, stacked books, second candle, and drawers
      with ring pulls in the counter front. **Baked into one composite** (P175) — the room is at
      204/220 nodes and cannot afford one node per prop.

- [ ] T412 [R384] — **The record's wax seal medallion** — laurel ring, cross, ribbon — at the foot
      of the sheet.

- [ ] T413 [R385] — **The pack's trim:** brass corner fittings, buckled straps, hanging crimson
      pennant. Baked into one `qm_packtrim.png`.

- [ ] T414 [R386] — **The room:** hanging lantern on a chain (own node, flickers), pinned parchment
      notes and the crimson wall banner (**baked together**), flagstones along the foot, the
      `SEAL & DEPART` crimson banner-plate with a seal ornament, and the
      **THE COLLEGIUM STANDS WITNESS** line beneath it.

- [ ] T415 [R387 / V4] — **Re-verify at the end.** Budget inside 220 with the baked composites,
      `--board-after-qm` green, no `src/**`.

## Verified so far

`--board-after-qm` green (`keepout live=8 ok=true`); `qm_budget.py` green at **204 / 220** — note the
headroom is thinning, which is exactly why T411–T414 must bake rather than add nodes. No `src/**`.

## Do not re-invent

- **A 9-slice stretches its CENTRE.** Anything with a pattern or a centred ornament there must be
  authored at display size (cloth) or composed from separate nodes (rule). Hit twice in one session.
- **Regenerating a PNG is not enough** — Godot serves the cached texture, at the OLD dimensions,
  until `--import` runs.
- **The reference depicts objects the catalog does not have** (telescope, horned skull, spiked orb).
  `gear.ts` is authoritative: our ten keep their identities and gain density (TD-075's rule).
- **The bottom instruction row with arrows is NOT built** (author instruction).
