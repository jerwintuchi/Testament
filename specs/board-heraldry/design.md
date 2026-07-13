# Design — Board Heraldry (ornate crest + carved nameplate)

> Satisfies R147–R151. **Client render only** (I1/I2): no server/shared/wire change. Adds one
> generator (`gen_heraldry.py`) for the crest + a nameplate function, and re-wires the header
> in `main.gd` (`_notice_placard`, `_place_placard`, `placard_rect`) + `board_decor.board_crest`.
> Canon: hand-painted raster + baked lighting on the dungeon-dark board (TD-046/TD-048/TD-049).

---

## Reference read (what the design language is)

The reference is a horizontal carved-wood header:
- **Crest (top-centre):** an upright **sword** (blade up, crossguard, grip, pommel) set against
  a broken **ring**, flanked by a **laurel wreath** (two branches curving up the sides), crowned
  by symmetric **filigree scrolls** spreading up-and-out. Dark gilded bronze, strongly lit,
  mounted proud (cast shadow). It **breaks the top edge** of the plate below it.
- **Nameplate:** a wide weathered **plank** sign, **beveled**, with **iron corner brackets +
  bolts**. Two-line gilt title: **THE COLLEGIUM** (large serif) / **CONTRACT BOARD** (small,
  letter-spaced).

We reproduce the *design*, stylised to our generator's reach — layered, readable, tonally on
the dungeon-dark board — not the painted pixels exactly (R-preamble ruling).

## Assets — `client/assets/ui/gen_heraldry.py` (new, imports `ashember`)

Stdlib generator (imports `ashember` for the PNG writer + ramps + helpers), run FROM
`client/assets/ui/` (relative filenames — the standing generator gotcha). Emits two PNGs,
headless-imported (`godot --headless --import`).

### Metal shading primitive

A shared `metal(lit, tone)` that rides the **gold/bronze** ramp: `deep`, `base`, `hi`, plus a
bright **rim** for light-facing edges and a dark **recess** for engraved lines. Lit from the
**upper-left key** (`LX, LY = -0.66, -0.66`, matching `gen_emblems`). Every crest component is
drawn as a coverage mask → shaded by a local surface term (edge distance for the rim, a lambert
for domed pieces), so the emblem reads as relief, not flat fill. Supersampled (`SS=3`) AA edges
(reuse the `gen_emblems._supersample` pattern).

### `crest_v1.png` (≈150×132, taller than the old 150×70)

Composited back-to-front, each a metal-shaded mask with alpha 0 elsewhere:

1. **Filigree scrolls (backmost, top):** symmetric C-scrolls / volutes emanating up-and-out
   from the top centre — parametric spiral arcs (`r = a·θ`), mirrored L/R, a few px thick,
   dimmer bronze (they sit behind). Tunable count; drawn first so the sword/ring overlap them.
   *If the scrolls read messy at capture size they degrade to a simpler pair of curls (V1 call).*
2. **Ring:** a bronze annulus (a torus band) centred behind the sword, **broken at the top**
   where the blade passes through — `abs(hypot(nx,ny) - R) < band`, minus a top gap.
3. **Laurel wreath:** two branches, one per side, each a parametric arc from bottom-centre
   sweeping up the ring's flank; **leaves** are small angled ellipses placed at intervals along
   the arc (alternating out?/in?), tapering toward the tip. Mid bronze, lit top-left.
4. **Sword (front, centred, upright):**
   - **blade** — a tall tapering isosceles (wide at guard, point at top) with a thin brighter
     **fuller** centre line;
   - **crossguard** — a horizontal bar at ~38% height, slight down-curve at the tips;
   - **grip** — a short vertical below the guard (a touch darker, wrapped);
   - **pommel** — a small domed disc/diamond at the base.
   Brightest gilt of the emblem (the hero), strong up-left rim.
5. **Central boss:** a small domed rivet where guard meets ring — catches the key.

`board_crest()` (in `board_decor.gd`) keeps drawing the **cast shadow** (a black, offset,
slightly-enlarged copy) so the emblem reads mounted; only the source texture + display size
change.

### `board_nameplate.png` (≈112×48, 9-slice with corner brackets)

A carved plank sign, **9-slice-safe** so it stretches to the title width:
- **Corners (fixed, ~22×22):** an **iron L-bracket** hugging each corner (two arms of dark
  iron with a bevelled lit top-left edge) + **bolt heads** (domed rivets) — lit top-left.
- **Edges:** a **beveled plank border** — a lit top chamfer, a dark bottom, plank seams.
- **Centre field:** deep warm wood, **horizontal grain**, a **recessed darker title panel**
  (an inset with a thin lit upper lip + dark lower) so the gilt letters read against it.
- Palette: the `wood` ramp (deep→hi) for the plank, `stone/black` + a gilt fleck for the iron
  brackets/bolts. Quantise for cohesion (optional; palette-lock retired TD-046).

9-slice patch margins ≈ **22 L/R, 22 T, 16 B** (keep the brackets un-stretched). Godot draws
the gilt title over the centre.

## Wiring — `main.gd` + `board_decor.gd` + `board_geometry.gd`

### Nameplate + two-line title — `_notice_placard` / `_place_placard`

- `board_placard.png` → **`board_nameplate.png`**; patch margins updated (22/22/22/16).
- `placard_rect` (in `board_geometry.gd`): **widen** the plate — `w ≈ inner.x · 0.62`
  (header-spanning, up from 0.42), height a touch taller for two lines (`inner.y · 0.11`),
  seated at the top band (`y ≈ inner.y · 0.115`).
- `_notice_placard(title, subtitle)` grows a second label:
  - **line 1** — `_card_label("THE COLLEGIUM", ~15, GILT)`, centred, upper portion;
  - **line 2** — `_card_label("CONTRACT BOARD", ~9, GILT_DIM, letter-spaced)`, centred, lower;
  both with the existing dark drop shadow. (Two labels because the two lines are different
  sizes; a `VBoxContainer` centres them.) Text stays **unlit** on top (P85).
  The nail Panels are dropped (the iron corner brackets replace them as the "mounted" cue).

### Crest — `board_crest()` / `_build_contract_board`

- `board_crest()` loads the new `crest_v1.png`; **display size grows** (≈ `96×85` from `76×35`)
  and the cast shadow scales with it.
- Placement in `_build_contract_board`: centre-x, and **raised** so the crest overlaps the
  nameplate's top edge (crowns it). z_index above the nameplate (keep `6`), below the reader.

## Correctness Properties

- **P82 (render-only, R151):** every change is a client asset/node; no `src/server` or
  `src/shared` edit, no wire message, no game-state read/write (I1/I2).
- **P83 (one register, R147/R148):** crest + nameplate are the same hand-painted raster idiom
  as the rest of the board (weathered, warm, dungeon-dark, baked), no foreign style.
- **P84 (Origin-neutral crest, R147):** the device is blade + laurel + scroll (the order's),
  and carries none of the Belief/Sin/Relic sigils; no trait data informs it (it is pure art).
- **P85 (title legibility, R149):** the gilt title is unlit ink on top of a recessed field; its
  contrast is set by the gilt colour vs the field, ≥ the floor at the title, independent of the
  baked nameplate lighting (heritage of the parchment floor T156/R136).

## Assets & files touched (all client)

New: `assets/ui/gen_heraldry.py`, re-authored `assets/ui/crest_v1.png` (bigger), new
`assets/ui/board_nameplate.png` (+ `.import`s). Edited: `scripts/ui/board_decor.gd`
(`board_crest` size/texture), `scripts/main.gd` (`_notice_placard` two-line title,
`_place_placard`), `scripts/ui/board_geometry.gd` (`placard_rect` widened). **No server/shared
files.** `board_placard.png` is superseded by the nameplate (kept on disk as a fallback only if
the load fails).

## Superseded / notes

- The radiant-star `crest_v1.png` (T158) and the routed `board_placard.png` (T159) are the
  immediate baseline this replaces — both were "consistent + tonally matched" but plain; the
  user asked for the **ornate** blade-and-laurel design. Logged in DECISION_LOG TD-049.
- The generator gotchas from board-lighting carry over: run generators **from
  `client/assets/ui/`** (relative filenames); brand-new PNGs need `godot --headless --import`.
