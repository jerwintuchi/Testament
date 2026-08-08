# Requirements — The lobby dissolves into the hall (TD-088)

> The author, weighing the room scroll: *"i think the room scroll is just unnecessary overhead and
> cost to deploy and maintain."* Half right — and the answer is not "just a room code", because the
> code is how you get **in** and says nothing about readiness, which the server enforces. The answer
> is to put its jobs where they belong: in the world and at the station whose fiction already is
> "the party musters here".
>
> **R313+**, **P147+**, **T327+**.

---

## What the scroll actually carried

Measured, not assumed — 247 lines, client render only (there is no deployment cost; the cost is
maintenance and screen real estate):

| job | where it goes |
|---|---|
| room code + copy | the Deploy Gate, and the Escape menu |
| ready toggle | the Deploy Gate — `Press E`, like every other station |
| ready state at a glance | a pip above each Seeker in the world |
| the roster | the Seekers themselves, standing in the hall |
| disconnected seats (ghosts) | those Seekers, rendered as ghosts |
| kick (leader) | the Deploy Gate's roster |
| leave | **already duplicated** by the Escape menu (TD-085) |

## R313 — The Deploy Gate becomes the muster point

- AC: it lists the party — every seat, who is ready, who is disconnected — and the **room code**,
  which is the thing you actually need in order to invite someone.
- AC: **ready is toggled here.** `allReady()` is a server gate (`acceptContract` refuses without it),
  so this is load-bearing, not decoration.
- AC: the leader can **kick** from this list; kicking is a roster operation and this is the roster.
- AC: the leader's **Deploy** action stays where it already is.
- AC: it is reached the way every station is — walk to it, `Press E` — with no new input verb.

## R314 — The world carries the at-a-glance state

- AC: a Seeker who is ready is marked **in the world**, above their own body, so readiness is legible
  without opening anything. That is what the closed scroll's pips existed for.
- AC: a Seeker whose player has **disconnected but still holds their seat** renders as a ghost. The
  scroll's roster was the only place this was visible, and it is the one thing the world genuinely
  did not show (TD-032's ghost case).
- AC: no floating captions beyond the name that already exists — the standing rule from TD-081.

## R315 — The room code is findable without a HUD

- AC: shown at the Deploy Gate, and in the **Escape menu**, which is where a player goes when asking
  "how do I get my friend in?".
- AC: copyable where it is shown.

## R316 — The scroll is deleted, not hidden

- AC: `client/scripts/ui/room_scroll.gd` and its wiring are **removed**. Nothing is left switched off
  "in case", and Tab stops being a lobby verb.
- AC: the Escape menu keeps `Leave the expedition`; the duplication introduced in TD-085 is resolved
  by deleting the scroll's copy, not the menu's.

## R317 (containment) — client only

- AC: no `src/**` change and no wire change. `TOGGLE_READY`, `KICK_PLAYER`, `DEPLOY` and `LEAVE_ROOM`
  are existing messages with existing payloads; only where the player triggers them moves.
- AC: maps, registry, budgets and suites green.

---

## Correctness Properties

- **P147 (one place per job):** each of ready, kick, leave and the room code has exactly one home.
  The bug this replaces is `leave` having had two.
- **P124 (standing):** the lobby view sends nothing on open or close; opening a station is an
  affordance, never an authorization (the server re-validates every action).

## Verification

- **V1 (R313):** capture at the Deploy Gate against a live server — roster, ready, code, deploy.
- **V2 (R314):** capture; a ready Seeker is marked in the world, and a disconnected one reads as a
  ghost.
- **V3 (R315):** capture; the code is present at the gate and in the Escape menu.
- **V4 (R316):** `room_scroll.gd` is gone and nothing references it; headless parse clean.
- **V5 (R317):** diff scoped; suites green.
