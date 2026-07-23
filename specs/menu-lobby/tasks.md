# Tasks — Main menu + lobby, production presentation (TD-071)

> T# continues global from T235 (reader-swap). Client render + input only; the named test is a
> capture (client-spec convention — no GDScript unit harness). Staged commits, in dependency order.
> **Phase B (T239) is blocked on the author's menu-treatment choice** (see design.md OPEN DECISION);
> Phases A and C do not depend on it and go first.

## Phase A — Wording + correctness (own commit)

- [ ] T236 [R224 / P125 / V1] — **`core/station_names.gd`.** Move `_STATION_LABEL` out of `main.gd`
      into a preloaded `RefCounted` (`StationNames.of(kind)`, unknown → raw value); consume it from
      `main.gd`'s `_prompt` **and** from `world/space_view.gd:_place_markers`, which prints the raw
      enum today.
      Test: **V1** — a lobby capture shows "Deploy Gate" on the world marker; `Press E: Deploy Gate`
      still appears in range.

- [ ] T237 [R226 / V1] — **Retire instruction scaffolding.** Delete the three standing "Walk to the
      … press E" lines and the menu tagline. The contextual `_prompt` is the only instruction.
      Test: **V1** — lobby + deploying + field captures carry no standing instruction line; the
      proximity prompt still shows.

- [ ] T238 [R225 / V2] — **Identity, not role.** Drop the `"Seeker"` default for an empty field with
      a `your name` placeholder; persist to `user://display-name.txt`; refuse Create/Join on an empty
      name with an inline hint and **send nothing**.
      Test: **V2** — first launch shows the empty placeholder; Create with an empty name sends no
      message (log-verified) and hints; a relaunch restores the typed name.

## Phase B — The menu (own commit; BLOCKED on the treatment choice)

- [ ] T239 [R227 / V3] — **Rebuild `_show_menu`** in the chosen treatment (recommendation:
      diegetic-lite — `panel.png` + Cinzel + stone surround + the existing torch rig, shipped art
      only). Group identity / create / join; separate Resume; move connection state to a quiet
      corner indicator. Add `--menu-preview` for capture.
      Test: **V3** — `--menu-preview` capture shows the themed menu, no tagline, grouped controls,
      no overlap; re-captured at a second integer scale to prove the layout holds.

## Phase C — The room scroll (own commit)

- [ ] T240 [R228 / P124 / V4] — **`ui/room_scroll.gd`.** Node-owning component (canon S3.1) with
      `refresh(snapshot, self_id)` / `set_open` / `toggle` and
      `ready_toggled`/`leave_pressed`/`kick_requested` signals. Closed = pinned tab with ready pips;
      open = parchment panel with code, roster (leader ★, "you", disconnected, ready pip), Ready,
      Leave, and the leader's Kick. Toggled by Tab (guarded by `not _menu_open`) and by clicking the
      tab. It never touches `_net`.
      Test: **V4** — `--lobby-preview` captures closed (world unobstructed, pips legible) and open
      (all fields); toggling logs nothing sent (P124).

- [ ] T241 [R228 / V4] — **Wire it into `main.gd`.** `_show_lobby` stops emitting bare labels and
      buttons; it instances the scroll, calls `refresh()` on each `LOBBY_UPDATED`, and forwards the
      three signals to the existing `TOGGLE_READY`/`LEAVE_ROOM`/`KICK_PLAYER` intents.
      Test: **V4** — two clients: readying on one updates the other's pips; Leave returns to menu;
      the leader can still kick a disconnected player.

- [ ] T242 [R229 / V4] — **Copy the code.** Large letter-spaced code + a Copy control
      (`DisplayServer.clipboard_set`) confirmed by the existing toast.
      Test: **V4** — clicking Copy toasts and the clipboard holds the code.

## Cross-cutting

- [ ] T243 [R230 / V5] — **Verify + land.** Headless parse clean; V1–V4 captures; regenerate
      asset-map + `--check` + `--selftest`; `git diff` scoped `client/ specs/ docs/`; server + shared
      suites green (untouched); DECISION_LOG TD-071; CLAUDE.md active spec.

## Notes

- Nothing here changes the wire. Ready/Leave/Kick keep their existing intents and the server stays
  authoritative — the scroll is presentation (P124).
- `room_scroll.gd` is a **new** feature and therefore starts in its own file, never inside `main.gd`
  (canon S5). It should be built to survive TD-067's remaining tranches unchanged.
- The full painted title plate (a carved TESTAMENT sign via `gen_header`'s idiom) is deliberately
  **out of scope** — it needs a generator task and belongs to its own spec.
