# Requirements — The Quartermaster, to the Reference (TD-110)

> **R382+**, **P175+**, **T407+**. Author reference image, 2026-08-09.
> **Art and presentation only.** No data, no interaction model, no `src/**`.

---

## What a fresh session needs to know

TD-101→108 built the room, its lighting, the alcoves and the derived shadows. This spec closes the
distance between that room and the author's reference image: the same composition, at the
reference's **density**.

**Measured before deciding anything:** the reference's shelf objects are ~50px wide in a 1536px
image, which is **~21px at our 640×360 logical** — so the reference is already 640×360-class art and
**24px is the right canvas**. The gap is detail density (8–12 tones with brass fittings, glass
highlights and feet, against our 4–7 flat-ish tones), not size. TD-055's rejection of hi-res UI art
is untouched by this work.

**The reference depicts objects our catalog does not have** — a telescope, a horned skull, a spiked
orb. `gear.ts` is authoritative and fixed: our ten keep their identities and gain the fidelity. The
reference gives *density and staging*, never the item list. (Same ruling as TD-075 for the title
screen: composition from the reference, content from the game.)

**Author rulings, 2026-08-09:**
- Instruments stay **24px** and gain reference density.
- The crimson counter cloth **is the inspection surface** — the chosen instrument rests on it.
- New dressing is **baked into composite textures**; only what animates gets its own node.
- **All four** scene groups are in scope: record furniture, pack furniture, counter props, room.

---

## R382 — The instruments carry their materials

- AC: each of the ten reads as a made object — brass collars and fittings, glass with a rim
  highlight, a foot or base to stand on, banding where a real one would have it.
- AC: **8–12 tones each**, up from 4–7, on the same 24px canvas.
- AC: **no bright gold** on an ordinary instrument (P168 stands): gold remains selection, headings,
  insignia, seal and the ready state.
- AC: hand-placed in Aseprite with the `.aseprite` source kept (TD-057).

## R383 — The counter is the Quartermaster's working bench

- AC: a **crimson cloth with gold crosses and a fringed hem** is draped over the bench and **is the
  inspection surface** — the carried instrument settles onto it.
- AC: the bench carries the reference's working set: an **open ledger** with a cross on the page, a
  **quill standing in an inkwell**, a **wax-sealed envelope**, a **brass balance**, stacked books,
  and a second candle.
- AC: the counter front gains **drawers with ring pulls**.
- AC: props are scenery — not focusable, not hoverable, not tooltipped (P169 stands).

## R384 — The record reads as a filed Collegium document

- AC: **cross-ornamented dividers** separate the quote, the record body and the warning.
- AC: a **QUARTERMASTER RECORD** heading above the body.
- AC: a **wax seal medallion** — laurel and cross, with a ribbon — at the foot of the sheet.
- AC: every word still comes from `lore.gd`; no item prose is rewritten.

## R385 — The pack is issued equipment

- AC: an **EXPEDITION PACK plaque** above it, in the same crimson-and-gold as the shelf plaques.
- AC: slots **numbered 1–4** with a faint cross watermark in each empty one.
- AC: **brass corner fittings**, **buckled straps** below, and a **hanging crimson pennant**.
- AC: capacity stays 4; the seal rite is unchanged.

## R386 — The room is furnished

- AC: a **hanging lantern on a chain** beside the shelves, lit and flickering.
- AC: **pinned parchment notes** on the wall, one with a wax blob.
- AC: a **crimson banner** with a gold cross at the top-left.
- AC: **flagstones** at the foot of the frame.
- AC: `SEAL & DEPART` becomes a **crimson banner-plate with a gold border and a seal ornament**, and
  a **THE COLLEGIUM STANDS WITNESS** line sits beneath it.

## R387 (containment) — nothing that works is disturbed

- AC: **no `src/**`**; no change to item data, capacity, the state machine, carry, packing, removal
  or the seal rite. Hover stays an outline only.
- AC: **static dressing is baked** into composite textures drawn as single nodes; only animated
  objects (candles, lantern, dust) get their own node. **Node count stays within the 220 ceiling.**
- AC: the Contract Board stays unaffected; `--board-after-qm` stays green.
- AC: **the instruction row with arrows from the reference is NOT built** (author instruction).

---

## Correctness Properties

- **P175 (density without cost):** new dressing that never moves costs one node per *composite*, not
  one per object — the room's node count stays inside the ceiling it already had.
- **P176 (the cloth is the surface):** the inspection rest point is derived from the cloth's rect, so
  the instrument cannot land beside the thing it is supposed to be set down on.
- **P177 (gold stays scarce):** no ordinary instrument is among the most-gold objects on screen.

## Performance budget

Unchanged: **≤ 220 nodes** (tool ceiling 260), **≤ 20 particles**, no `_process`, no full-frame
additive layer. Enforced by `tools/qm_budget.py`.

## Verification

- **V1 (R382 / P177):** icon audit — every instrument 8+ tones, zero bright-gold pixels.
- **V2 (R383, R386):** `--quartermaster` capture reads as the reference's room; no overlap, no
  clipping.
- **V3 (R384, R385):** `--qm-pick` and `--qm-full` captures show the record's furniture and the
  pack's.
- **V4 (R387 / P175):** `qm_budget.py` green with the count inside 220; `--board-after-qm` green;
  `git diff` touches no `src/**`.
