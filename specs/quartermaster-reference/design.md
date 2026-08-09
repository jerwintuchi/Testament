# Design — The Quartermaster, to the Reference (TD-110)

> Satisfies R382–R387. Properties P175–P177. Art + placement only.

---

## The baking rule (P175), and why it is not laziness

The reference adds roughly forty objects. At one node each the room goes 189 → ~229, past its 220
ceiling, on the heaviest screen in the game. So:

| kind | example | how it ships |
|---|---|---|
| **never moves** | ledger, envelope, books, pinned notes, banner, drawers | **baked** into a composite PNG, one node per composite |
| **moves** | candles, hanging lantern, dust | its own node, as now |
| **reacts to state** | instruments, pack slots, plaques | its own node, as now |

A composite is authored as one image at the size it is drawn, so it costs one `TextureRect`. The
cost of baking is that a baked prop cannot be moved without regenerating — which is the correct
trade for scenery that is, by definition, never moved.

New composites: `qm_deskset.png` (the bench's working set), `qm_wallset.png` (notes + banner).

---

## The cloth is the inspection surface (P176)

`Counter.rest_point()` currently returns a point computed from the counter rect. It will be derived
from **the cloth's rect** instead, and `room.gd` will place the cloth from the same constants — so
the instrument cannot land beside the thing it is meant to be set down on. Same coupling as the
candle and its light (TD-105): when two things must occupy one place, one is computed from the other.

`qm_cloth.png` is a 9-slice: gold-crossed crimson field, a darker fold at each side, and a **fringed
hem** in the bottom margin. The hem must live in the 9-slice's bottom border so it never stretches.

---

## The record's furniture

| piece | how |
|---|---|
| dividers | `qm_rule.png` — a thin ink rule with a small cross at its centre, 9-sliced so the rule stretches and the cross does not |
| headings | `QUARTERMASTER RECORD` in the heading face, letter-spaced, above the note |
| seal | `qm_record_seal.png` — laurel ring + cross on oxblood wax, with a ribbon; placed bottom-right of the sheet |

`record.gd` gains the rules and the heading; every string still comes from `lore.gd`.

## The pack's furniture

Plaque reuses `qm_label.png` (the shelf plaques' own 9-slice) so the room speaks one signage
language. Slots gain a **numeral and a cross watermark** drawn as `Label`s inside the existing
compartment `Button`s — no new art, and they vanish under a packed instrument. `qm_strap.png` and
`qm_pennant.png` are baked into one `qm_packtrim.png` drawn beneath the case.

## The room

`qm_lantern.png` (own node, flickers), `qm_wallset.png` (baked), `qm_floor.png` (tiling, along the
foot), and `SEAL & DEPART` re-skinned to a crimson plate: `qm_rite.png` 9-slice with a gold border,
plus `qm_rite_seal.png` at its left. The motto is a `Label`.

---

## The instruments (R382)

Same 24×24 ASCII maps in Aseprite; what changes is the **material vocabulary**. Each glyph gains a
`+` variant meaning "the lit face of this material" and a `-` meaning "the occluded face", so the
form-aware pass has three explicit tones per material plus its own neighbour rule — 8–12 tones per
icon in practice. Brass collars, glass rims and a foot are added where the object would have one.

**The ban stands:** no `#B08A3E` or `#D6AE5C` on any instrument (P177), audited by the same check
that has run since TD-102.

---

## Files

**New art:** `qm_cloth`, `qm_deskset`, `qm_wallset`, `qm_lantern`, `qm_floor`, `qm_rule`,
`qm_record_seal`, `qm_packtrim`, `qm_rite`, `qm_rite_seal` (+ normals where lit).
**Changed:** `gen_qm_room.py`, `gen_icons.lua`, `room.gd`, `counter.gd`, `record.gd`, `pack.gd`,
`register.gd`.
**Untouched:** `lore.gd`, `shelf.gd`'s state machine, `seal_rite.gd`, all item data, `src/**`.

**Not built:** the reference's bottom instruction row with arrows (author instruction).
