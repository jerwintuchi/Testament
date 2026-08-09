# Design — Alcoves and Contact Shadows (TD-108)

> Satisfies R379–R381. Properties P172–P174. Art + placement only.

---

## The alcove

Replaces `qm_shelf.png` in place — same file, same 9-slice consumer, so `room.gd` needs no
restructuring. What changes is what the texture *depicts*.

```
        0 1 2 3 4 5 6 7 …                 ring   meaning
       ┌───────────────────           0    the shadow line where the cut meets the wall face
     0 │ ░ ▓ ▓ ▓ ▒ ░ · ·              1–4  the REVEAL: the wall's thickness, 4px (author ruling)
     1 │ ▓ █ █ ▓ ▒ ░ · ·              5–6  occlusion ramp into the interior
     2 │ ▓ █ █ ▓ ▒ ░ · ·              7+   the interior, near-black, with a faint floor bounce
     3 │ ▓ ▓ ▓ ▓ ▒ ░ · ·
     4 │ ▒ ▒ ▒ ▒ ▒ ░ · ·
     5 │ ░ ░ ░ ░ ░ · · ·
```

**The reveal is lit by facing, not by position.** The top face catches light and the bottom face is
in shadow *regardless of where the alcove sits*, because that is how a cut in a wall behaves under a
light in the room. The left/right faces take an intermediate value, brighter on the side nearer the
candle — which the shader then modulates for real, since the reveal has a normal map.

**Why `navestone` and not wood:** a wooden lining would say "a cabinet was fitted here"; the brief
asks for shelves cut into the building. The wall, the Great Hall and the alcove all resolve to the
same ramp (TD-081), so the opening is unmistakably part of the fabric.

**The old carcass is deleted, not hidden.** `_shelf_h`/`_shelf`'s uprights, top rail and iron straps
go; the boards (`qm_board.png`) stay and now span the opening.

---

## The contact shadows

A new generator step, `gen_qm_shadows.py`, reads `stations/gear_icons.png` and writes
`stations/gear_shadows.png` — ten cells, same 24px pitch, so a shadow is addressed by the same index
as its icon.

**Algorithm** (per icon):

```
for each column x:
    base[x] = lowest opaque y in that column, or none
contact = max(base)                     # the row the object actually rests on
for each column with a base:
    depth = contact - base[x]           # how far this column sits above the contact row
    weight = 1 - depth/6 clamped 0..1   # columns near the ground cast; a lifted rim does not
    emit at (x, 0)      alpha = 190 * weight        # dense at contact
    emit at (x±1, 1)    alpha = 110 * weight * s    # spreading, seeded scatter s
    emit at (x±2, 2)    alpha =  55 * weight * s
```

Three rows only, and the scatter is a **seeded hash** so the sheet is byte-identical every run.
Alpha steps are discrete — 190 / 110 / 55 — because a smooth ramp is a gradient, and this register
does not have those.

**Why derived rather than authored:** ten hand-drawn shadows would need an eleventh drawn by hand
the moment an instrument is added, and nothing would notice if one drifted from its icon. Deriving
makes `P173` checkable: the generator asserts every icon has a shadow and every shadow has an icon.

**Consumer:** `shelf.gd` swaps its `ColorRect` for a `TextureRect` with an `AtlasTexture` at the same
index it already uses for the icon. Position: the object's base, not its top — the shadow sits on the
board the instrument stands on.

The shadow **does not animate**. Hover is an outline only (TD-103), so the object never leaves the
board and there is nothing for the shadow to react to. The tween that used to tighten it is gone.

---

## Files

**New:** `client/assets/ui/gen_qm_shadows.py` → `stations/gear_shadows.png`.
**Changed:** `gen_qm_room.py` (`_shelf_h`/`_shelf` become the alcove), `shelf.gd` (shadow node).
**Untouched:** every other module, all item data, the interaction flow, `src/**`.

## Correctness Properties

- **P172** the opening is cut, not drawn — one height field feeds both paint and normal.
- **P173** a shadow belongs to its object — derived, and the generator fails on a mismatch.
- **P174** scenery cannot be touched — ignore-filtered, unfocusable.
