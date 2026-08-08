# Design — The way out (TD-085)

> Satisfies R307–R312. Client only.

---

## Which idiom, and why it matters

Two now exist, and picking the wrong one would have muddled both:

| | looks like | used by |
|---|---|---|
| a **document you fill in** | parchment, ink, ruled lines | the join writ, options |
| a **choice you make** | gilt Cinzel, no chrome, laurel on focus | the title menu, **this** |

A pause menu is a choice, so it is the title's language laid over a dimmed world. That also makes the
transition legible: *Leave the expedition* takes you to a screen that already looks like this one.

## Escape is routed, not captured

Escape already meant something, and the order matters:

```
pause menu open        -> close it            (its own layer answers first)
station popup open     -> step back one layer (T146, untouched)
on a writ  (MENU)      -> Back to the title
in an expedition       -> open the menu
on the title           -> nothing; Quit is already there
```

A player deep in the Contract Board pressing Escape wants out of the *board*. Taking that key away
to offer them a quit dialog would be worse than not having the menu.

## Its own layer (R311, P146)

`CanvasLayer` at 128, above everything, with a full-rect root that **stops** input rather than
ignoring it. The menu is the way out; anything able to draw over it would trap the player in exactly
the situation it exists for. `_clear()` closes it on every screen change, so it can never be left
behind over the screen that follows.

## Leaving tells the server (R309)

It sends `LEAVE_ROOM` before returning to the title, reusing the room scroll's own leave path. The
room is authoritative and would time the player out eventually, but leaving quietly strands the party
with a ghost until it does — which is the failure TD-032 exists to prevent.

## The shared row

`Widgets.choice(host, text, size, on_pressed)` — moved verbatim out of `main.gd._title_option`, whose
body it now is. Three screens speak this language; a third copy would drift from the other two, and
the TD-077/TD-084 tuning inside it (175ms ease, +12% warmth, the laurel keeping its space) is exactly
the kind of detail that drifts silently.

## Files

**New:** `client/scripts/ui/pause_menu.gd`, `specs/pause-menu/*`.
**Edited:** `client/scripts/ui/widgets.gd` (`choice`), `client/scripts/main.gd` (the layer, Escape
routing, open/close, `_clear`).

## Correctness Properties

- **P146 (one way out, always reachable):** topmost layer, cleared on every screen change.
