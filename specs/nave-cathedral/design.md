# Design — The nave re-authored as High Gothic (TD-072)

> Satisfies R235–R240. Client render + generated art. Verified by capture + a measured contrast check.

---

## Where the palette came from

Not eyeballed. `client/assets/ui/` + `pngio` were run over the reference:

1. **k-means (k=14) over 24k samples** for the image's true working palette. It came back dominated
   by warm mid-browns — `#57463B`, `#6A594D`, `#826D5F` — with a long dark tail (`#1F1008`,
   `#110704`). Confirms the building is **warm**, and that most of its area is *mid-dark*, not
   bright: the awe is not brightness.
2. **Per-region percentile sampling** (dark 10% / mid 50% / lit 92%) to separate architecture from
   the foreground pews, which polluted the global cluster:

```
high vault (centre)   dark #1B100D   mid #3E2E1D   lit #76674F
nave pier faces       dark #150B03   mid #544138   lit #9F856E
far arcade / depth    dark #2B1E1C   mid #5E4E43   lit #D0988F   ← the lit far end
apse east window      dark #76554E   mid #797A91   lit #ECC8B6   ← cool violet → warm bloom
```
3. **Hue-bucketed saturated pixels** for the glass, since averaging over the lead came back muddy:
   cobalt `#26346A` typical / `#A3D9F9` peak; ruby `#581F30` / `#F8B7CD`; amber `#5A3F21` / `#EBA97F`.

Two findings drive the whole spec: the stone is **warm ochre**, where the client's `stone` ramp is
cool blue-grey; and the **far arcade is lighter than the near** (`#D0988F` vs `#150B03`), which is
the depth cue the current nave gets backwards by darkening with distance.

## Geometry — what changes

The TD-071 corridor projection (`_resolve`: ray-cast each pixel to floor / vault / wall / far wall
with depth `t`) is **kept** — it is what made the bays converge, and it generalises. What changes is
what is drawn on those surfaces.

| Element | Now (Romanesque) | Target (Gothic) |
|---|---|---|
| Arch heads | semicircle, `arch_top = -0.62 - 0.42·√(1-(dp/half)²)` | **two-centred pointed**: two arcs struck from opposite springing points, meeting at an apex |
| Vault | flat near-black + faint rib hint | **quadripartite**: diagonals crossing at a boss per bay + transverse ribs + lighter webs |
| Piers | flat rectangular face | **compound**: core + 3–5 engaged colonnettes, each shaded as a half-round, capitals at springing |
| Storeys | one | **three**: arcade / triforium band / clerestory windows |
| Camera | `VPY = 0.545` | **`VPY ≈ 0.66`** — the viewer looks up; vault takes the upper half |
| Depth | darkens with distance | **brightens** toward a lit apse |

### The pointed arch

A single formula replaces the semicircle. For bay coordinate `dp ∈ [0, half]` measured from the
opening's centre, the head is the lower of two circular arcs whose centres sit on the springing line
at `±half·k` (`k ≈ 0.55` gives the reference's proportion — a lancet, not a wide Tudor arch):

```
r      = half·(1 + k)
y_arc  = -springing - √(max(0, r² - (dp + half·k)²))   # arc struck from the FAR centre
```

Taking the far-centre arc for each side and meeting them at `dp = 0` produces the apex. The same
function serves arcade, triforium, clerestory and apse lancets at different `half`/`springing`.

### The vault

Per bay (bay index from the along-hall coordinate), in the vault's own `(u, along)` space:
- **diagonal ribs**: `|u| ≈ ±(bay-local along)` — two lines crossing at the bay centre → the boss.
- **transverse ribs**: a band at each bay boundary.
- **webs**: the infill, one `limestone` step lighter than the ribs so ribs read as raised.
- A **ridge rib** running the length of the ceiling ties the bosses into a chain — the receding
  sequence of Xs that carries the depth.

### Compound piers

At a pier's `dp`, quantise into `N` colonnettes; within each, shade as a half-cylinder
(`cos` across its width) off the ramp, with a darker seam between. This is what turns a flat face
into a *bundle of shafts*, and it is cheap: one modulo and one cosine.

## The Contract Board's wall (R239) — and its risk

`gen_structure.stone_px` is re-authored from `limestone` instead of the cool `stone` ramp; the
normal map is unchanged in shape, only the diffuse re-tones.

**This is the one part of this spec that can regress shipped work**, and it must be treated as such.
The board's look was tuned across TD-047/048/050 against a *cool, dark* wall: the torch halos read
because warm light lands on cool stone. Warming the wall reduces that separation, and could flatten
the very lighting the board is built on. So:

- capture the board **before** and **after**;
- recompute **L1** explicitly (INK `#2A2115` on the parchment floor tone `#CBB583` = **7.90:1**
  today) and state the number — the parchment is unchanged, so this should hold, but it is asserted
  rather than assumed;
- run `--lights-off` to confirm the torch rig is still what lights the scene;
- if the halos stop reading, **tone the wall back** toward the cool ramp until they do. The menu does
  not get to cost the board its lighting (P127).

## Correctness Properties

- **P127 (no silent regression, R239):** `limestone` is additive; the cool `stone` ramp survives for
  the field tiles and anything not named. The board's measured legibility and lit read are
  re-verified after the re-tone, and a failure reverts the wall rather than lowering the bar.

## Files touched

Edited: `client/assets/ui/ashember.py` (new ramps), `client/assets/ui/gen_nave.py` (the rebuild),
`client/assets/ui/gen_structure.py` (`stone_px` re-tone), `client/assets/ui/gen_normals.py` if the
stone normal needs re-deriving. Regenerated: `assets/ui/title/nave.png`,
`assets/ui/board/stone_tile{,_n}.png`. New: `specs/nave-cathedral/*`. Docs: DECISION_LOG (TD-072),
CLAUDE.md, `docs/technical/asset-map.md`. No `src/**` change, no client-script change beyond what the
re-tone forces.
