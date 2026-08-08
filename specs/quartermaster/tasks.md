# Tasks — The Quartermaster (TD-090)

> T# continues global from T330. **Phase A is client-only and can ship alone — it is the whole
> remaining spec.** Phase B (the Stipend) was **cut by the author on 2026-08-08, TD-091**; its tasks
> are marked superseded in place below.

## Phase A — the requisition form (client only)

- [x] T331 [R319 / V1] — **The four slots read as slots.** Occupied and empty shown at once, at the
      top of the sheet, because bounded capacity is the mechanic (`loadout-economy` non-negotiable 3)
      and "2 of 4" makes the player parse a number to learn it.
      Shipped: four bordered slots that FILL with the instrument's icon, above a line that reads
      "3 of 4 slots still open" / "the bag is full" — the count is the subtitle, the slots are the
      statement. **The Quartermaster is a LENDING COUNTER**, not a shop or storage: there is no
      currency (TD-091) and instruments are issued against a writ, not owned.
      Test: `--quartermaster` and `--qm-full` capture against a live server. Both green.

- [x] T332 [R318, R320 / V1] — **The list becomes ink.** Each item is a marked row in the writ idiom
      — `WritForm.toggle`'s inked square, not a stock `CheckBox` — and states what it does in the
      player's language ("Reads Residue"), never the wire enum, never a rating.
      **Style in the builders, never in the popup `Theme`** — it cascades into the Contract Board
      (TD-089). This is the whole risk of the task.
      Shipped as `client/scripts/stations/quartermaster.gd` — a new client feature does NOT enter
      `main.gd` (canon S5); the router keeps the selection and the socket, the module only renders and
      hands intents back. **Interaction is CLICK-TO-ASSIGN, not drag-and-drop**: mobile is a target
      platform (TD-042), and a drag needs a touch state machine, is fiddly at this scale and breaks
      the keyboard focus the board already uses. Rows are grouped **Instruments of Sight / of Trial**
      — the spine verbs — so the real tradeoff is visible: how many slots for looking, how many for
      trying. Each row states the QUESTION it settles ("Answers: what hurts it?"), never the wire enum.
      **Icons**: 10 hand-authored 24px marginalia (`art/src/gen_gear_icons.lua`, Aseprite per TD-057),
      iron-gall ink with a muted wash because they sit on parchment. Shown 1:1 NEAREST.
      Test: capture — no engine widget visible. **One found on the way**: the popup's stock grey
      scrollbar was the last engine widget on the paper; inked on the node, never in the Theme.

- [x] T333 [R321 / V2] — **Board proven untouched**: captured from a stashed clean tree at HEAD,
      **0.339%** of pixels differ against a ~0.47% control floor (torch particles + hover-focus).
      Necessary because the scrollbar fix touches the popup's SHARED `ScrollContainer`; the board does
      not overflow, so its bar never draws. Suites green (server 393 / shared 65 / tools 7); no
      `src/**` change.
      **Unrelated defect found and fixed while capturing** (it blocked the capture path): the client
      wrote a display name of any length to `user://display-name.txt`, but the server rejects over 32
      characters — so a player who typed a long name in the options writ could never create an
      expedition again, with only a transient toast to explain. The local file held 82 characters.
      Clamped in both `_save_name` and `_load_name`, since a file written by an older build is already
      on disk.

## Phase B — the Register (author brief, 2026-08-08)

- [x] T369 — **The Quartermaster becomes an expedition preparation screen.** Three columns —
      the register of available instruments, the **expedition pack** as a real leather case with
      recessed compartments, and the **field record** — over a tally and the rite. Split per the
      brief's §18 into `stations/quartermaster/`: `register` (composition + state), `pack`
      (case, compartments, flight), `record` (the field document), `lore` (item prose),
      `seal_rite` (the commitment). Selection inspects; the record commits; a packed compartment
      is clicked to give the instrument back.
      **Assets**: `client/assets/ui/gen_quartermaster.py` — deterministic, fixed Ash & Ember
      palette with an `assert_on_palette` gate, authored at display size, shown 1:1 NEAREST.
      Test: `--quartermaster`, `--qm-full`, `--qm-pick` captures; `--reduced-motion` clean;
      `--muster` unaffected; board diffed at **0.289%** against a ~0.47% control floor.

- [x] T370 — **Author playtest follow-up.** Three fixes and one real bug the playtest surfaced.
      **The bug:** `WRONG_PHASE` on sealing. `REQUISITION` is `DEPLOYING`-only server-side (R65 — the
      bag is a bet on the contract's intel), but the station is walkable in `WAITING`, so a player
      could browse, pack four instruments, seal, and only then be refused. The station is now
      **closed until a charge is taken up**: one `_station_open()` predicate read by BOTH the
      proximity prompt (which reads "Quartermaster — closed") and the E key (which states the
      reason), so the affordance and the action can never disagree.
      **Party bags** are now shown — `LobbyPlayer.bag` already ships party-visible precisely because
      coordinating the bags IS coordinating perception (TD-007), and the screen ignored it. A shelf
      row marks `held` and the record says "Wren already carries this." A second copy of an
      instrument the party holds is a wasted slot; nothing used to say so.
      **Pack art redesigned**: brass corner brackets, straps buckled over the rim, stitched interior,
      and compartments re-cut as leather LOOPS rather than bevelled boxes (the old ones read as
      buttons). Detail lives in the border, which a 9-slice never stretches.
      Also: the outer scrollbar is gone (the columns bound themselves), descriptions were halved and
      each carries a line of the order's history, and the property line dropped to a 6px footer under
      its own rule.
      Test: `--qm-pick`, `--qm-full`, `--qm-party`, `--reduced-motion`, `--muster`, `--board-preview`
      — all clean; board diffed at **0.042%** against a ~0.47% floor.

### The Godot trap this pass hit, recorded so it is not repeated

**`Panel` does not lay out its children.** The expedition case was a `Panel` with an anchored column
inside it. The panel collapsed to zero height, and the column — anchored but with its own minimum
size — rendered OUTSIDE it. So the case texture was drawing correctly, at no size, while the
compartments floated in front of it, and three passes of art tuning changed nothing because the art
was never the problem. `PanelContainer` sizes to its child and applies the stylebox's content
margins, which is what the insets should have been all along.

### Three findings from the brief that the tree overruled

1. **BURDEN was rejected and replaced.** Every instrument costs exactly one slot, so a weight
   line would either restate `PACKED: n/4` or reintroduce the per-item cost TD-091 cut. The slot
   now shows the pack's **shape** — `SET TO READ` / `SET TO TEST` / `EVENLY SET` — which is the
   Observe/Test tradeoff the two groups exist to make, and says something the count cannot.
2. **The stacked layout does not fit.** `get_viewport_rect()` returns the **logical** 640x360, so
   the sheet is ~250 units tall while the brief's composition is ~370. Three columns is the honest
   adaptation; the brief's §22 makes the project's resolution the source of truth.
3. **`capacity_cost`, audio files and expedition history were not built.** Per-item cost is (1)
   again; there is no audio system (T262 blocked — hooks only, no placeholder files); and the
   Field Testament is a stub hard-coding `outcome: 'success'`, so a history panel would be
   fabricated data, which the brief's §10 forbids.

## Phase B — the Stipend — **CUT (TD-091, 2026-08-08)**

> The author cut the Stipend: `BAG_SLOTS` is the economy and there is **no currency in Testament**.
> The three tasks below are kept as the record and **will not be built**. Reasoning in TD-091 and in
> the Phase B banner of `requirements.md`; the short version is that gear items are *keys*, so a flat
> price is a no-op and a varied price is the ladder `loadout-economy.md` non-negotiable 2 forbids.

- [~] T334 **SUPERSEDED** (no prices exist; `GearItem` gains nothing) — [R322] — `price` +
      `description` on `GearItem` and every `GEAR_CATALOG` entry; shared stays types + constants
      only (I4).

- [~] T335 **SUPERSEDED** (no `stipend` on the room; `REQUISITION` keeps validating slots only) —
      [R323, P148 / V3] — `stipend` on `RoomRecord`, initialised at `createRoom` from
      `STARTING_STIPEND`; `REQUISITION` validates cost against the balance as well as `BAG_SLOTS`.

- [~] T336 **SUPERSEDED** (there is no balance to show) — [R324, R325 / V4] — The client shows the
      remaining balance as something the player can feel, not a spreadsheet.

## The open follow-up (not yet a task — needs an author ruling)

**Consumable charges on probe kits.** `generateTraitRoll` draws `ward` independently of `frailty`
from the same four values, and `deriveReaction` only ever fires on an exact match — so carrying all
four kits is a **guaranteed four-step lookup** of the one probe-gated axis, free at 3+ players. That
is a memorizable *procedure* standing in for a read. Charges fix it, need no pricing decision, and
are already implied by `docs/systems/investigation-and-probing.md` ("resupply of **consumable**
probes"). TD-091 also records three unfixed findings: `exposure` is written but read by nothing,
`deploy.ts:87`'s `isSolo` counts ghosts, and an Apprentice probe kit is a guaranteed null.

## Do not re-invent

`specs/station-ui/` T125–T130 already covers the Stipend economy. Its **server** half (T125/T126) is
the plan of record and is folded into Phase B above; its **client** half (T127–T129) predates the
writ idiom, the muster point (TD-088) and the popup restyle (TD-089), and is superseded here.

## Standing constraints

- **Do not touch the Contract Board or any finished spec** unless the work requires it or the author
  asks (`.claude/rules/spec-workflow.md`).
- The client sends intentions; the server validates (I1/I2).
- Budget stated in `design.md`: no new particles, no additive layer, nothing per frame.
