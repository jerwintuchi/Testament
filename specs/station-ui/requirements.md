# Requirements — Station UI v2 (Preparation Loop, Themed) 

> Phase 5, spec 4. Turns the three functional station popups
> (`specs/collegium-client` v1) into the full **preparation loop** the mockup
> depicts — a browsable **Contract Board**, a **Quartermaster** with a Stipend
> economy and item detail, and a **Deploy Gate** summary — in the gothic
> parchment-and-gold aesthetic already prototyped (`assets/ui/panel.png`,
> `_build_popup_theme`).
>
> **Canon this spec honors (do not re-litigate):**
> - *The board is free, the rank is the gate* — Seekers browse a **pool** of
>   contracts and pick one; Rank gates tier (`docs/systems/contracts.md`, TD-012).
> - *Intel is partial and trait-free* — a contract card shows only `ContractIntel`
>   (`toContractIntel`), never the hidden trait roll (invariant I3/I5). **No
>   Incarnate art on the board** — mystery is the mechanic (vision.md pillar 3).
> - *Funded by the Stipend, priced by utility not power* — gear has a Stipend
>   **price** keyed to the capability/channel it unlocks, never a power ladder
>   (`docs/systems/loadout-economy.md`, TD-017).
> - *Roles emerge from the loadout, never a class pick* (GLOSSARY, Hunter-Scholar)
>   — the Deploy Gate shows each Seeker's **bag**, not an assigned class/role.
>
> Numbering continues: **R109+**, correctness **P58+**, tasks **T122+**. Trust
> boundary unchanged: server authoritative, client render+intent only (I1/I2).

---

## Phase A — Contract Board (a pool, selectable)

**R109** (server): the room holds a seeded **contract board** — a pool of
contracts generated at room creation, delivered to clients as intel only.
- AC: on room creation the server generates `BOARD_SIZE` contracts via the
  existing pure `generateContract` (seeded from the expedition seed), stored on
  the room; regenerating with the same seed yields the same board (determinism, I3).
- AC: the `LobbySnapshot` carries the board as `ContractIntel[]` (via
  `toContractIntel`); **no board entry contains any hidden trait-roll field**
  (I3/I5 — assert the serialized board has only intel keys).
- AC: each board entry has a stable `contractId` usable to select it.

**R110** (server): the leader **selects** a contract from the board; selection is
the acceptance that stakes the Surety and moves the room to DEPLOYING.
- AC: `SELECT_CONTRACT { contractId }` is honored only when the sender is the
  **leader**, standing at the **CONTRACT_BOARD**, in **WAITING**, party **ready**,
  and `contractId` is on the board — else the matching error
  (`NOT_LEADER` / `NOT_AT_CONTRACT_BOARD` / `WRONG_PHASE` / `PARTY_NOT_READY` /
  `UNKNOWN_CONTRACT`) to that sender only, no state change (I2).
- AC: on success the room's active contract becomes the chosen board entry and the
  phase becomes DEPLOYING (the existing `ROOM_DEPLOYING` broadcast carries its
  intel). The pre-existing single-contract `ACCEPT_CONTRACT` path is retired or
  redefined in terms of selection (design decides), with its tests updated.

**R111** (client): the Contract Board popup renders the pool as parchment cards,
no Incarnate art, and drives selection.
- AC: one card per board entry showing `targetName`, `siteName`, threat as pips
  derived from `tier`, and `primaryVerb`; **no image/sprite of the target**.
- AC: selecting a card shows its detail (the same intel, larger) with an **Accept**
  action (leader only) that sends `SELECT_CONTRACT`; a raced `NOT_*`/`PARTY_NOT_READY`
  still surfaces in the status line (affordance ≠ authority, P56 heritage).
- AC: threat pips are a pure function of `tier` and never display a numeric trait.

## Phase B — Quartermaster (Stipend economy + item detail)

**R112** (shared): every gear item carries a **Stipend price** and a
player-facing **description**; pricing reflects utility, not power.
- AC: each `GearItem` gains `price: number` (> 0) and `description: string`;
  `GEAR_CATALOG` populates both for every entry.
- AC: prices are authored data (a table), not computed from any power stat; the
  catalog test asserts presence and positivity, and that two items of different
  power tiers are *not* required to be ordered by price (no shopping ladder).
- AC: the catalog stays wire-safe — it carries channels/stimuli/descriptions only,
  never trait-axis values (existing gear invariant).

**R113** (server): the party has an ephemeral **Stipend** balance; requisition is
validated against price **and** bag bound, server-authoritative.
- AC: a room starts with `STARTING_STIPEND`; the snapshot carries the current
  balance. `REQUISITION` is rejected (`INSUFFICIENT_STIPEND`) if the requested
  loadout's total price exceeds the balance, and (existing) rejected if it exceeds
  `BAG_SLOTS` — no state change on rejection (I2).
- AC: on success the actor's bag becomes the requested set and the Stipend balance
  is debited by the loadout's total price (idempotent re-requisition recomputes
  from the catalog, never drifting).
- AC: the Stipend is ephemeral session state (I7) — never persisted mid-run.

**R114** (client): the Quartermaster popup shows the catalog grid, a detail panel,
the equipped loadout, a slot counter, and the Stipend balance.
- AC: a grid of catalog items; selecting one fills a detail panel with its `name`,
  kind, `description`, and what it **reads/presents** (`channel`/`stimulus`) — the
  "Reads: RESIDUE" line in the mockup.
- AC: an **equipped/loadout** row reflects the current bag; a slot counter shows
  `used / BAG_SLOTS`; the **Stipend balance** and the selected loadout's cost are
  shown; **Requisition** sends the intent and a raced `INSUFFICIENT_STIPEND` /
  slot error still surfaces.

## Phase C — Deploy Gate (expedition summary + party)

**R115** (client): the Deploy Gate popup shows the selected contract summary and
the party (by loadout, not class), with the Deploy action.
- AC: an **expedition summary** from the selected contract: `targetName`,
  `siteName`, `tier` (as threat pips), `primaryVerb` — no invented fields.
- AC: a **party roster** listing each Seeker's display name, ready state, and
  **bag contents** (their emergent role); **no fixed class/role label is assigned**
  (canon: roles emerge from the loadout).
- AC: **Deploy** (leader) sends the existing `DEPLOY` intent; a raced gate error
  still surfaces. The field-deploy flow is otherwise unchanged.

## Cross-cutting

**R116** (trust / trait containment, standing I3/I5): every station payload the
client receives carries intel/vocabulary only.
- AC: the board (`ContractIntel[]`), the active contract (`ContractIntel`), the
  gear catalog (channels/stimuli/descriptions), and the Stipend balance contain
  **no** Incarnate trait-roll axis anywhere on the wire (serialized-shape assertion).

**R117** (client visual system): the three station popups share one themed,
render-only presentation.
- AC: all three use the gothic 9-slice panel + gold-on-charcoal theme
  (`_build_popup_theme`); the **threat-pip** widget and the **contract card** are
  reusable scenes/components; no game logic lives in any of them (they render
  snapshot data and emit the existing intents).

---

## Verification

Server/shared requirements (R109, R110, R112, R113, R116) are verified by Vitest
unit tests colocated with the source (the repo convention), each named in its task
below — determinism, validation/rejection paths, trait-containment shape
assertions, and Stipend accounting. Client requirements (R111, R114, R115, R117)
have no GDScript unit harness (prior client-spec convention), so they are verified
by an extension of the MCP-driven playtest (`specs/station-ui/playtest.md`): the
client logs the load-bearing events (board card count, selection, requisition
cost/balance, deploy summary) for `get_debug_output`, run against `pnpm dev:server`.
