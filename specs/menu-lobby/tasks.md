# Tasks — Main menu + lobby, production presentation (TD-071)

> T# continues global from T235 (reader-swap). Client render + input only; the named test is a
> capture (client-spec convention — no GDScript unit harness). Staged commits, in dependency order.
> Menu treatment: **diegetic-lite**, settled by the author. Phase A landed first.

## Phase A — Wording + correctness (own commit)

- [x] T236 [R224 / P125 / V1] — **`core/station_names.gd`.** Move `_STATION_LABEL` out of `main.gd`
      into a preloaded `RefCounted` (`StationNames.of(kind)`, unknown → raw value); consume it from
      `main.gd`'s `_prompt` **and** from `world/space_view.gd:_place_markers`, which prints the raw
      enum today.
      Test: **V1** — a `--lobby-preview` capture shows **"Deploy Gate"**, "Contract Board" and
      "Quartermaster" on the world markers (was `DEPLOY_GATE`). `_popup_title` reads the same table,
      so it moved too. **Done.**

- [x] T237 [R226 / V1] — **Retire instruction scaffolding.** Delete the three standing "Walk to the
      … press E" lines and the menu tagline. The contextual `_prompt` is the only instruction.
      Test: **V1** — the `--lobby-preview` capture carries no standing instruction line and the menu
      no tagline; `_prompt` is untouched. **Done.** (The lobby's "share the code aloud" line survives
      into Phase C, which replaces the whole lobby body with the scroll — R229 obsoletes it.)

- [x] T238 [R225 / V2] — **Identity, not role.** Drop the `"Seeker"` default for an empty field with
      a `your name` placeholder; persist to `user://display-name.txt`; refuse Create/Join on an empty
      name with an inline hint and **send nothing**.
      Test: **V2** — a capture with no saved name shows the empty `your name` placeholder; seeding
      `user://display-name.txt` and relaunching restores it (round-trip captured). **Done.** The
      empty-name refusal is verified **by inspection, not capture**: `_claim_name()` returns before
      any `_net.send_message`, and clicking it unattended would need input injection the capture
      harness does not have.

## Phase B — The menu (own commit) — treatment: **diegetic-lite** (settled)

- [x] T239 [R227 / V3] — **Rebuild `_show_menu`** diegetic-lite: `panel.png` + Cinzel + stone
      surround + the existing torch rig, shipped art only. Group identity / create / join; separate Resume; move connection state to a quiet
      corner indicator. Add `--menu-preview` for capture.
      Test: **V3** — `--menu-preview` (seeds a fake reconnect token so the Resume block, which only
      exists when there is something to return to, is capturable) shows the carved TESTAMENT plate on
      lit masonry, grouped identity/create/join, Resume set apart, and `connected` quiet in the
      corner. Re-captured at **1920×1080** (logical 952×520): proportional, no clipping, no
      scrollbar. **Done.** Two things the first capture caught — the plate overflowed 360 logical px
      (Resume clipped, scrollbar showing) and the controls used the theme default ~17px font, which
      towers in a 640×360 space; fixed by `MENU_FS = 11` and a tighter top spacer.

## Phase C — The room scroll (own commit)

- [ ] T240 [R228 / P124 / V4] — **`ui/room_scroll.gd`.** Node-owning component (canon S3.1) with
      `refresh(snapshot, self_id)` / `set_open` / `toggle` and
      `ready_toggled`/`leave_pressed`/`kick_requested` signals. Closed = pinned tab with ready pips;
      open = parchment panel with code, roster (leader ★, "you", disconnected, ready pip), Ready,
      Leave, and the leader's Kick. Toggled by Tab (guarded by `not _menu_open`) and by clicking the
      tab. It never touches `_net`.
      Test: **V4** — `--lobby-preview` (added early in Phase A, since V1 needed a lobby capture and
      no server/input is available unattended) captures closed (world unobstructed, pips legible) and open
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

## Phase D — The title screen (own commit)

- [x] T244 [R231 / V6] — **`gen_nave.py` → `assets/ui/title/nave.png`.** The empty nave, generated
      at 640×360: a real one-point corridor projection (every pixel ray-cast to floor / vault /
      arcade / far wall with a depth `t`), an arcade of arched bays, worn flags, one leaning daylight
      shaft, one candle. No figure of any kind.
      Test: **V6** — `assert_on_palette` passes; the plate was iterated against captures. Two
      rejected drafts are worth recording: a *vertical* shaft read as a flame or a laser rather than
      light, and flat vertical piers read as a fence — the corridor projection is what made the bays
      converge. Ordered 4×4 dithering was needed because a 5-step stone ramp turns a smooth falloff
      into visible contour rings.

- [x] T245 [R232 / P126 / V6, V7] — **`_show_title`.** `Screen.TITLE` added and booted into; gilt
      Cinzel options with no button chrome; **no** name field, code field, or status line. `Return to
      your expedition` is listed first and **only** when a token exists.
      Test: **V7** — `--title-preview` shows four options, `--title-preview --no-token` shows three.
      `--no-token` clears a real saved token, not just the seeded one (the first version showed
      Return anyway because a live `reconnect-token.txt` was on disk).

- [x] T246 [R231 / V6] — **Integer-scale the plate.** `_fit_nave()` sizes it to the largest integer
      multiple that fits and centres it, with `_nave_bg` filling the remainder in the plate's own
      black; re-fit on viewport resize.
      Test: **V6** — at 1920×1080 (logical 952×520) the plate draws at 1× centred with crisp pixels.
      The first version used `STRETCH_KEEP_ASPECT_CENTERED`, which scaled 1.44× and softened the
      pixel grid the whole project is built on.

- [x] T247 [R233 / V7] — **Room setup, one screen deeper.** `_show_room_setup(mode)`: **New
      Expedition** asks for a name only, **Join Expedition** for name + Room code; both reuse the
      Phase B plate and lit masonry, both offer **Back**. Debug: `--setup-create`, `--setup-join`.
      Test: **V7** — both plates captured; the R225 empty-name/empty-code guards still hold.

- [x] T248 [R234 / V8] — **Hall of Petitions** enters `docs/GLOSSARY.md` with a DECISION_LOG note.
      Test: **V8** — the entry is present. (Using the name *in game* lands with Phase C, which
      rebuilds the lobby body.)
