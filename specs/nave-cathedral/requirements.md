# Requirements — The nave re-authored as High Gothic; the limestone palette (TD-072)

> On the author's reference (Chartres, nave looking east). The TD-071 nave is **structurally the
> wrong building**: round arches, a flat dark vault, plain rectangular piers, a camera at eye level.
> That is Romanesque — heavy, low, enclosing. The reference is **High Gothic** — pointed, ribbed,
> shafted, and above all *tall*. It does not read as "a nicer version" of what exists; it is a
> different architecture, and the awe comes from the difference.
>
> The reference is also a **warm limestone** building. The client's entire stone vocabulary today is
> **cool blue-grey** (`stone` ramp `#22242A → #616A72`). The author's instruction is to derive the
> wall colour from this palette and carry it to the **Contract Board's wall**, so the two spaces
> read as one Collegium.
>
> Client render + generated art only. Numbering continues global: **R235+**, correctness **P127+**,
> tasks **T249+**. Logged **TD-072**. Verified by capture, plus a **measured** contrast check on the
> board (the wall change is the risky part, not the nave).

---

## What the awe is actually made of

Named so the implementation has criteria, not vibes. From the reference, in order of contribution:

1. **Verticality.** The vault owns the top ~half of the frame and the eye is pulled up before it is
   pulled in. Shafts run unbroken from floor to springing — the reference's piers are *bundles of
   thin colonnettes*, which is what makes stone look drawn upward rather than stacked.
2. **A low camera looking up.** The horizon sits low; the vault is seen from beneath, so its ribs
   splay overhead. An eye-level shot of the same building is merely a corridor.
3. **Storeys.** Arcade → triforium → clerestory. Three tiers of diminishing openings give the wall a
   measurable height; a blank wall gives it none.
4. **Ribs that converge.** The quadripartite vault's ribs meet at bosses along the ridge, drawing a
   receding chain of Xs down the ceiling — the strongest depth cue in the image.
5. **A lit far end.** The apse glows pale and cool against everything near it, so depth is read as
   *light*, not just as size.
6. **Jewel light.** Small, intensely saturated windows against a desaturated stone field. The glass
   is a fraction of the area and carries most of the colour.

## Phase A — The palette

**R235**: a **limestone** palette is derived from the reference and becomes the client's warm stone.
- AC: the ramps below are added to `ashember.py` and are what the nave is authored from. They are
  measured from the reference (k-means over the image + per-region percentile sampling), not picked
  by eye:

| Ramp | Steps | Role |
|---|---|---|
| `limestone` | `#140B05 · #251A11 · #3C2C1F · #544136 · #6E5C4D · #907A63 · #B79C84` | piers, walls, vault webs |
| `vaultstone` | `#150F0C · #2A211B · #433529 · #5E4E43 · #7B6A5A` | vault + ribs, a touch cooler/greyer |
| `apse` | `#4A4050 · #797A91 · #B9A9A8 · #ECC8B6` | the far end: cool violet-grey blooming to warm pale |
| `glass_cobalt` | `#101A3A · #26346A · #4C6FA8 · #A3D9F9` | the dominant glass |
| `glass_ruby` | `#2A0C15 · #581F30 · #9A3550 · #F8B7CD` | |
| `glass_amber` | `#2E1B0B · #5A3F21 · #A97A45 · #EBA97F` | |

- AC: the existing cool `stone` ramp is **retained** (the field/tiles still use it); `limestone` is
  additive, not a replacement, so nothing outside this spec's scope shifts silently.
- AC: `assert_on_palette` accepts the new ramps, and the nave passes it.

## Phase B — The nave re-authored

**R236**: the nave is High Gothic, not Romanesque.
- AC: **pointed** arches throughout (arcade, triforium, clerestory, apse lancets) — the current
  semicircular heads are the single most Romanesque thing in the image and must go.
- AC: a **ribbed quadripartite vault**: diagonal ribs crossing at a boss per bay, transverse ribs at
  each bay division, and lighter infill webs between them. Not a flat dark ceiling.
- AC: **compound piers** — a core with engaged colonnettes, so each pier reads as a bundle of
  vertical shafts, with capitals at the springing.
- AC: **three storeys** — main arcade, a shallow triforium band, and a clerestory of pointed windows
  — each tier's openings smaller than the one below.

**R237**: the camera creates the height.
- AC: the vanishing point sits **low** (≈0.62–0.70 of frame height) so the viewer looks **up** the
  vault, and the vault occupies roughly the upper half of the frame.
- AC: bays recede with perspective spacing to a **lit apse** carrying pointed lancets; the apse is
  the brightest thing in the frame and reads as distance.
- AC: the image remains **empty** — no character, creature, weapon, effect, or furniture. (The
  reference's chairs are deliberately not reproduced: they are clutter and they date the space.)

**R238**: light does the storytelling.
- AC: clerestory and aisle windows are **jewel-saturated** against desaturated stone, and cast a
  faint coloured wash onto nearby surfaces.
- AC: near piers sit darkest, the far arcade brightens toward the apse — depth as luminance.
- AC: the plate stays **legible as a backdrop**: the title and its options sit over it with the
  gilt still reading, so the centre of the frame stays comparatively quiet.

## Phase C — The Collegium's wall follows

**R239**: the Contract Board's wall is re-toned to the limestone palette, so both spaces are one
building (author instruction).
- AC: `stone_tile.png` (+ its normal) is re-authored from `limestone`, replacing the cool blue-grey
  masonry currently behind the board and the room-setup plate.
- AC: **the board's legibility floor is re-verified, not assumed** — the L1 measurement (INK on the
  parchment floor tone ≥ 4.5:1) and L3 (each writ readable in its own backlight) must still pass, and
  the warm/cool separation that currently makes the torch halos read must be re-checked by capture.
  If warming the wall costs the torches their read, the wall is toned back — the board is shipped
  work and does not regress for the menu's benefit (P127).

## Cross-cutting

**R240** (containment): client render + generated art only.
- AC: no `src/**` change; no wire change; dependency map regenerated; server + shared suites green.

---

## Correctness Properties

- **P127 (no silent regression of shipped work, R239):** the palette change is additive and its
  reach is explicit. The board's measured legibility (L1) and its lit read (L3/L5) are re-verified
  after the wall re-tone; a failure reverts the wall rather than accepting a quieter board. The
  cool `stone` ramp survives for everything not named here.

## Verification

- **V1 (R235):** `python3 ashember.py` self-test green with the new ramps; the nave passes
  `assert_on_palette`.
- **V2 (R236/R237):** a `--title-preview` capture shows pointed arches, a ribbed vault with bosses,
  compound piers, three storeys, and a lit apse, with the vault owning the upper half; re-captured
  at 1920×1080 for the integer-scale centring.
- **V3 (R238):** jewel windows read as saturated against desaturated stone; the gilt title and
  options stay legible over the plate.
- **V4 (R239/P127):** board captures before/after the wall re-tone; L1 recomputed (INK on the floor
  tone, ≥4.5:1) and stated numerically; `--lights-off` still proves the torch rig is what lights it.
- **V5 (R240):** `git diff --name-only` only `client/ specs/ docs/`; asset-map `--selftest` +
  `--check`; server + shared suites green.
