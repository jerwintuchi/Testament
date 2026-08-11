# Asset Briefs — The Stores Gain Form (TD-115)

> For the author. One brief per asset. Deliver into
> `C:\Users\jerwi\Pictures\Testament\prop-assets\quartermaster\` using the **filename
> given**; I crop, grade, derive normal maps, wire and capture.

---

## The rules that apply to all six

- **Draw at the size given.** Everything in this project is authored at the size it is
  displayed and drawn 1:1 through NEAREST. A piece drawn at 4× and reduced turns to mush
  — measured twice, at TD-054 and again on your seal-stamp.
- **Baked light, from the upper left.** Every one of your existing pieces reads correctly
  because the light is drawn *in* — bevels, grain, ambient occlusion, a lit top edge, a
  shadowed foot. That is exactly what the generated art lacks, and it is the whole point
  of this pass.
- **Hard tonal steps, no gradients, no anti-aliasing.** Three to five tones per material.
- **Colour is free.** Don't match the room's palette by hand — I measure a grade and
  apply it. Your last set needed one gain (R×1.06, G×1.09, B×0.85) and nothing else.
- **Alpha where there is no object.** Transparent, not black.
- **The room is dark and getting darker.** Draw the object as if lit by a candle a metre
  away: a bright side, a mid body, a deep shadow side.

---

## 1. `qm-wall.png` — the ashlar behind everything · **128 × 128** · tiles both axes

**The one that matters most.** It is currently a nearly featureless grey-brown field, and
a lighting shader paints a smooth gradient across it — a smooth gradient over nothing is
what reads as a 3D render sitting in a pixel-art scene.

**Must show:** cut stone blocks with **deep recessed joints** (a shadow line, not a bright
line); each block a slightly different tone from its neighbours; a **lit chamfer** at each
block's top-left and a **shadowed foot** at its bottom-right; **chipped arrises** where
two exposed edges meet, because that is where stone actually fails; sparse damp or soot
staining that does not read as a repeating stamp.

**Scale:** roughly 2 courses of 2–3 blocks across the tile, so blocks read at around
64×40. Vary the block widths — a course of identical blocks reads as graph paper.

**Must tile seamlessly on both axes.** I check this automatically (column 0 against 127,
row 0 against 127) and the check fails on a seam, so please offset-test it before sending.

**Avoid:** per-pixel noise, a bright mortar line, uniform block sizes, anything centred
(it tiles — there is no centre).

**I derive its normal map from the image's own luminance,** so the joints you draw dark
become the recesses the shader lights. You do not supply a normal map.

---

## 2. `qm-cloth.png` — the altar cloth on the bench · **104 × 46 exactly**

The inspection surface an instrument is set down on. Currently a flat red rectangle with
two flat crosses and a fringe.

**The size is load-bearing:** the resting place of the inspected instrument and the
caption beneath are both derived from this rect. 104 × 46, not approximately.

**Must show:** **folds** — the cloth is draped over a bench, so it gathers and the top
plane catches light while the front face falls into shadow; a **woven texture** (a subtle
two-tone weave, not noise); a **hem** at the bottom; the Collegium device **embroidered
into** the weave — sunk, catching light on one edge and shadowed on the other — rather
than printed flat on top.

**Layout:** the top ~32 rows lie on the bench's top surface, the bottom ~14 hang over its
front edge. Put the fold shadows where the cloth turns that edge.

**Avoid:** a flat field, a hard rectangle of colour, a device that looks stuck on.

---

## 3. `qm-rite-plate.png` — the SEAL & DEPART plate · **48 × 30** · 9-slice

The commitment control, spanning the full width of the screen at the foot. Currently a
red rectangle with a gold rule.

**It is a 9-slice, and that constrains it absolutely:** the **centre must be a uniform
field** with nothing in it. The centre is the region that stretches to ~600px wide, so a
device, a bevel or a bolt there smears across the whole screen. This project has learned
that twice already.

**Margins:** 14 left / 14 right / 10 top / 10 bottom. All the form lives in those bands.

**Must show:** a struck metal or painted-wood **plate with a bevelled edge** — a lit top
edge, a shadowed bottom; **fixings** (rivets or corner straps) in the left and right
margins; a **worn face** with the wear at the edges rather than scattered evenly.

**Two states, and I make the second one:** draw the **ready** state (warm, gold-lit). The
not-ready state is the same object at a dim modulate, so please do not draw two.

**Avoid:** anything in the middle 20 columns; a border-only design; a flat fill.

---

## 4. `qm-satchel.png` — the expedition pack · **64 × 48** · 9-slice

The open pack the instruments fly into. Currently a dark box with a lid strip.

**Also a 9-slice** — margins 18 on all sides — so again the **centre must be uniform**.
It stretches to about 222 × 60.

**Must show:** **leather with grain**, a **stitched edge** in the margin bands, a
**turned-back flap** with its underside in shadow at the top, and a **dark interior**
that reads as depth rather than as a black rectangle. Brass or iron fittings in the
corners are welcome — they live in the margins, so they survive.

**Avoid:** anything in the centre; a uniform dark fill; a lid drawn as a single line.

---

## 5. `qm-lantern.png` — the hanging lantern · **20 × 60**

Hangs in the gutter between the shelves and the record board, and is the visible source
of the room's fill light — so it has to look like it emits. Currently a bracket and an
orange bar.

**Must show:** a **hanging chain or hook** at the top; a **metal frame** with visible
corner posts; **glass panes** with a highlight; a **flame** inside, brightest at its core;
the frame **lit from inside**, so its inner edges are warm and its outer edges are dark.

**Layout:** roughly the top 16 rows are chain and mount, the middle 32 the lantern body,
the bottom 12 a finial. Drawn 1:1 — it is never stretched.

**Avoid:** a flat orange rectangle for the flame; a symmetrical body with no depth.

---

## 6. `qm-banner.png` — the corner banner · **26 × 54**

Hangs at the top-left corner above the header. Currently a flat crimson strip with a
cross and a swallowtail hem.

**Must show:** **vertical folds** so the cloth hangs rather than lies flat — a lit ridge
and a shadowed valley, at least two folds across 26px; a **top hem** with the rod or
nails it hangs from; the device on it following the folds rather than sitting flat across
them; a **frayed or swallowtail hem** at the bottom.

**Avoid:** a flat field with a device stamped on it; perfect symmetry.

---

## What happens when a file arrives

1. I add it to `gen_qm_furniture.py` — the one door every author asset comes through, so
   everything takes the same measured grade (P178).
2. I derive any normal map from the delivered image, never from a separate source (P180).
3. I capture the room, look at it, and tune the grade if it needs it.
4. I delete the generated painter it replaces, **only after** the replacement has landed
   and been captured (TD-070's rule).

**Until a file arrives the room keeps the current generated art** (P179), so you can send
them one at a time and nothing breaks in between.
