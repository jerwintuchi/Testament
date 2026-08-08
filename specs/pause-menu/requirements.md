# Requirements — The way out (TD-085)

> The author, during testing: *"pressing escape opens a menu to be able to exit from the game so I
> can exit instead of manually closing the godot window"* — with **two** exits, to the main menu and
> to the desktop.
>
> **R307+**, **P146+**, **T323+**.

---

## R307 — Escape opens a menu inside an expedition

- AC: pressing Escape while in the walkable game (lobby, deploying, field) opens a menu; pressing it
  again closes it. There is currently **no way out of the game at all** except closing the window.
- AC: it does **not** hijack Escape where the key already means something. A station popup still
  steps back one layer first (T146's behaviour is untouched), because a player deep in the Contract
  Board expects Escape to back out of the board, not to offer to quit.
- AC: on the title screen Escape does nothing — Quit is already on it — and on a writ it means Back,
  which is what the key already does everywhere else.

## R308 — Two exits, because they are different acts

- AC: **Leave the expedition** — leaves the expedition and returns to the title screen.
- AC: **Quit to desktop** — closes the program.
- AC: **Return to your post** — dismisses the menu, and holds focus on open, so Enter is always the
  safe answer.

## R309 — Leaving tells the server

- AC: leaving for the title sends `LEAVE_ROOM` before it goes. The room is authoritative and would
  eventually time the player out, but leaving quietly strands the party with a ghost until it does —
  the exact failure `specs/lobby-resilience/` (TD-032) was written to fix.
- AC: it reuses the path the room scroll's own Leave already takes, rather than inventing a second
  one that can drift from it.

## R310 — It is a menu, not a document

The project now speaks two idioms and this fixes which one applies:

- AC: **a document you fill in is a writ** (join, options — parchment, ink, ruled lines); **a choice
  you make is a menu row** (the title screen). The pause menu is a choice, so it is the title's
  language: gilt Cinzel, no chrome, the laurel marking the focused line, over a dimmed world.
- AC: the laurel-marked row is **shared**, not copied a third time.

## R311 — Nothing can draw over the way out

- AC: the menu lives on its own `CanvasLayer`, above every other. A station popup or HUD drawing over
  it would trap the player in precisely the situation the menu exists to escape.
- AC: it blocks input to the world beneath rather than letting clicks through.
- AC: changing screen never strands an open menu over the screen that follows.

## R312 (containment) — client only

- AC: no `src/**` change. `LEAVE_ROOM` is an existing message sent with its existing payload.
- AC: maps, registry, budgets and suites green.

---

## Correctness Properties

- **P146 (one way out, always reachable):** the menu is on the topmost layer and is cleared on every
  screen change, so it can neither be covered nor left behind.

## Verification

- **V1 (R307/R310/R311):** capture, against a live server; the menu reads over the dimmed Collegium.
- **V2 (R308/R309):** leaving returns to the title and sends `LEAVE_ROOM`.
- **V3 (R312):** diff scoped; suites green.
