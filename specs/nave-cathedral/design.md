# Design — The nave re-authored as High Gothic (TD-072)

> Satisfies R235–R240. Client render + generated art. Verified by capture.

---

## Withdrawn: the derived "limestone" palette

The first draft of this spec measured a palette off the reference photograph (k-means over 24k
samples, per-region percentile sampling, hue-bucketed glass) and proposed re-toning the Contract
Board's wall to match. **Both halves of that are withdrawn**, on the author's clarification that the
reference supplies *angle and structure only*.

It was wrong twice, and the reasons are worth keeping so the mistake is not repeated:

1. **Wrong source of truth.** The look is governed by `docs/art.md` — warm, weathered, aged,
   *dramatically torch-lit*, in the Prototype v1 idiom. A photograph of a real cathedral at midday is
   not that: Chartres is a **daylight** building whose drama is sun through glass. Ours is a
   **firelit** one. Copying its light would have quietly replaced the game's register with a
   photograph's.
2. **Wrong direction of propagation.** `docs/art.md` states the Notice Board is the canonical worked
   example and that *its* register propagates to the HUD and menus. Pushing a menu backdrop's palette
   into the board reverses the one flow the bible names — and would have put shipped, tuned work
   (TD-047/048/050) at risk for a screen that had not been built yet.

What survives from the measurement is one *observation*, not a palette: the far arcade in the
reference is **lighter** than the near (`#D0988F` vs `#150B03`), i.e. depth reads as luminance
contrast. The TD-071 nave has this backwards — it darkens with distance uniformly. That is a
**structural** lesson about how depth is drawn, so it is kept (R238); the hex values are not.

## Geometry — what changes

The TD-071 corridor projection (`_resolve`: ray-cast each pixel to floor / vault / wall / far wall
with depth `t`) is **kept** — it is what made the bays converge, and it generalises to the storeys.
What changes is what is drawn on those surfaces, and where the camera stands.

| Element | Now (Romanesque) | Target (Gothic) |
|---|---|---|
| Arch heads | semicircle | **two-centred pointed** arcs meeting at an apex |
| Vault | flat near-black, faint rib hint | **quadripartite**: diagonals crossing at a boss per bay + transverse ribs + lighter webs + a ridge rib |
| Piers | flat rectangular face | **compound**: core + engaged colonnettes shaded as half-rounds, capitals at springing |
| Storeys | one | **three**: arcade / triforium / clerestory |
| Camera | `VPY = 0.545` | **`VPY ≈ 0.66`** — the viewer looks up; the vault takes the upper half |
| Light | one pale daylight shaft, no fire | **fire is the key** (braziers, warm falloff); the cold shaft becomes the accent |

### The pointed arch

One function replaces the semicircle and serves every tier at different `half`/`springing`. For bay
coordinate `dp ∈ [0, half]` from the opening's centre, the head is a circular arc struck from the
*opposite* springing point, so the two arcs meet at an apex:

```
r      = half·(1 + k)                                  # k ≈ 0.55 → a lancet, not a wide Tudor arch
y_head = -springing - √(max(0, r² - (dp + half·k)²))
```

### The vault

Per bay, in the vault's own `(u, along)` space: **diagonal ribs** where `|u| ≈ ±(bay-local along)`,
crossing at the bay centre → the boss; **transverse ribs** as a band at each bay boundary; **webs**
one ramp step lighter than the ribs so the ribs read raised; a **ridge rib** down the centre tying
the bosses into the receding chain that carries the depth.

### Compound piers

Quantise a pier's `dp` into `N` colonnettes; shade each as a half-cylinder (`cos` across its width)
off the `stone` ramp, with a darker seam between and a capital band at the springing. One modulo and
one cosine turns a flat face into a bundle of shafts.

### Light (R236) — the part the bible governs

- **Braziers** stand in the aisles at bay intervals: warm, local, with `1/d²`-ish falloff off the
  `flame`/`gold` ramps. Nearer braziers are brighter and larger, so they also carry depth.
- Their light lands on **cool-shadowed** `stone`, which is the same warm-on-cool contrast that makes
  the board's torch halos read — the register is inherited, not re-invented.
- **One cold shaft** from a high lancet remains as the counterpoint TD-043 asks for, but dimmer than
  the fire and no longer the source of the image.
- **One light direction**: cast shadows from piers and the vault ribs all trace to the braziers
  (bible rule 4).
- Ordered 4×4 dithering (TD-071) stays: a smooth falloff over a stepped ramp bands into contour
  rings without it.

## Correctness Properties

- **P127 (the register propagates one way):** the menu inherits the board's ramps and lighting
  language; no board asset changes. Any future board re-tone is its own spec with its own measured
  legibility check.

## Files touched

Edited: `client/assets/ui/gen_nave.py` (the rebuild). Regenerated: `assets/ui/title/nave.png`.
New: `specs/nave-cathedral/*`. Docs: DECISION_LOG (TD-072), CLAUDE.md,
`docs/technical/asset-map.md`. **No** `ashember.py` ramp additions, **no** board asset, **no**
`src/**` change.
