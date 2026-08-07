# Design — Options, and taking your name back (TD-084)

> Satisfies R300–R306. Client only; no wire change.

---

## It is the same writ

The join screen (TD-080) established a Collegium document as the way this game asks the player for
something: aged parchment over the hall, ink captions, ruled lines instead of boxes, Cinzel
throughout, actions marked by the laurel. Options is that object with different rows — because a
settings screen that looked like a settings screen would undo four specs of work in one step.

`writ_form.gd` grows two row types to carry it:

- **`toggle`** — an inked square, struck through with an X when set. Emptying every stylebox is the
  trick that removes chrome from the *actions*; applied to a checkbox it leaves nothing to see at
  all, which is exactly what the first pass shipped.
- **`slider`** — a hairline track, an ink-filled portion, and a small inked **diamond** for the
  grabber. Godot's default is a grey trough with a white puck: the single most "engine widget dropped
  onto parchment" thing that could sit on this sheet. The diamond is the board's own ornament
  vocabulary (`ornament_scrollbar` already uses one for the same job), so the replacement is the
  project's, not Godot's.

## The name (R301, P145)

`_show_options` reads and writes the **same** `user://display-name.txt` the create path already uses,
through the same `_load_name` / `_save_name`. There is deliberately no second store: a display name
with two sources of truth is a bug waiting for the moment they disagree.

It refuses an empty name with the same message the first-run rite uses, because **P140** — no route
to `CREATE_ROOM` without a name — must not weaken just because a second way to set one now exists.

**It does not rename you inside a room you are already in.** The server owns lobby membership; this
writes the local identity used for the *next* create or join. Anything else would be a wire change,
and this spec is not one.

## Settings (R302)

`core/settings.gd`, a `ConfigFile` at `user://settings.cfg`. Legitimate under **TD-006**: identity,
cosmetics and *customization* persist, and a volume level and a motion preference are customization.
A missing file is the **first launch** — the common case, not an edge one — so it returns defaults
silently, and a corrupt file does the same rather than refusing to start.

**The name keeps its own file.** Folding it into the config would make the one value the game cannot
start without depend on config parsing succeeding — a strictly worse failure mode for no gain.

Settings load **before the first screen is built**, so reduced motion is honoured from the very first
frame rather than applied to a screen that has already been constructed with animation in it.

## Reduced motion (R303)

Already existed as the F9 lever and already worked; it was simply undocumented. Shipping a settings
screen while leaving the one accessibility control as a debug key would be strange. **F9 now persists
what it toggles**, so the key and the setting cannot disagree — otherwise the options screen would
show something the game is not doing.

## Volume (R304)

The author asked for a placeholder. A slider that moves and does nothing is worse than one that is
honest, and wiring it is two lines: it drives the **master bus** and persists. It is labelled
`VOLUME (no sound ships yet)` because the game ships no audio — T262 is blocked on there being no
sanctioned audio tool — and the player should not have to discover that by turning it up.

No other placeholder rows are invented. An options screen full of dead controls is a promise the game
has not made.

## Files

**New:** `client/scripts/core/settings.gd`, `specs/options/*`.
**Edited:** `client/scripts/ui/writ_form.gd` (`toggle`, `slider`, `gap`, the diamond),
`client/scripts/main.gd` (the Options entry, `_show_options`, settings at boot, F9 persisting, and
the corner-label fix).

## Correctness Properties

- **P145 (one place decides the name):** every path reads and writes the same stored value through
  the same two functions.
- **P140 (standing):** still no route to `CREATE_ROOM` with an empty name.
