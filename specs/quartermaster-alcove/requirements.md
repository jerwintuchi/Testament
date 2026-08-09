# Requirements — Alcoves and Contact Shadows (TD-108)

> **R379+**, **P172+**, **T404+**. Written to be picked up cold.
> Author brief, 2026-08-09. **Art and placement only** — no data, no interaction, no `src/**`.

---

## What a fresh session needs to know

TD-101→107 built the Quartermaster as a room: shelves, counter, record, open satchel, candle and
lamp, all lit by the Contract Board's shader from a two-light rig. Two items from the author's
reference remain, and both are about **making objects belong to the room** rather than sit on top
of it.

1. **The shelving is a free-standing frame drawn over masonry.** The brief asks for *recessed*
   storage — the shelves should be cut into the wall, not parked against it.
2. **Contact shadows are a 2px `ColorRect` bar.** Every instrument casts the same rectangle
   regardless of its shape, which is the single clearest "this is a UI sprite" tell left on the
   shelf.

**Author rulings, 2026-08-09:** the recess is an **alcove cut into the stone** (stone reveal, not a
wooden carcass), at a **4px reveal**, and contact shadows are **derived from each instrument's own
silhouette**.

**Constraints that already bind this work:** every PNG is authored offline and imported Nearest
(no pixel art generated in Godot at run time); surfaces carry a height field that drives both the
paint and the normal map; the room's budget is enforced by `tools/qm_budget.py`; and the Contract
Board must stay provably unaffected.

---

## R379 — The shelving is an opening in the wall, not a box in front of it

- AC: the shelf unit renders as an **alcove**: a **4px stone reveal** on all four sides showing the
  wall's thickness, a shadowed interior behind it, and the wooden boards spanning *inside*.
- AC: the reveal is **`navestone`** — the same ashlar as the wall and the Great Hall — so the opening
  is plainly cut from the building it is in, not lined with a second material.
- AC: the reveal is **lit consistently with the room**: the top and left faces catch light, the
  bottom and right fall away, and the interior darkens with depth.
- AC: it carries a **height field** driving both its paint and its normal map, as every other surface
  in this room does, so the shader lights the cut edge rather than a picture of one.
- AC: **no free-standing frame remains.** The uprights and top rail of the old carcass are gone;
  what reads as structure is the wall itself.

## R380 — Every instrument casts its own shadow

- AC: each of the ten instruments has a contact shadow **derived from its own silhouette**, not a
  shared rectangle.
- AC: the shadow is **densest where the object meets the board** and scatters to looser pixels
  outward — pixel clusters, never a gradient and never a soft blur.
- AC: it is **generated from `gear_icons.png` at authoring time**, so a new instrument gets a correct
  shadow without anyone drawing one, and the shadow cannot drift from the art it belongs to.
- AC: shadows are **scenery**: never focusable, never hoverable, never hit-testable.

## R381 — Nothing that works is disturbed

- AC: **no `src/**` change**; no change to item data, capacity, the state machine, the carry, packing,
  removal, or the seal rite.
- AC: hover remains **an outline and nothing else** (TD-103 author ruling). The shadow does not
  animate, because the object no longer moves.
- AC: the room's **budget holds** — `tools/qm_budget.py` green, node count within ceiling.
- AC: the **Contract Board is unaffected**; if any shared surface is touched, it is re-captured and
  compared rather than assumed (TD-106's lesson).

---

## Correctness Properties

- **P172 (the opening is cut, not drawn):** the alcove's reveal and interior come from the same
  height field that feeds its normal map, so the shader lights real relief.
- **P173 (a shadow belongs to its object):** every shadow is derived from the silhouette of the icon
  it sits under; the generator fails if an icon has no shadow or a shadow has no icon.
- **P174 (scenery cannot be touched):** alcove and shadow nodes are `MOUSE_FILTER_IGNORE` and
  unfocusable.

## Performance budget

Unchanged from TD-101 and enforced by `tools/qm_budget.py`: **≤ 260 nodes**, **≤ 20 particles**, no
`_process`, no full-frame additive layer. This spec swaps one node type for another per instrument
(a `ColorRect` becomes a `TextureRect`) and adds none.

## Verification

- **V1 (R379 / P172):** `--quartermaster` capture — the shelves read as openings; a `--lights-off`
  run shows the relief flatten, proving the shader lights it rather than the diffuse faking it.
- **V2 (R380 / P173):** the shadow atlas is generated and audited — ten shadows, each non-empty and
  matching its icon's base width; a capture shows different shapes under different instruments.
- **V3 (R381):** `qm_budget.py` green; `--board-after-qm` still green; `git diff` touches no `src/**`.
