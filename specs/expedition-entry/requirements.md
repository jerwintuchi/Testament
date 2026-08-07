# Requirements — Entering an expedition (TD-080)

> The author, on the room-setup screens: *"it doesn't belong to the current theme based on the title
> screen"* — and, decisively, *"the create room should be the actual in-game, player in collegium not
> another ui. the join expedition should be the only one that should have a dedicated ui scene."*
> Plus: *"just make it simple, not too much"*, and a transition from the title.
>
> **R287+**, **P140+**, **T305+**.

---

## What is wrong today, specifically

The setup screens are a dialog box, not the Collegium. Measured against the title screen they break
in six ways at once: a saturated **purple-navy panel** (a colour that appears nowhere else in the
game), a **bright yellow frame with corner studs**, **chunky filled buttons**, **body text in the
default sans** where the title is Cinzel throughout, and a **tiled brick wall with red banners** —
a different room entirely from the Great Hall. Only the heading is on-theme.

The deeper problem is structural, and the author named it: **creating a room does not need a screen
at all.**

## R287 — "New Expedition" enters the Collegium; it is not a form

- AC: pressing it sends `CREATE_ROOM` directly and the player lands **in the walkable Collegium** as
  their Seeker. No intermediate UI.
- AC: this is mostly a deletion. `ROOM_CREATED` already routes to the lobby, and the lobby already
  *is* the walkable Collegium — the form was the only thing in the way.
- AC: the create half of `_show_room_setup` is **removed**, not hidden.

## R288 — The name is identity, and is asked exactly once

`CREATE_ROOM` requires a `displayName`, and with no form there is nothing to read it from. The name
is already persisted to disk, so:

- AC: the stored name is used. Nothing is asked on any subsequent launch.
- AC: **first run only**, when no name is stored, one small rite asks for it — in the same parchment
  idiom as the join screen, so it never reads as a settings dialog.
- AC: this is the *only* interruption between pressing New Expedition and standing in the Collegium.
  (Stated plainly because it is the one place R287 cannot be absolute: a named player cannot be
  created without a name.)

## R289 — Join Expedition is the one dedicated scene, and it is a writ

- AC: the form is a **diegetic Collegium document** — aged parchment, the vocabulary the Contract
  Board already owns, reusing its `parch_v1_*` art rather than inventing a surface.
- AC: the purple panel, the yellow frame with corner studs and the filled buttons are **gone**.
- AC: type is **Cinzel** throughout, as on the title screen; the fields are ruled lines on paper, not
  boxes; actions are marked by the **laurel sprig**, the language established in TD-077.
- AC: ink on paper — dark ink on parchment, not gilt on stone. The writ is the one lit thing.

## R290 — The hall stays behind it, and the change is a transition

- AC: the Great Hall **remains** behind the writ — the same plate, shader, vignette and dust. The
  player never leaves the room they were standing in.
- AC: the title's environment is **not rebuilt** on the way in; it is kept alive, so there is no
  rebuild cost and no flicker.
- AC: a short transition (~250 ms) carries the title's menu column out and the writ in. "Simple, not
  too much" — a fade and a small settle, nothing theatrical.
- AC: reduced motion shows the end state directly.

## R291 — Performance, under the standing canon

- AC: the writ adds **no full-frame additive layer** and no per-frame script; the budget check stays
  green and the particle count is unchanged.
- AC: keeping the title environment alive is *cheaper* than rebuilding it, and is the reason the
  transition can be a pure crossfade.

## R292 (containment) — client render + wiring only

- AC: no `src/**` change and no wire-protocol change. `CREATE_ROOM` and `JOIN_ROOM` are sent exactly
  as before, with the same payloads — only the client's route to them changes.
- AC: maps, registry and manifest regenerated; suites green.

---

## Correctness Properties

- **P140 (the client still only sends intentions):** removing the create form changes *when*
  `CREATE_ROOM` is sent, never what it is or who validates it. The server remains the only authority
  on whether a room exists (I1/I2).
- **P141 (identity persists, state does not):** the display name is written to disk because it is
  identity (TD-006). Nothing about the expedition is.

## Verification

- **V1 (R287):** pressing New Expedition with a stored name reaches the walkable Collegium with no
  screen in between — captured.
- **V2 (R288):** with no stored name, the rite appears once; captured, and the name is on disk after.
- **V3 (R289):** the join writ captured beside the title screen — same type, same palette, no panel,
  no frame, no filled buttons.
- **V4 (R290/R291):** captured mid-transition and settled; `title_assets --budget` unchanged.
- **V5 (R292):** diff scoped; `git diff` shows no `src/**`; suites green.
