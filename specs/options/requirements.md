# Requirements — Options, and taking your name back (TD-084)

> The author: an options/config screen reachable from the title — **the name first**, because TD-080
> asks for it once and then it lives on disk with no way to change it; volume and the rest are
> placeholders "just to give way for the player to change name".
>
> **R300+**, **P145+**, **T318+**.

---

## R300 — Options is a title-menu choice, in the established idiom

- AC: the title menu gains **Options**, above Quit. One line added; nothing else about the
  composition moves (the polish brief's preservation still holds).
- AC: it opens a **writ** — the same parchment object as the join screen (TD-080), over the same
  hall, with the same 175ms arrival. A settings screen that looked like a settings screen would undo
  the work of the last four specs.

## R301 — The name is changeable, and that is the point of this spec

- AC: the current name is shown and can be edited; saving writes it to the same
  `user://display-name.txt` TD-080 already reads, so nothing about the create path changes.
- AC: an empty name is refused with a reason, exactly as the first-run rite refuses it — the
  invariant that `CREATE_ROOM` is unreachable without a name (P140) must not be weakened by adding a
  second way to set it.
- AC: changing the name **does not** rename you inside a room you are already in. The server owns
  who is in a lobby; this writes the local identity used for the *next* create/join. Stated because
  the opposite would be a wire change, and this spec is not one.

## R302 — Settings persist, and only settings do

- AC: options are written to `user://settings.cfg` and restored on launch.
- AC: this is legitimate under **TD-006**: identity, cosmetics and *customization* persist; nothing
  about an expedition does. A volume level and a motion preference are customization.
- AC: a missing or corrupt file falls back to defaults without erroring — the first launch has no
  file, and that is the common case, not an edge one.

## R303 — Reduced motion becomes a real setting

- AC: the F9 lever (`_reduced_motion`) is exposed as a toggle and **persists**. It already exists,
  already works, and is the one accessibility control the game has; leaving it as an undocumented
  debug key while shipping a settings screen would be strange.
- AC: toggling it takes effect on the next screen build, as F9 already does.

## R304 — Volume is real, not a prop

The author asked for a placeholder. A slider that moves and does nothing is worse than one that is
honest, and wiring it costs two lines:

- AC: the slider drives the **master audio bus** and persists. It genuinely controls volume.
- AC: it is labelled so the player understands there is nothing to hear yet — the game ships no audio
  (T262 is blocked on there being no sanctioned audio tool). Honest, not fake.
- AC: no other placeholder rows are invented. An options screen full of dead controls is a promise
  the game has not made.

## R305 — The corner stops colliding

- AC: found while capturing the join writ: the connection status (`connected`) and the version string
  (`v0.0.1`) are both anchored bottom-right and **overlap**. They are separated.

## R306 (containment) — client only

- AC: no `src/**` change and no wire change. The name written here is the same local identity the
  client already sends on `CREATE_ROOM`/`JOIN_ROOM`; the server keeps validating it (I2).
- AC: maps, registry and suites green.

---

## Correctness Properties

- **P145 (one place decides the name):** every path that needs a display name reads the same stored
  value through the same function. Adding an editor must not create a second source of truth.
- **P140 (standing):** there is still no route to `CREATE_ROOM` with an empty name.

## Verification

- **V1 (R300):** capture; Options sits in the menu and opens the writ over the hall.
- **V2 (R301/P145):** capture; change the name, return to the title, and the new name is what the
  next expedition is created with — verified against a live server, not asserted.
- **V3 (R302/R303/R304):** toggle and slider persist across a relaunch; defaults survive a missing
  file.
- **V4 (R305):** capture; the two corner labels no longer overlap.
- **V5 (R306):** diff scoped; suites green.
