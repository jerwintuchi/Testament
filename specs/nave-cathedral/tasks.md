# Tasks — The nave re-authored as High Gothic (TD-072)

> T# continues global from T248 (menu-lobby Phase D). Client render + generated art; the named test
> is a capture, plus a **measured** contrast number where shipped work is at risk (T253). Staged so
> the nave lands before the board's wall is touched — the risky change goes last and alone.

## Phase A — The palette

- [ ] T249 [R235 / V1] — **`limestone` + friends into `ashember.py`.** Add the six ramps derived from
      the reference (`limestone`, `vaultstone`, `apse`, `glass_cobalt`, `glass_ruby`, `glass_amber`),
      leaving the cool `stone` ramp in place for the field tiles and everything not named here.
      Test: **V1** — `python3 ashember.py` self-test green (ramps distinct, `quantize` identity on
      the new locked colours, a quantized gradient 100% on-palette).

## Phase B — The nave

- [ ] T250 [R236 / V2] — **Pointed arches + three storeys.** Replace the semicircular head with the
      two-centred lancet (`r = half·(1+k)`, `k ≈ 0.55`), and drive arcade / triforium / clerestory /
      apse lancets from the same function at different `half`/`springing`.
      Test: **V2** — capture shows pointed heads at every tier and three tiers of diminishing
      openings.

- [ ] T251 [R236, R237 / V2] — **Ribbed vault + compound piers + the low camera.** Quadripartite
      vault (diagonals crossing at a boss per bay, transverse ribs, lighter webs, a ridge rib tying
      the bosses); piers become bundles of half-round colonnettes with capitals; `VPY` drops to
      ≈0.66 so the vault owns the upper half.
      Test: **V2** — capture shows the receding chain of vault Xs and shafted piers, with the vault
      above the halfway line; re-captured at 1920×1080 for the integer-scale centring.

- [ ] T252 [R238 / V3] — **Light does the work.** Jewel windows (cobalt/ruby/amber) saturated against
      desaturated stone, casting a faint coloured wash; depth reads as luminance — near piers
      darkest, far arcade brightening to a lit apse. Keep the frame's centre quiet enough that the
      gilt title and options stay legible.
      Test: **V3** — capture; the title and all four options read over the plate.

## Phase C — The Collegium's wall (own commit; the risky one)

- [ ] T253 [R239 / P127 / V4] — **Re-tone `stone_tile` to `limestone`.** Re-author
      `gen_structure.stone_px` off the warm ramp; re-derive the normal if needed.
      Test: **V4** — board captures **before and after**; **L1 recomputed and stated numerically**
      (INK `#2A2115` on `#CBB583` = 7.90:1 today; the parchment is untouched so this should hold, but
      it is asserted, not assumed); `--lights-off` still proves the torch rig lights the scene. **If
      the halos stop reading against warm stone, tone the wall back** — the board is shipped work and
      does not regress for the menu's benefit.

## Cross-cutting

- [ ] T254 [R240 / V5] — **Verify + land.** Headless parse clean; V1–V4; regenerate asset-map +
      `--selftest` + `--check`; `git diff` scoped `client/ specs/ docs/`; server + shared suites
      green; DECISION_LOG TD-072; CLAUDE.md.

## Notes

- The TD-071 corridor projection (`_resolve`) is **kept** — it is what made the bays converge, and it
  generalises to the new storeys. What changes is what is drawn on those surfaces, not how depth is
  computed.
- The reference's **chairs are deliberately not reproduced**: the brief is an empty, timeless space,
  and furniture both clutters the frame and dates it.
- Ordered dithering (TD-071) stays: any smooth falloff over a stepped ramp bands into contour rings
  without it.
