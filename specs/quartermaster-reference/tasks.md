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

- [~] T410 [R382 / V1] — **The instruments: PARTLY there, and the halves are worth naming.**
      **Done — the palette half.** Each material's triple was three neighbouring greys; it now spans
      a real range, and glass, brass and iron take a **specular**: the one pixel where a curved
      material catches the room, placed where the lit face meets the top-left corner. Wood, bone and
      wax stay matte on purpose — a highlight on everything is what makes a sheet read as plastic.
      Mean tones **5.5 → 6.2**, contrast up on all ten uniformly. **Brass's bright stop returns here
      and ONLY here:** P177 bans gold as a *field* on an ordinary instrument; a single lit pixel is
      not a field, it is how metal reads. Field audit still **0 gold pixels** on all ten.
      **Not done — the drawing half.** Reference density (8–12 tones) needs each glyph to carry
      MORE MATERIALS, not just more shades of the ones it has: a brass collar on the lens, a foot
      under the prism, banding on the censer, a stand for the bead. That is per-icon hand editing of
      ten 24-row maps.
      **Stopped deliberately rather than done halfway:** a sheet where three instruments are detailed
      and seven are not reads worse than ten that are uniformly simple, because the eye reads the
      inconsistency before it reads either. The palette work applies to all ten at once; the drawing
      work cannot, so it is a whole task or none.
      The derived contact shadows were regenerated from the new sheet — they are read from the icons,
      so they cannot go stale silently (P173).

- [ ] T411 [R383] — **The rest of the bench.** Open ledger with a cross on the page, quill standing
      in the inkwell, wax-sealed envelope, brass balance, stacked books, second candle, and drawers
      with ring pulls in the counter front. **Baked into one composite** (P175) — the room is at
      204/220 nodes and cannot afford one node per prop.

- [ ] T412 [R384] — **The record's wax seal medallion** — laurel ring, cross, ribbon — at the foot
      of the sheet.

- [ ] T413 [R385] — **The pack's trim:** brass corner fittings, buckled straps, hanging crimson
      pennant. Baked into one `qm_packtrim.png`.

- [x] T414 [R386] — **The room is furnished.** A hanging lantern on a chain (its own node, because
      it flickers), the crimson banner in the corner, pinned parchment notes, flagstones along the
      foot, the `SEAL & DEPART` crimson plate with the order's disc at its left hand, and
      **THE COLLEGIUM STANDS WITNESS** beneath it. **+4 nodes** (204 → 208): everything static is one
      sprite apiece and the notes are a single baked composite, which is the whole reason the budget
      still holds.
      **The composition had to make room for it.** There was no gutter between the shelves and the
      record column, so `LEFT_W` narrows 0.575 → 0.530 and the header shifts right of the banner —
      the reference gives the banner that corner, and the title cannot share it.
      **The lantern was rebuilt once:** the first pass gated the cage on `edge < 6` inside a 20px
      sprite, so only a narrow strip of it ever drew and it read as two vertical bars. Rebuilt from
      explicit bands — crown, uprights, pane, flame, base — which is legible to read and to fix.
      **The rite plate is a 9-slice whose centre is a UNIFORM FIELD**, which is the only shape a
      9-slice may safely take. Ready wears crimson-and-gold; not-ready is the same plate held back to
      a dim `modulate` — one object in two states, rather than two different-looking controls.
      Adjusted after the first capture: the bar sat low enough that the motto ran into the frame edge
      and the flagstones, so the bar lifted and the floor's band narrowed.

- [ ] T415 [R387 / V4] — **Re-verify at the end.** Budget inside 220 with the baked composites,
      `--board-after-qm` green, no `src/**`.

## Verified so far

`--board-after-qm` green (`keepout live=8 ok=true`); `qm_budget.py` green at **208 / 220**. The
headroom is thinning, which is exactly why T411–T413 must bake rather than add nodes. No `src/**`.

## Do not re-invent

- **A 9-slice stretches its CENTRE.** Anything with a pattern or a centred ornament there must be
  authored at display size (cloth) or composed from separate nodes (rule). Hit twice in one session.
- **Regenerating a PNG is not enough** — Godot serves the cached texture, at the OLD dimensions,
  until `--import` runs.
- **The reference depicts objects the catalog does not have** (telescope, horned skull, spiked orb).
  `gear.ts` is authoritative: our ten keep their identities and gain density (TD-075's rule).
- **The bottom instruction row with arrows is NOT built** (author instruction).
