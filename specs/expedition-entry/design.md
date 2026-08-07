# Design — Entering an expedition (TD-080)

> Satisfies R287–R292. Client render + routing only. Verified by capture, including one against a
> live server.

---

## The shape of it

```
TITLE ──"New Expedition"──▶ CREATE_ROOM ──▶ ROOM_CREATED ──▶ the walkable Collegium
          (no screen)                                          (already existed)

TITLE ──"Join Expedition"─▶ the writ ──▶ JOIN_ROOM ──▶ … ──▶ the walkable Collegium
          (the one dedicated scene)
```

The create path is **a deletion**. `ROOM_CREATED` already routed to `_show_lobby()`, and the lobby
already *is* the walkable Collegium — the form was the only thing standing between the title and the
game. Removing it is the whole feature.

## The name (R288)

`CREATE_ROOM` needs a `displayName` and there is no longer a field to read it from. The name is
already persisted (`user://display-name.txt`) because it is **identity**, the one category canon lets
us keep (TD-006). So:

```
_begin_new_expedition():
    who = stored name
    if who == "":  the rite, once, ever
    else:          CREATE_ROOM, straight in
```

The first-run rite is the same writ object as the join screen, deliberately — so the one time it
appears it reads as the Collegium entering you in its roll, not as a settings dialog.

## The writ (R289)

`ui/writ_form.gd`, a new file rather than more of `main.gd` (canon S5: new client features start as
their own file). It builds onto a passed-in host, the `add_torches` / `RiteBanner` idiom, and never
touches the socket — it hands back its `LineEdit`s and the caller decides what to send (I1).

What it removes, and why each mattered:

| gone | why |
|---|---|
| the purple-navy panel | a saturated blue-violet that appears nowhere else in Testament |
| the yellow frame with corner studs | chrome; a box drawn round the content is what R232 exists to stop |
| filled brown buttons | the title marks a choice with the laurel, not with a filled rectangle |
| the default sans | the title is Cinzel throughout |
| the brick wall, banners and torches | a different room from the one the player was just standing in |

What replaces it: **aged parchment** — the Contract Board's own `parch_v1_0.png`, reused as an asset
rather than as a code dependency on `board/`, because a writ and a notice are the same material and a
second parchment would be two things to keep in sync. Captions and values are **ink**, fields are
**ruled lines** (a box is the thing that reads as a form control), and actions are Cinzel marked by
the laurel.

### The laurel moved to `Widgets`

Two screens now mark focus with it, so it is shared visual language rather than something the title
owns: `Widgets.laurel(pointing_right)`. `main.gd`'s `_menu_sigil` delegates, so there is exactly one.

### Two layout facts that cost a pass each

- **`_root` is a `VBoxContainer` inside a `ScrollContainer`.** An absolutely-positioned, absolutely-
  sized sheet is therefore stretched full-width every layout pass, which shoved the content to one
  side and cut the actions off the bottom. The writ is now a **NinePatchRect behind a
  MarginContainer**, so the *content* drives the height and the deckled tear survives because only
  the middle stretches.
- **A child's own `SHRINK_CENTER` does not centre it there.** The title screen centres its column by
  putting it in a centred `VBox` host; the writ now does the same.

## The hall stays (R290)

`_clear()` gains `keep_env`. The join writ is laid over the *same* hall the player was just looking
at, so rebuilding the title environment would cost a full scene construction and produce a visible
flicker at precisely the moment we want continuity. Keeping it is both cheaper and better, which is
why the transition can be a plain crossfade: the writ fades and settles 6px over 250 ms, and nothing
else moves.

## Files

**New:** `client/scripts/ui/writ_form.gd`, `specs/expedition-entry/*`.
**Edited:** `client/scripts/main.gd` (routes, `_clear(keep_env)`, debug flags),
`client/scripts/ui/widgets.gd` (`laurel`).
**Removed:** `_show_room_setup`, `_show_menu`, `_menu_caption`, `_claim_name`, and the
`--setup-create` flag — the screen it opened no longer exists.

## Correctness Properties

- **P140 (intentions only):** removing the form changes *when* `CREATE_ROOM` is sent, never what it
  is or who validates it. The server remains the only authority (I1/I2).
- **P141 (identity persists, state does not):** the name is written to disk because it is identity;
  nothing about the expedition is.
