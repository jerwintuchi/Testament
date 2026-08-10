# Requirements — Depth: the Room Stops Being an Elevation (TD-112)

> **R392+**, **T419+**. Author brief, 2026-08-10: *"more detail, more detailed texture, and not flat
> (in angle and in texture)."*
> **Art only.** No data, no interaction, no `src/**`.

---

## The diagnosis

Every surface in the Quartermaster is currently a **front-on elevation**: the counter is a rectangle,
the alcoves are rectangles, the floor is a strip. Nothing shows a second plane, so nothing has
volume — the room reads as a wall of flat panels no matter how well each panel is shaded.

The reference is in **3/4 perspective**: the desk shows its **top surface receding away** with the
front face below it, the shelf boards show their **front edge and their upper surface**, and objects
sit ON those visible tops rather than in front of them. That single difference is most of what the
author is seeing as "flat".

**The blocking technical fact, learned three times already in TD-110:**
**a 9-slice cannot carry perspective.** Stretching a receding plane makes its vanishing lines diverge,
which reads as a warped object. Every perspective surface must therefore be **authored at the size it
is drawn** — exactly the ruling that fixed the altar cloth and retired `qm_rule.png`.

That is the real cost of this spec: the counter, the alcoves and the floor stop being small tiling
9-slices and become **large authored sprites**, one per display size.

---

## R392 — The room is drawn in 3/4 perspective

- AC: the **counter** shows three planes — a receding **top surface**, a **front face**, and one
  **end face** — each with its own tone band, so the eye reads a solid object.
- AC: the **alcoves** show the **thickness of the cut**: the reveal's top face is seen from below and
  its bottom face from above, with the interior receding to a vanishing point above the counter.
- AC: the **shelf boards** show a front edge AND a sliver of upper surface, so an instrument stands
  *on* a plane rather than in front of a line.
- AC: **one vanishing point** for the whole room, declared as a constant and read by every surface —
  two surfaces receding to different points is what makes a scene read as collage.

## R393 — Perspective art is authored at display size

- AC: any surface carrying perspective is a **single sprite drawn 1:1 NEAREST**, never a 9-slice and
  never scaled. (`qm_counter`, the alcove frames, the floor.)
- AC: surfaces with no perspective (plaques, the rite plate) may stay 9-slices, because their centres
  are uniform fields.
- AC: the generator asserts each perspective sprite's authored size equals the rect it is drawn into,
  so a mismatch fails at build rather than appearing as a soft or doubled edge.

## R394 — Texture density is raised

- AC: **wood** carries grain running *with* the plane's perspective, plus knots, worn arrises and
  end-grain at cut edges.
- AC: **stone** carries per-block tonal variation, pitting, chipped corners and mortar depth — not a
  repeated tile.
- AC: **iron** carries hammered facets and rust bloom at joints; **brass** carries a lit crown and a
  dark foot.
- AC: texture is **structural, never noise**: variation lands on edges, joints and wear paths where a
  real surface would show it. Per-pixel scatter is explicitly forbidden — it has been shipped twice
  by accident (the polka-dot counter, the hatched label) and is what makes pixel art look dirty
  rather than detailed.

## R395 — Objects follow the perspective

- AC: the instrument set down on the counter rests on the **top surface**, at a point derived from
  the counter's perspective geometry — not at a fixed offset from its front face.
- AC: contact shadows sit on the plane the object stands on and shear with it.
- AC: the altar cloth drapes **over the front edge**, so it crosses two planes and proves the depth.

## R396 (containment)

- AC: no `src/**`, no interaction change. The state machine, carry, packing, removal and seal rite
  are untouched.
- AC: node budget holds at **≤ 220** — perspective is paid in *authored pixels*, not in nodes.
- AC: `--board-after-qm` stays green.

---

## Tasks

- [x] **T419** — declare the room's single vanishing point and the plane geometry every surface reads.
- [x] **T420** — re-author the counter as one perspective sprite: top, front and end faces.
- [x] **T421** — re-author the alcoves with visible cut thickness and a receding interior.
- [x] **T422** — re-author the shelf boards with a visible upper surface.
- [ ] **T423** — raise texture density on wood, stone, iron and brass per R394.
- [ ] **T424** — move the rest point and contact shadows onto the perspective planes.
- [ ] **T425** — verify: budget, board guard, captures of empty/picked/full/sealed.

## Sequencing note

**T419 first, and alone.** Every other task reads the vanishing point; authoring any surface before
it is fixed guarantees a re-do. This is the same coupling lesson as the candle and its light (TD-105)
and the cloth and its rest point (TD-110): when many things must agree on one value, that value is
declared once and derived everywhere.

## Depends on

`specs/quartermaster-gear/` **T417–T418** (the nine remaining hand-shaded instruments). The
instruments sit on these surfaces; re-authoring the surfaces first would mean judging them against
art that is about to change.
