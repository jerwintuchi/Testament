# Tasks — The lobby dissolves into the hall (TD-088)

> T# continues global from T326. Client only; no `src/**` change.

- [x] T327 [R314 / V2] — **The body carries the state.** A ready Seeker is marked above their own
      head; a Seeker whose player has dropped but still holds their seat fades to 45% and reads
      *(lost)*. The ghost is the one thing the world could not show before — a roster line was the
      only evidence of it (TD-032) — and on the body it cannot be missed.

- [x] T328 [R313, R315 / V1, V3] — **The Deploy Gate becomes the muster point.** Roster, ready
      toggle, leader kick, the room code and Copy, and the existing Deploy — reached the way every
      station is, with no new input verb. Ready stays because `allReady()` is a **server gate**, not
      decoration. The room code also appears in the **Escape menu**, which is where a player goes
      when asking how to get a friend in.
      **One layout correction:** a `Label` with autowrap inside an `HBoxContainer` collapses to one
      character per line, because autowrap lets its minimum width fall to the widest glyph. Rows now
      use a non-wrapping label at `SIZE_EXPAND_FILL` with the action pinned `SHRINK_END`.

- [x] T329 [R316, P147 / V4] — **The scroll is deleted.** `room_scroll.gd` and every reference are
      gone, including the `Tab` verb and `--scroll-open`. The `leave` duplication TD-085 introduced
      is resolved by deleting the scroll's copy, not the menu's.

- [x] T330 [R317 / V5] — **Land it.** No `src/**` change and no wire change: `TOGGLE_READY`,
      `KICK_PLAYER`, `DEPLOY` and `LEAVE_ROOM` are existing messages with existing payloads, and only
      where the player triggers them moved. DECISION_LOG **TD-088**.

## Exposed, not caused, by this pass

- The **station popup chrome** is still the old purple-and-yellow panel — the idiom the join screen
  shed in TD-080. Moving the roster into it makes it more visible. Already specced as `station-ui`
  T127–T129.

## Still open

- A **two-client playtest**: a second Seeker joining by code, readying, and appearing as a ghost on
  disconnect. The capture harness has one client, so this needs a human.
