# Design — The lobby dissolves into the hall (TD-088)

> Satisfies R313–R317. Client only; no wire change.

---

## The move

Every job the room scroll held goes to the place that already implies it:

```
the party        -> the Seekers standing in the hall
who is ready     -> a mark above each Seeker's head
who has dropped  -> that Seeker, rendered as a ghost
the roster+kick  -> the Deploy Gate (Press E)
ready toggle     -> the Deploy Gate (Press E)
the room code    -> the Deploy Gate, and the Escape menu
leave            -> the Escape menu (already there since TD-085)
```

Nothing new is invented: stations, `Press E`, and the Escape menu all existed. The 247-line HUD does
not.

## Why the Deploy Gate

Its fiction already is *the party assembles here to leave*, so a muster roll on it is the thing the
object is for. It also puts readiness next to the action readiness gates — `allReady()` is a **server
gate** (`acceptContract` refuses without it), so the toggle is load-bearing and could not simply be
deleted with the panel.

## Why the body carries the state

The closed scroll's pips existed so readiness was legible without opening anything. Above the
Seeker's own head does that better, because the party is standing right there.

The **ghost** is the one thing the world genuinely could not show before: a player who has dropped but
still holds their seat (TD-032). A roster line was the only evidence. Now the body fades to 45% and
its label reads *(lost)* — which is more legible than a panel entry, since you see it where you are
already looking.

## Two layout facts

- A `Label` with autowrap inside an `HBoxContainer` collapses to **one character per line**, because
  autowrap lets its minimum width fall to the widest glyph. Roster rows use a non-wrapping label with
  `SIZE_EXPAND_FILL` and the action pinned `SHRINK_END`.
- Ready is shown as a **mark**, never the words "not ready" — a muster roll notes who has answered,
  and blank says the same thing without accusing anyone.

## Files

**Deleted:** `client/scripts/ui/room_scroll.gd` (247 lines) and all its wiring, including the `Tab`
verb and `--scroll-open`.
**Edited:** `client/scripts/world/player.gd` (ready mark, ghost), `client/scripts/main.gd` (the
muster point, lobby state on bodies, scroll removal), `client/scripts/ui/pause_menu.gd` (room code).

## Known debt this exposes rather than creates

The station popup is still the **old purple-and-yellow panel** — the chrome the join screen shed in
TD-080. Moving the roster into it did not cause that, but it does make it more visible, and it is
already specced as `station-ui` T127–T129.

## Correctness Properties

- **P147 (one place per job):** ready, kick, leave and the room code each have exactly one home. The
  bug this replaces is `leave` having had two.
