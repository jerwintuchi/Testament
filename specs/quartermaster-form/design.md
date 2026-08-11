# Design — The Stores Gain Form (TD-115)

> Satisfies R397–R405. Properties P178–P182.
> Presentation only. `src/**` is not touched. Author art enters through one door.

---

## Where the code is

| what | where | change |
|---|---|---|
| author art → runtime PNGs | `assets/ui/gen_qm_furniture.py` | grows: the cabinet rebuild, the wall's derived normal map, one more prop divisor |
| generated surfaces | `assets/ui/gen_qm_room.py` | shrinks as author art lands; each retired painter is deleted with its output (TD-070's rule) |
| the room | `stations/quartermaster/room.gd` | cabinet geometry re-derived; the light rig re-tuned |
| the shelves | `stations/quartermaster/shelf.gd` | three per shelf; the hover brighten |
| the pack | `stations/quartermaster/pack.gd` | none (the satchel is a drop-in 9-slice) |
| the rite plate | `stations/quartermaster/register.gd` | none (drop-in 9-slice; only the margins move) |
| item data / bag rules / prose | `src/**`, `lore.gd` | **none** |

---

## The cabinet rebuild (R397, P182)

The author's closed cabinet is 166×166. It is made **bigger by repeating its own drawn
bands**, never by scaling — so its pixels stay exactly the size of a 24px instrument
icon, which is the whole reason 1:1 is canon (TD-050/TD-055).

Two inserts, both cuts of the author's drawing:

```
VERTICAL — one extra shelf band, full width

   rows  0.. 69   crown, first two alcoves          kept
   rows 70..102   ONE ALCOVE + ITS SHELF            kept, then REPEATED
   rows 70..102   (the copy)                        inserted
   rows 103..165  deck, drawers, plinth             kept, shifted +33

   166 -> 199 tall.  Left bay shelves 36/69/102 -> 36/69/102/135
                     Right bay        41/67/97  -> 41/67/97/130
```

The band is chosen so that **both** bays are mid-alcove across it: the left bay's shelf
at 102 and the right bay's at 97 both fall inside, so one insert gives each bay one more
shelf. Picking a band that straddled only one bay would make the two bays different
heights, which is impossible in a single object.

```
HORIZONTAL — one backboard slice inside each bay

   cols  0.. 12   left upright                      kept
   cols 13.. 78   LEFT BAY  — a middle slice repeated (+37)
   cols 79.. 87   centre stile                      kept
   cols 88..152   RIGHT BAY — a middle slice repeated (+37)
   cols 153..165  right upright                     kept

   166 -> 240 wide.  Bay interiors 66/65 -> 103/102
```

The closed cabinet's bays are **empty** — vertical planking with no drawn contents — so a
middle column slice is genuinely repeatable, and a shelf board crossing it simply gets
longer. **The known risk is the drawer band:** the four drawers do not align with the
bays, so an insert inside a bay lands inside a drawer and widens it. Two drawers become
wider than the other two. T430 verifies this by looking; the fallback, if it reads badly,
is to make the horizontal insert a whole drawer unit and accept a wider bay than 103.

**Geometry is then measured back off the emitted PNG, never hand-typed** (P182): the
shelf rows are found by their lit top edge and the bay spans by their uprights, exactly
as they were found for the 166 version. A `--qm-geometry` readout prints what it found so
a re-derivation that disagrees with the art is visible rather than silent.

Three per shelf: a bay interior of ~102 holds `3 × 24 = 72` with 30px of air, so the
existing even-pitch placement in `shelf.gd` needs no new rule — only more room.

---

## The wall (R398, P180)

The author delivers a **128×128 diffuse** that tiles on both axes. This spec derives its
normal map from that image's own luminance, using the existing `gen_normals._normal_pixel`
— the same function every generated surface already uses, so relief and shading come from
one source and cannot disagree.

Deriving relief from a *delivered* diffuse is new: until now every normal map came from
the height function that also drove the paint. The substitute is the drawn luminance
itself, which is legitimate precisely because the brief asks for drawn form — cut joints
read dark, lit chamfers read bright, and that IS the height field.

The surface shader stays (author ruling). What changes is that it now has structure to
describe rather than a flat field to gradient across.

**Seam check, not eyeball:** a self-check samples column 0 against column 127 and row 0
against row 127 for continuity of the joint pattern, and fails if a delivered tile does
not wrap. A wall that almost tiles is the defect that only shows up on a wide screen.

---

## Lighting (R403)

Moodier, and it is three numbers, not a rewrite:

| | now | target | why |
|---|---|---|---|
| wall ambient | 0.22 | **0.13** | the corners fall away |
| candle radius / energy | 0.44 / 0.90 | **0.34 / 1.05** | tighter, hotter — a pool rather than a wash |
| lantern fill energy | 0.34 | **0.22** | the gutter reads as spill, not a second key |
| room vignette | 0.26 | **0.38** | the frame's edges deepen |

The pools stay coupled to their fixtures through `candle_pos` and `lantern_pos` (P95) —
neither may be re-aimed without moving the object that casts it.

**Text is exempt.** The header, the record's prose and the rite plate's letter are drawn
above the surfaces and keep their own colours; a darker room must not be paid for in
legibility (TD-098's spirit). The record's contrast is re-measured after, not assumed.

---

## Hover carries the light (R404, P181)

`shelf.gd` already builds a hidden gold edge per instrument and toggles it (TD-103).
This adds one property alongside it:

```
_set_hover(rec, on):
    rec.edge.visible = on
    rec.icon.modulate = LIT if on else Color.WHITE     # a brighten, not a tween
```

`LIT` is a warm multiplier a little above white, so the instrument reads as catching the
candle rather than as a UI highlight. **No tween**: hovering must allocate nothing and
run nothing per frame, which is also why the reduced-motion path needs no special case —
there is no motion to reduce, only an instant property.

Mouse and keyboard drive the same handler, so the room is not darker for a player using
focus rather than a pointer.

---

## How author art lands (P178, P179)

One door: `gen_qm_furniture.py`. Each new asset gets an entry naming its source, its
content box and its transform, and takes the **same measured grade** as the furniture
(TD-114) unless its brief says it is delivered already in the room's palette.

Every asset is optional until delivered:

```
if not os.path.exists(src):
    print("  %-40s not delivered yet — keeping the generated art" % out)
    return
```

so the tree is always buildable and art can land one file at a time (P179). A generated
painter is deleted **only when its replacement has landed and been captured** — and then
its output, its painter and its table entries go together, because generated art with no
consumer is what TD-070 had to go back and clean up.

---

## Files

**Changed:** `assets/ui/gen_qm_furniture.py`, `assets/ui/gen_qm_room.py` (deletions as
art lands), `stations/quartermaster/{room,shelf}.gd`, `tools/qm_budget.py` (the tiling
and geometry checks).
**New:** `specs/quartermaster-form/asset-briefs.md`; the author's PNGs under
`assets/ui/_src/qm/`.
**Untouched:** `lore.gd`, `seal_rite.gd`, `record.gd`, `pack.gd`, `gear_icons.png`, the
record board, all of `src/**`.
