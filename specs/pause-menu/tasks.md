# Tasks — The way out (TD-085)

> T# continues global from T322. Client only; no `src/**` change.

- [x] T323 [R310 / V1] — **Share the menu row.** `main.gd._title_option` moved verbatim into
      `Widgets.choice`, which the title and the pause menu now both call. A third copy would drift,
      and the tuning inside it (175ms ease, +12% warmth, the laurel keeping its space so marking
      never shifts the lettering) is exactly what drifts silently.

- [x] T324 [R307, R308, R311, P146 / V1] — **The Escape menu.** `ui/pause_menu.gd` (its own file,
      canon S5) on its own `CanvasLayer` at 128, above everything, blocking input to the world.
      Three choices, named for what they cost rather than for the widget: *Return to your post*
      (focused on open, so Enter is always safe), *Leave the expedition*, *Quit to desktop*.
      Escape is **routed, not captured**: an open station popup still steps back one layer first
      (T146 untouched), a writ takes Back, the title does nothing because Quit is already on it.
      `_clear()` closes the menu on every screen change so it is never stranded over the next one.
      Test: **V1** — captured against a live server via `--pause`.
      **Two layout corrections, both mine:** the column was full-rect, so a `CenterContainer` with a
      shrink-centred column replaced it; and then the heading was *still* off-centre because
      `engraved_line` returns a **zero-width** Control whose labels anchor full-rect to it — setting
      `SHRINK_CENTER` on it collapsed the box to nothing and the text drew from the centre rightward.
      It must **fill** its column, which is what the title screen was quietly doing all along.
      Dim also went 0.72 → 0.86: the Seeker and his name label are centred like the menu, so they
      always collide, and the answer is for the hall to recede rather than for the menu to dodge.

- [x] T325 [R309 / V2] — **Leaving tells the server.** `LEAVE_ROOM` before returning to the title,
      reusing the room scroll's own leave path. Leaving quietly would strand the party with a ghost
      until the room timed it out — the failure TD-032 exists to prevent.

- [x] T326 [R312 / V3] — **Land it.** No `src/**` change; `LEAVE_ROOM` is an existing message with
      its existing payload. Maps, registry, budgets and suites green; diff scoped.
      DECISION_LOG **TD-085**.

## Still open

- **A real playtest of the exits.** The capture harness cannot click, so "Leave the expedition"
  actually returning you to the title, and the room emptying server-side, needs a human.
