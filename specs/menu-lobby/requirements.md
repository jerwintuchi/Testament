# Requirements — Main menu + lobby, production presentation (TD-071)

> The Contract Board ships at production quality while the **menu and lobby are still Godot
> greybox** — default theme, bare labels stacked over the walkable Collegium, colliding with station
> labels and the Seeker sprite. This spec brings the game's *first two screens* up to the register
> the rest of the client already holds.
>
> **Author rulings (do not re-litigate):**
> - **Wording stays functional** — Create Room / Join Room / Room code / Ready / Leave Room. No new
>   GLOSSARY terms, no in-fiction renaming. Clarity over flavor on the plumbing.
> - **The tagline is removed** ("We seek truth, not certainty." leaves the menu).
> - **The lobby HUD is a toggleable scroll/parchment** — like taking a contract down to read: it
>   costs **no screen space** until opened.
>
> Client render + input only (I1/I2 hold); no `src/**` change, no new wire message. Numbering
> continues global: **R224+**, correctness **P124+**, tasks **T236+**. Logged **TD-071**. Verified by
> capture (client-spec convention).

---

## Phase A — Wording + correctness (cheap, load-bearing)

**R224**: no enum ever reaches a player.
- AC: the world marker over each station reads **"Deploy Gate"**, not `DEPLOY_GATE`
  (`space_view.gd:52` renders `m["kind"]` raw today). Same for Contract Board, Quartermaster,
  Extraction.
- AC: the display-name table lives in **one** place both `main.gd` and `space_view.gd` read
  (today `_STATION_LABEL` sits in `main.gd` and the world never sees it) — a preloaded `RefCounted`
  under `scripts/core/`, per canon S3.2/S3.4.
- AC: an **unknown** kind falls back to its raw value rather than rendering blank (P125).

**R225**: the player's name is an identity, not a role.
- AC: the name field no longer **defaults to "Seeker"** — Seeker is the role every player holds
  (GLOSSARY), which is why every screenshot shows a party of "Seeker". It starts **empty** with a
  placeholder, and Create/Join are refused with an inline hint until a name is entered.
- AC: the name persists locally between launches (`user://`), so a returning player is not retyping.

**R226**: instruction scaffolding retires.
- AC: the permanent lines "Walk to the Contract Board and press E to accept.", "Walk to the
  Quartermaster (E) to requisition…", "Walk to the Extraction and press E to leave." are **removed**;
  the already-built contextual prompt (`_prompt`, "Press E: <station>", shown only in range) is the
  single instruction surface.
- AC: "The Collegium is hiring. We seek truth, not certainty." is removed from the menu
  (author ruling); the menu carries the title and the controls, nothing else.

## Phase B — The menu

**R227**: the menu reads as a finished screen, in the client's established register.
- AC: title in **Cinzel** over the themed surface; controls grouped into three blocks with real
  spacing — **identity** (name), **create**, **join** (code + button) — and **Resume** separated as
  the recovery path it is, shown only when a reconnect token exists.
- AC: it reuses shipped art only — `panel.png` 9-slice, `Fonts.cinzel`, `PopupTheme`, the stone
  surround + torch rig. **No new generator** is required by this spec.
- AC: connection state is a quiet corner indicator, not a body line; "server offline" keeps its
  actionable text.
- AC: the layout holds at 1280×720 and at the other integer scales (`PixelScale`), and nothing
  overflows or overlaps at any of them.

## Phase C — The lobby: the room scroll

**R228**: the lobby HUD is a **toggleable parchment**, closed by default (author ruling).
- AC: **closed** is the default on entering the lobby and costs no usable screen space: a small
  pinned tab only, carrying the party's ready pips (e.g. `●●○○`) so readiness is legible without
  opening.
- AC: **Tab** opens/closes it (when no station popup is open — the board owns Tab while it is up);
  the tab itself is also clickable.
- AC: **open**, it shows: the **Room code** with a **copy** affordance, the **party roster** (name,
  leader mark, "you", disconnected state, ready state as a pip — not the words "not ready"), and the
  **Ready** and **Leave Room** actions.
- AC: it is drawn as parchment on a themed panel and **never collides** with station labels or the
  Seeker sprite — the failure in the current build.
- AC: the leader's **Kick** control for a disconnected player stays available (R92 heritage), inside
  the roster row.

**R229**: copying the code is a real affordance.
- AC: a **Copy** control puts the room code on the OS clipboard
  (`DisplayServer.clipboard_set`) and confirms with the existing transient toast.
- AC: the code renders in a **large, unambiguous** style (the current build asks players to read
  `CZ3ZG4` aloud off a body label).

## Cross-cutting

**R230** (containment): client render + input only.
- AC: no `src/**` change; no new or changed wire message — Ready/Leave/Kick keep emitting the
  existing intents and the server stays authoritative (I1/I2).
- AC: dependency map regenerated; server + shared suites untouched-green.

---

## Correctness Properties

- **P124 (the scroll is view state):** opening/closing/toggling the room scroll sends nothing and
  mutates no game state; it is local presentation only, exactly as the notice reader is (I1). The
  roster it draws is the snapshot, never a client-derived copy.
- **P125 (display names are presentation):** the wire keeps carrying the enum `kind`; the client
  maps it for display at the render edge. An unmapped kind degrades to its raw value — a new server
  station can never render as an empty label.

## Verification

- **V1 (R224/R226):** a lobby capture shows **"Deploy Gate"** on the world marker and **no**
  standing instruction lines; the `Press E:` prompt still appears in range.
- **V2 (R225):** launching with no saved name shows an empty field with placeholder; Create with an
  empty name is refused inline and sends nothing.
- **V3 (R227):** a `--menu-preview` capture shows the themed menu — Cinzel title, no tagline,
  grouped controls — with no overlap at 1280×720.
- **V4 (R228/R229):** `--lobby-preview` captures **closed** (tab + pips only, world unobstructed)
  and **open** (code, roster, ready pips, actions); Copy places the code on the clipboard and toasts.
- **V5 (R230):** `git diff --name-only` is only `client/ specs/ docs/`; asset-map `--check` green;
  server + shared suites green.

---

# Phase D — The title screen (author redesign)

> Added after Phases A–B landed, on the author's brief: the title screen is a **held, minimalist
> image** — no characters, no combat, no monsters, no explosions. A solemn, sacred space. Selecting
> an option then transitions into the **Hall of Petitions**, where the player takes control of their
> Seeker. The rhythm the game gains: **contemplation → preparation → expedition → the unknown.**
>
> This is not only taste. A title screen showing an Incarnate would **leak the mystery** the game is
> built on (Pillar 3: understood through interpretation, never memorization) — a player would learn
> what a Manifestation looks like before reading a single sign. And combat imagery would advertise
> the *failure* state: the order's aims are witness, contain, redeem, and killing is "a failure of
> understanding, not a trophy" (`docs/lore/collegium.md`). The quiet screen is the canonical one.
>
> **Author rulings:** the image is **the empty nave**. There is **no "Continue"** — the options are
> **New Expedition** and **Join Expedition**, with **Return to your expedition** appearing above them
> **only** when a reconnect token exists. This supersedes the earlier "keep functional terms" ruling
> *on the title screen*; `Room code` stays the field's name where a code is actually typed.

**R231**: the title screen is a held image with no figures.
- AC: it renders **the empty nave** — a dark stone hall receding into black, one shaft of pale light
  from an unseen high window, a single lit candle. **No character, creature, weapon, or effect.**
- AC: the image is **generated** (`gen_nave.py`, Python owns surfaces per TD-057) into its own
  feature folder `assets/ui/title/`, per canon S5b.
- AC: it is drawn at an **integer** scale, centred, with the remainder filled in the image's own
  near-black — never fractionally stretched (the project's pixel grid, TD-042/PixelScale).
- AC: the title `TESTAMENT` is engraved lettering, not a printed label, matching the board's sign.

**R232**: the title offers only the ways in, and never a dead one.
- AC: the options are **New Expedition**, **Join Expedition**, **Quit**, plus **Return to your
  expedition** listed **first and only when a reconnect token exists** — never shown disabled.
- AC: `Return` maps to the existing `RECONNECT` intent, not to a save-game load: canon I7 keeps
  expedition state ephemeral, so the only thing to return to is an expedition still live on the
  server. A rejected/stale token surfaces its error and drops back to the title (P126).
- AC: no name field, no code field, and no status line on the title screen — it is an image with a
  short list of choices.

**R233**: the room setup is one screen deeper, and asks only what its path needs.
- AC: **New Expedition** opens a plate asking for the **name** only, acting via `CREATE_ROOM`.
- AC: **Join Expedition** opens a plate asking for the **name** and the **Room code**, acting via
  `JOIN_ROOM`.
- AC: both reuse the Phase B diegetic-lite plate + lit masonry (it is not discarded — it becomes
  this screen), and both offer **Back** to the title.
- AC: the empty-name and empty-code guards from R225 still hold and still send nothing.

**R234**: the walkable Collegium is named **the Hall of Petitions**.
- AC: the term enters `docs/GLOSSARY.md` with a DECISION_LOG entry — it is not an invention but a
  name the fiction already converged on (`PETITION TYPES` on the board bar, *"No petitions stand
  before the Collegium"*, the signing **petitioner**, and "the hall" in `specs/collegium/`).
- AC: entering it from the title is a **deliberate transition**, not an instant cut, so the rhythm
  (contemplation → preparation) is felt.

## Correctness Properties

- **P126 (the title sends one intent, R232):** the title screen emits **only** `RECONNECT`, and only
  from `Return`. New/Join Expedition are pure navigation to the room screen and send nothing; a
  failed reconnect returns to the title with the server's error shown, never a half-entered state.

## Verification

- **V6 (R231):** a `--title-preview` capture shows the nave, the engraved title, and the option list
  with no figure of any kind; re-captured at a second window size to prove the integer-scale centring.
- **V7 (R232/R233):** `--title-preview` with and without a token shows four options vs three, Return
  first; New Expedition shows a name-only plate, Join Expedition a name+code plate, both with Back.
- **V8 (R234):** the GLOSSARY carries **Hall of Petitions**; the DECISION_LOG records it.
