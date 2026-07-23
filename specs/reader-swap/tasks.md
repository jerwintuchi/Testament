# Tasks — take-down/return without rebuilding the board (TD-068)

> T# continues global from T231 (main-decompose, queued). Client render only; the named test is a
> `--board-preview` capture plus the `board live=` build counter in the client log.

- [x] T232 [R221 / P123 / V1] — **Swap the overlay instead of rebuilding.** `_select_board_card`
      gains the fast path: free/retire the `ReaderOverlay` and re-show it in place, keeping the
      board subtree; a non-board popup or a missing `_board_canvas` still falls back to
      `_rebuild_popup_body`. `_show_notice_reader` returns its overlay.
      Test: **V1** — `--board-preview --reader` logs `board live=` **once** (was twice).

- [x] T233 [R222 / P123 / V2] — **Leave the wall as the rebuild left it.** Stamp a `tilt` meta at
      placement; `_reset_notice_transforms()` restores lean + scale and kills the hover tween (which
      `_hover_card` now tracks in a meta), so the clicked writ does not stay hover-swollen. Retire a
      closing overlay safely (rename + click-through) and restore focus via `_focus_first_notice`.
      Fades move onto the overlay alone (0.12s in / 0.07s out).
      Test: **V2** — a `--reader` capture is identical to a stashed pre-change build **inside the
      sheet** (0 differing px; all 14,073 differing px lie in the two torch gutters, x<160 / x>1120,
      which the flame particles vary run to run). A `--reader-cycle` capture shows the wall intact
      after the return: eight writs at their leans, none swollen, reticle on the first writ.

- [x] T234 [R221 / V1] — **`--reader-cycle` debug flag.** Opens then closes the fixture writ in one
      unattended run, then makes the writs click-through so the stray-click preview gotcha cannot
      re-open one before the capture.
      Test: **V1** — `--board-preview --reader-cycle` logs `board live=` **once** for a run
      containing both a take-down and a return, and `reader cycle complete`.

- [x] T235 [R223 / V3] — **Verify + land.** Headless parse clean; asset-map regenerated + `--check`;
      `git diff` scoped `client/ specs/ docs/`; server + shared suites green (untouched); commit;
      append DECISION_LOG TD-068; note the spec in CLAUDE.md.

## Notes

- The inert `if sel: card.rotation_degrees = 0.0` in `_make_live_notice` (overwritten by the
  placement `rotation_degrees = tilt` immediately below) is **left alone on purpose** — making the
  "taken-down writ hangs straight" actually work is a visible change, not this spec's business.
  Worth a deliberate decision later.
- The same fast-path shape is what `board/notice_reader.gd` (T230, R218) should inherit when the
  reader is extracted — that extraction must preserve P123, not re-introduce the rebuild.
