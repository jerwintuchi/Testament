# Design — take-down/return without rebuilding the board (TD-068)

> Satisfies R221–R223. Client render only. Verified by captures + the `board live=` build counter.

---

## Why the rebuild was there

`_select_board_card(c)` set `_board_selection` and then cross-faded into a full
`_rebuild_popup_body()` → `_clear_popup_body()` + `_build_contract_board()`. That was the simplest
correct thing when the reader was just "another view of the popup body", and TD-065 already carved
the **stamp** out of it (`_refresh_open_reader`, P120) while explicitly leaving open/close alone.

What the rebuild actually redoes, on every take-down and every return:

- a fresh canvas + plank `NinePatchRect` with a new `ShaderMaterial`,
- `BoardGeo.layout_live` + **`_fit_writ` per writ** (font metrics, wrap measuring, step-down search),
- 8 × (`backlight` gradient + cast shadow + `_make_live_notice` subtree),
- the decay props, the vignette, the legend bar, the placard,
- **`add_torches`** — new `CPUParticles2D` flames.

## The insight

`_board_selection` reaches the board in exactly **two** places:

1. `_build_contract_board` line ~1367: `if not _board_selection.is_empty(): _show_notice_reader(…)`.
2. `_make_live_notice`: `var sel := …`, used for `if sel: card.rotation_degrees = 0.0` and the
   `mouse_exited` rest scale.

(1) is the overlay itself. (2) is **inert**: the "taken-down writ hangs straight" is overwritten two
lines later by the placement `node.rotation_degrees = tilt`, and the 1.03 rest scale cannot fire
while the reader's dim owns the mouse. So a rebuild always yields *seeded lean, scale 1.0* — which
is precisely what the fast path must reproduce. (Left as-is deliberately: making the straighten
work would be a **visible change**, out of scope here. Noted for a future look.)

Everything else the rebuild produces is a pure function of the snapshot + viewport, both unchanged
by a selection. So the board is redundant work, and the reader is already a self-contained
`ReaderOverlay` (TD-065 built it that way).

## The change — `_select_board_card`

```
set _board_selection (+ clear scroll/seal memory on close, unchanged)
if popup is not the board, or _board_canvas is gone → old full-rebuild cross-fade   (fallback)
find the existing ReaderOverlay
_reset_notice_transforms()                       # leave the writs as a rebuild would
close: _retire_reader_overlay(old); _focus_first_notice.call_deferred()
open : old.free() if any; ov = _show_notice_reader(...); fade ov 0→1 over 0.12s
```

`_show_notice_reader` now **returns** its overlay so callers need not re-find it.

### Supporting helpers

- **`_reset_notice_transforms()`** — for every `live_notice`: kill its hover tween, restore
  `rotation_degrees` from a new **`tilt` meta** stamped at placement, and reset `scale` to 1. Needed
  because a card is hover-lifted (1.05) at the instant it is clicked and the old path threw that
  node away; the surviving node must be put back.
- **`_retire_reader_overlay(ov)`** — renames it `ReaderOverlayClosing` and makes it + its children
  `MOUSE_FILTER_IGNORE`, then fades and `queue_free`s. The rename keeps a dying overlay from being
  returned by the next `find_child("ReaderOverlay")`; the filter keeps its dim (which `STOP`s mouse)
  from swallowing a board click during the 0.07s fade.
- **`_hover_card`** now stores its tween in a `hover_tween` meta and kills the previous one, so an
  in-flight lift cannot animate over the direct scale write (and two fast re-hovers stop fighting).

### Debug

`-- --reader-cycle` takes the fixture writ down, waits 20 frames, returns it, then makes the writs
`MOUSE_FILTER_IGNORE` (the window pops under the OS cursor and stray physical clicks kept re-opening
a writ before the capture fired — the known preview gotcha). One run proves both transitions.

## Correctness Properties

- **P123 (smallest subtree, R221/R222):** open/close mutates only the `ReaderOverlay` plus the live
  writs' transforms. The board subtree is not freed, rebuilt, or re-measured, and no generator or
  particle system re-runs — while the *observable* result is identical to the rebuild's (seeded
  lean, rest scale, focus on the wall). Canon: S6, and the TD-065 stamp lesson generalized.

## Files touched

Edited: `client/scripts/main.gd` (`_select_board_card`, `_show_notice_reader` return, `_hover_card`,
the placement `tilt` meta, `_board_preview`), `docs/technical/asset-map.md` (regenerated),
`docs/DECISION_LOG.md` (TD-068), `CLAUDE.md`. New: `specs/reader-swap/*`. No `src/**` change.
