# Tasks — Entering an expedition (TD-080)

> T# continues global from T304. Client render + routing; no `src/**` change.

- [x] T305 [R287, P140 / V1] — **New Expedition stops being a screen.** It sends `CREATE_ROOM` from
      the title and the player lands in the walkable Collegium. Mostly a deletion: `ROOM_CREATED`
      already routed to the lobby and the lobby already *is* the Collegium.
      Test: **V1, against a live server** — `--new-expedition` reaches
      `phase=WAITING grid=24x16, bodies=1` with the Seeker standing between the Quartermaster and the
      Deploy Gate, and no screen in between. Captured.

- [x] T306 [R288, P141 / V2] — **The name is asked once, ever.** Taken from
      `user://display-name.txt`; if absent, one rite in the writ idiom takes it and then proceeds
      straight into the expedition. Stated plainly in the requirements because it is the one place
      R287 cannot be absolute — a named player cannot be created without a name.
      Test: **V2** — `--name-rite` captured; the name is written on accept.

- [x] T307 [R289 / V3] — **The join screen becomes a writ.** `ui/writ_form.gd` (its own file, canon
      S5): aged parchment reusing the board's `parch_v1_0.png`, ink captions, **ruled lines instead
      of boxes**, Cinzel throughout, actions marked by the laurel. The purple panel, the studded
      yellow frame, the filled buttons, the sans and the brick-and-banner backdrop are all gone.
      The laurel moved to `Widgets.laurel` — two screens speak it now, so it is shared language and
      a second copy would drift.
      **Two layout facts cost a pass each:** `_root` is a `VBoxContainer` inside a `ScrollContainer`,
      so an absolutely-sized sheet was stretched full-width (content shoved right, actions cut off) —
      fixed by making the writ a NinePatchRect behind a MarginContainer so the *content* drives the
      height; and a child's own `SHRINK_CENTER` does not centre it there, so it uses a centred VBox
      host, the same way the title's column already did.
      Test: **V3** — captured beside the title: same type, same palette, no panel, no frame.

- [x] T308 [R290, R291 / V4] — **The hall stays, and the change is a transition.** `_clear()` gains
      `keep_env`, so the title environment is held alive rather than rebuilt — cheaper *and* the
      reason the transition can be a plain crossfade. The writ fades and settles 6px over 250 ms;
      reduced motion shows the end state.
      Test: **V4** — captured; budget unchanged (the writ adds no additive layer and no per-frame
      script).

- [x] T309 [R292 / V5] — **Land it.** No `src/**` change and no wire change — `CREATE_ROOM` and
      `JOIN_ROOM` go out with the same payloads as before; only the route to them changed. Maps,
      registry and suites green; diff scoped. DECISION_LOG **TD-080**.

## Found on the way, not fixed here

- **The Collegium the player now lands in is a greybox.** Removing the form made the create path
  instant, which puts the title screen's finished Great Hall directly against flat grey tiles, a
  visible grid and white system labels. That contrast was previously hidden behind a form. It is the
  obvious next pass, and it is *not* a regression from this one — the destination was always like
  that; the form was just in front of it.

## Queued

- The **lobby / room scroll** and the walkable Collegium's own art.
