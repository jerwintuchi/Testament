# Tasks — The nave re-authored as High Gothic (TD-072)

> T# continues global from T248. Client render + generated art; the named test is a capture.
> **Revised before implementation**: the derived-limestone task and the board wall re-tone are
> withdrawn (see design.md § Withdrawn) — the nave inherits the board's register instead, which also
> removes the only part of this spec that could have regressed shipped work.

- [ ] T249 [R235, R236 / V1] — **Register + light.** Author the nave from the **existing** Ash &
      Ember ramps (no additions); make **fire the key** — braziers at bay intervals with warm falloff
      off `flame`/`gold`, landing on cool-shadowed `stone` — and demote the pale shaft to the cold
      counterpoint. One light direction; every cast shadow traces to a brazier in frame.
      Test: **V1** — `assert_on_palette` passes with no ramp additions; capture shows fire as key,
      deep shadow dominant, warm-on-cool separation visible.

- [ ] T250 [R237 / V2] — **Pointed arches + three storeys.** Two-centred lancet head
      (`r = half·(1+k)`, `k ≈ 0.55`) replacing the semicircle, driving arcade / triforium /
      clerestory / apse lancets from one function at different `half`/`springing`.
      Test: **V2** — capture shows pointed heads at every tier and three tiers of diminishing
      openings.

- [ ] T251 [R237, R238 / V2] — **Ribbed vault, compound piers, the low camera.** Quadripartite vault
      (diagonals → boss per bay, transverse ribs, lighter webs, ridge rib); piers become bundles of
      half-round colonnettes with capitals; `VPY` → ≈0.66 so the vault owns the upper half; depth
      reads as luminance contrast rather than uniform darkening.
      Test: **V2** — capture shows the receding chain of vault Xs and shafted piers, vault above the
      halfway line; re-captured at 1920×1080 for integer-scale centring.

- [ ] T252 [R238 / V3] — **Backdrop discipline.** Keep the frame's centre quiet enough that the gilt
      title and all four options stay legible over the plate.
      Test: **V3** — `--title-preview` capture; title + options read.

- [ ] T253 [R239, R240 / V4, V5] — **Verify + land.** Board capture **unchanged** and `git diff`
      touching no board asset; headless parse clean; asset-map `--selftest` + `--check`; suites
      green; DECISION_LOG TD-072 (including the withdrawn palette and why); CLAUDE.md.

## Notes

- The TD-071 corridor projection (`_resolve`) is **kept** — it is what made the bays converge and it
  generalises to the new storeys. What changes is what is drawn on those surfaces.
- The reference's **chairs are deliberately not reproduced**: the brief is an empty, timeless space,
  and furniture both clutters the frame and dates it.
- Ordered dithering (TD-071) stays.
