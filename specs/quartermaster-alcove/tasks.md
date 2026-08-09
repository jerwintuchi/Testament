# Tasks — Alcoves and Contact Shadows (TD-108)

> T# continues global from T403. Art + placement only; no `src/**`, no interaction change.

- [x] T404 [R379, P172 / V1] — **The shelves become alcoves cut into the stone.** `_shelf_h`/`_shelf`
      in `gen_qm_room.py` no longer describe a carcass: rings from the outside in are the cut's
      shadow line, a **4px `navestone` reveal** (author ruling), an occlusion ramp, and a near-black
      interior lifting slightly at the foot.
      **The reveal is lit by FACING, not by position** — the top face catches light and the bottom
      face is in shadow wherever the alcove sits, because that is how a cut in a wall behaves. A
      border shaded by position would read as a printed frame, which is what the old carcass was.
      Stone rather than a wooden lining, deliberately: a lining says "a cabinet was fitted here",
      and the brief asks for shelves cut into the building. The wall, the Great Hall and the alcove
      all resolve to the same ramp (TD-081).
      Test: `--lights-off` — the relief **flattens to near-black** (mean luma 16.6 over the shelf
      band), proving the shader lights real geometry rather than a diffuse faking it. Lit capture
      shows the openings read as holes in the masonry.

- [x] T405 [R380, P173 / V2] — **Every instrument casts its own shadow.** New
      `gen_qm_shadows.py` reads `gear_icons.png`, finds each icon's base silhouette, and emits
      `gear_shadows.png` — dense at the contact row, scattering outward over three rows at three
      **discrete** alphas (190/110/55), because a smooth ramp is a gradient and this register has
      none. Seeded, so the sheet is byte-identical every run.
      **A lifted rim casts less than a standing base:** a column is weighted by how far it sits above
      the contact row, so a magnifier's glass and a lantern's hood do not throw shadow as if they
      rested on the board. Without that the cluster is as wide as the object's widest point — which
      is what the old rectangle already looked like.
      **Derived, not authored, so the claim is checkable:** the generator asserts every instrument
      casts (P173), and the consumer indexes shadows by the SAME `ICON_INDEX` as the icons, so a
      shadow cannot end up under the wrong object. A new instrument gets a correct shadow free.
      Test: audit — 10 shadows, each non-empty; preview shows visibly different shapes (narrow under
      the lens's stem, wide under the salt bowl).

- [x] T406 [R381, P174 / V3] — **Nothing that works was disturbed.** No `src/**`, no shared surface,
      so the Contract Board is unaffected by construction — and `--board-after-qm` is still green
      (`keepout live=8 ok=true`), which is the guard TD-106 added after the last time that assumption
      was wrong. Shadows are `MOUSE_FILTER_IGNORE` and unfocusable; hover remains an outline and
      nothing else, so the shadow never animates. Budget **189 nodes / 220**, 14 particles / 20 —
      the `ColorRect` became a `TextureRect`, so no node was added.

## Do not re-invent

- **The reveal is stone, not wood.** A wooden lining makes it a cabinet; the brief asked for an
  opening in the building. One ramp for wall, hall and alcove (TD-081).
- **Shadows are derived, never drawn.** Hand-authored ones need an eleventh drawn by hand the moment
  an instrument is added, and nothing notices when one drifts from its icon.
- **Three discrete alphas, not a ramp.** A soft shadow is the one thing that would break the register
  at this resolution.
- **Hover is an outline only** (TD-103). The shadow does not react, because the object does not move.
