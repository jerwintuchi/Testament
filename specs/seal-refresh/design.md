# Design — Seal refresh (TD-065)

> Satisfies R211–R213. Client render only. Verified by author playtest + captures.

---

## R211 — refresh only the open reader

The reader overlay (dim + the centred reader row) is wrapped in a single named container so it can
be found and replaced without touching the board:

- `_show_notice_reader` adds its `dim` + `cc` under one `Control` named **`ReaderOverlay`** (full
  rect, `MOUSE_FILTER_IGNORE` so the dim still catches clicks and the reader still reads); the
  container is added to the board `canvas`. `_build_contract_board` stores the canvas in a member
  `_board_canvas` so the refresh can find the overlay.
- `_refresh_open_reader()`: if `_board_canvas` is valid and `_board_selection` is non-empty, free
  the existing `ReaderOverlay` and call `_show_notice_reader(_board_canvas, _board_selection)` again
  — rebuilding only the ~30-node reader subtree (fresh seal state from `_snapshot.contract`,
  animation via the `_seal_prev` flip, scroll restored via `_reader_open_cid`/`_reader_scroll_mem`).
  The board notices, backing, decay, and **torches are untouched** — `add_torches` is never called,
  which is what removes the hitch (its CPUParticles + sprite churn was the bulk of the cost).
- `_on_message` `LOBBY_UPDATED` (WAITING, board open): if `_board_selection` is non-empty (a notice
  is open — the only state a stamp happens in) call `_refresh_open_reader()`; else keep the full
  `_rebuild_popup_body()` (grid view — a ready-toggle/join, no animation in flight).

`_board_selection` (the open notice's intel) is unchanged by a stamp (target/site/etc. are static);
the seal state is read live from `_snapshot.contract`, so no intel re-fetch is needed.

## R212 — the robust cooldown

Two independent guarantees replace the fragile deadline recheck:

- **Spam prevention (hard, in the click handler):** `if Time.get_ticks_msec() < _seal_cooldown_until:
  return` — a click during the window sends nothing. This is independent of the button's disabled
  state, so it can neither be defeated nor stick. On a live click it sets
  `_seal_cooldown_until = now + SEAL_COOLDOWN_MS` and sends the intent.
- **Visual disable (soft, always re-enables):** in `_seal_block`, `stamp.disabled = (not leader) or
  cooling`; when `cooling`, a `create_timer(cool_left/1000 + 0.08)` re-enables the button
  **unconditionally** (no `>= _seal_cooldown_until` recheck — that off-by-a-frame miss is the
  original stuck bug), guarded only by `is_instance_valid`. The +0.08 s buffer guarantees the timer
  outlasts the deadline.

Because the stamp now goes through `_refresh_open_reader`, the seal block IS rebuilt on each stamp
(so the visual disable + its re-enable timer are created every time), and the click-handler guard is
the real lock — belt and suspenders, no stuck state possible.

## Correctness Properties

- **P120 (targeted refresh, R211):** a stamp/lift rebuilds only the reader overlay subtree; the
  board decor (notices, torches, backing, decay) is not recreated — no `add_torches` call, no hitch;
  seal state, animation, banner, and scroll continuity all preserved.
- **P121 (lockout can't stick or leak, R212):** the spam guard is a pure time comparison in the
  click handler (no state to get stuck); the visual disable always re-enables via an unconditional
  buffered timer; the server remains the authority (P66).

## Files touched

Edited: `client/scripts/main.gd` (`ReaderOverlay` wrapper; `_board_canvas`; `_refresh_open_reader`;
`LOBBY_UPDATED` route; robust cooldown in `_seal_block` + click handler), `docs/DECISION_LOG.md`
(TD-065), `CLAUDE.md` (active spec). New: `specs/seal-refresh/*`. No `src/**` change.
