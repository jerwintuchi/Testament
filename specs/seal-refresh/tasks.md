# Tasks — Seal refresh (TD-065)

> T# continues global from T221 (seal-polish). Client render only — author playtest for the
> interactive items + `--board-preview` captures for regression. Order: robust cooldown (small,
> fixes the stuck bug), then the targeted reader refresh (fixes the stutter).

- [x] T222 [R212 / P121 / V2] — **Robust cooldown.** Click handler: hard time-guard (`return` if
      within the window) then set `_seal_cooldown_until` + send. `_seal_block`: `stamp.disabled =
      (not leader) or cooling`; when cooling, an unconditional buffered re-enable timer
      (`cool_left/1000 + 0.08`, `is_instance_valid` only — no deadline recheck).
      Test: **V2** — author playtest: seal re-stampable after ~0.9 s with no reopen; rapid clicks
      fire once per window.

- [x] T223 [R211 / P120 / V1] — **Targeted reader refresh.** Wrap the reader's dim + row in a
      `ReaderOverlay` `Control`; store `_board_canvas` in `_build_contract_board`; add
      `_refresh_open_reader()` (free the overlay, re-show the reader only); route
      `LOBBY_UPDATED` (WAITING, board open, reader open) to it instead of `_rebuild_popup_body`.
      Test: **V1** — author playtest: stamp/lift smooth, seal animates, banner fires, scroll stays;
      a `--reader --sealed` capture still renders correctly; the board is unchanged.

- [x] T224 [R211–R213 / V3] — **Verification pass.** V1–V3; asset-map `--check`; suites
      untouched-green; diff scope; refresh the board preview artifact; append DECISION_LOG TD-065;
      swap the active spec in CLAUDE.md.
