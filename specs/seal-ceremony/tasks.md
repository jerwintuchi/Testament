# Tasks — The seal ceremony (TD-063)

> T# continues global from T212 (seal-rite). Client render + generated art only — tests are
> `--board-preview` captures + author playtest for motion. Order: the wax art first (the socket and
> the press frame it), then the socket, then the press, then the banner, then verify.

- [x] T213 [R202 / V1] — **Pressed pixel wax.** Rewrite `make_collegium_seal`: SS=1, centred disc,
      deformed rim (3 seeded squeeze lobes + per-angle jitter + pressed-ellipse bias), raised
      bulge band over a pressed field, debossed device with lit lip, 4-band posterized shading,
      hard-stepped contact shadow. Re-emit + headless-import `seal_collegium.png`.
      Test: **V1** — `--sealed` reader capture: irregular pressed rim, banded shading, device
      legible; no smooth painterly gradients.

- [x] T214 [R203 / V2] — **The empty socket.** `wax_seal.gd` faint = a centred dashed circle only
      (12 arcs, alpha ≈0.30, width 1.5) — the ghost wax texture gone; firm unchanged.
      `_seal_block` modulate bookkeeping simplified (dash carries its own opacity).
      Test: **V2** — unsealed reader capture: only the dashed circle, centred, low-opacity.

- [x] T215 [R204 / P116 / V3] — **The slow heavy press.** Rework `_animate_seal`: hover 0.10s →
      drop 0.30s (CUBIC EASE_IN) → squash (1.22, 0.80) 0.09s → BACK settle 0.28s; flash re-parented
      to the SEAL (`show_behind_parent`), blooming at impact; the sheet-thump removed; lift slowed
      to 0.28s.
      Test: **V3** — author playtest (weight); static: unsealed vs sealed captures show identical
      caption geometry (nothing displaced).

- [x] T216 [R205 / P117 / V4] — **CONTRACT SEALED.** `_show_rite_banner(title, sub)` (dark band +
      gilt letter-spaced Cinzel title + target subline; fade-hold-fade ≈2.2s; reduced-motion
      static); `CONTRACT_SELECTION accepted=true` → banner party-wide, stamp toast removed;
      `accepted=false` → existing lift toast; `--rite-banner` debug preview.
      Test: **V4** — `--rite-banner` capture shows the banner over the board; author playtest:
      both clients see it on a stamp, no stamp toast, lift toast intact.

- [x] T217 [R202–R206 / V5] — **Verification pass.** V1–V5; asset-map `--check`; suites
      untouched-green; diff scope; refresh the board preview artifact; append DECISION_LOG TD-063;
      swap the active spec in CLAUDE.md.
