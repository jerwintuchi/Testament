# Tasks — Options, and taking your name back (TD-084)

> T# continues global from T317. Client only; no `src/**` change.

- [x] T318 [R300 / V1] — **Options in the title menu, as a writ.** One line added above Quit;
      nothing else about the composition moves. Opens the same parchment object as the join screen,
      over the same hall, with the same 175ms arrival.
      Test: **V1** — captured via `--options`.

- [x] T319 [R301, P145 / V2] — **The name is changeable.** Reads and writes the *same*
      `user://display-name.txt` the create path uses, through the same `_load_name`/`_save_name` —
      no second store, because a display name with two sources of truth is a bug waiting for them to
      disagree. Refuses an empty name with the first-run rite's own message, so **P140** does not
      weaken now that a second way to set one exists. Does **not** rename you inside a room you are
      already in: the server owns lobby membership, and anything else would be a wire change.

- [x] T320 [R302, R303, R304 / V3] — **Settings persist; reduced motion is real; volume is honest.**
      `core/settings.gd` (`ConfigFile` at `user://settings.cfg`), loaded **before the first screen**
      so reduced motion is honoured from the first frame rather than applied to a screen already
      built with animation in it. A missing file is the first launch — the common case — so it
      returns defaults silently. F9 now **persists what it toggles**, or the screen would show
      something the game is not doing. Volume drives the master bus for real and says
      `(no sound ships yet)`, because a slider that moves and does nothing is worse than one that is
      honest.
      Test: **V3** — a settings file was **planted on disk** with `reduced_motion=true` and the
      screen came up with the box inked, proving the load path end to end. *Honest limit:* the
      slider's grabber position could not be isolated from the caption text by pixel measurement, so
      volume's load is verified by riding the same three lines in the same function rather than by
      its own capture, and the round-trip **save** is unverified because an unattended capture cannot
      click.

- [x] T321 [R305 / V4] — **The corner stops colliding.** `connected` and `v0.0.1` were both anchored
      bottom-right and overlapped — found while capturing the join writ, not by looking for it. The
      version string lifts 13px clear.

- [x] T322 [R306 / V5] — **Land it.** No `src/**` change and no wire change: the name written here is
      the same local identity the client already sends, and the server keeps validating it (I2).
      Maps, registry, budgets and suites green; diff scoped. DECISION_LOG **TD-084**.

## Still open

- **A real playtest of the round-trip** — change the name in Options, then create an expedition and
  confirm the lobby shows it. The capture harness cannot click, so this one needs a human.
- The **lobby / room scroll HUD** remains the last unstyled surface in the pre-expedition flow.
