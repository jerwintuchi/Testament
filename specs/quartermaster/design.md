# Design — The Quartermaster (TD-090)

> Satisfies R318–R325. **Phase A is client-only and shippable alone**; Phase B needs an author
> decision first (see the requirements' open questions).

---

## Where the code is

| what | where |
|---|---|
| the station body | `client/scripts/main.gd`, `_station_body`, case `"QUARTERMASTER"` |
| the popup sheet | `client/scripts/ui/popup_theme.gd` — **panel + tooltip only, deliberately** |
| ink helpers | `main.gd` `_popup_label`, `_popup_button`, `_ink_action`, `_muster_row` |
| the writ vocabulary | `client/scripts/ui/writ_form.gd` — `toggle`, `slider`, `action`, the diamond |
| the gear list | `client/scripts/core/catalog.gd` (`Catalog.GEAR`, `BAG_SLOTS`, `item_label`) |
| the model | `src/shared/src/gear.ts` |

## Phase A — the form

The pieces already exist; this is assembly, not invention. `WritForm.toggle` is an **inked square
struck through with an X** — that is the mark a chosen item wants, and it is already the language of
the options writ. `_ink_action` gives a button the ruled underline.

**The slots are the headline.** Four slots, drawn as four marks that fill — occupied and empty
visible at once — because bounded capacity is the mechanic, not a footnote. A sentence reading
"Requisition: 2 of 4 slots" makes the player parse a number to learn something a row of four marks
says instantly.

**Each item says what it does**, in the player's language: `PERCEPTION`/`channel` becomes "Reads
Residue", `PROBE`/`stimulus` becomes what presenting it means. `StationNames.of` (R224) is the
precedent — the player never reads a wire enum. There are **no ratings**: vision.md's "no knowledge
as a number" is about Incarnates, but the same reasoning kills a "power: 3" on a lens.

### The trap this spec exists downstream of

Style **only in the builders**. The popup `Theme` is shared with the Contract Board, whose notice
cards are `Button`s laid out by `_fit_writ` — which *measures* each writ against the font it will be
drawn in. A `Label`/`Button` font in the Theme silently re-flows the board (TD-089). The Theme
carries the sheet; the builders carry the ink.

## Phase B — the Stipend

Shape only; the numbers are the author's.

```
shared   GearItem gains  price, description        (types + constants only — I4)
         STARTING_STIPEND
server   RoomRecord gains stipend, set at createRoom
         REQUISITION validates cost <= stipend AND size <= BAG_SLOTS
         rejects over-budget with a reason (I2)
client   shows the remaining balance; the list is an affordance, never authority
```

The Stipend is **expedition state**: server memory, never persisted (I7 / TD-006, and TD-082's
reasoning about what may cross to disk).

## Performance budget (canon)

Trivial by construction, and stated so it is not skipped: **no new particles, no additive layer, no
`_process`**. The popup is rebuilt on open, which already happens; nothing here runs per frame. If
the item list ever grows past a screen it scrolls in the existing `ScrollContainer` rather than
paginating.

## Files

**Phase A:** `client/scripts/main.gd` (the `"QUARTERMASTER"` body) and, if the slot marks or item
rows want their own builders, `client/scripts/ui/writ_form.gd`.
**Phase B:** `src/shared/src/gear.ts`, `src/server/src/rooms/…` (record + `REQUISITION` handler and
their colocated tests), plus the client's balance display.

## Correctness Properties

- **P148 (the bag is the server's):** slots and cost are validated server-side.
- **P149 (no number stands for knowledge):** gear is described by what it does; price is a cost.
