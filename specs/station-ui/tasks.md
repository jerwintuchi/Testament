# Tasks — Station UI v2 (Preparation Loop, Themed)

> **AUDITED 2026-07-24 (TD-074) — READ THIS BEFORE TRUSTING CLAUDE.md ON THIS SPEC.**
> CLAUDE.md described this as "Stipend-priced Quartermaster and Deploy Gate … shipped
> server/shared-side". **That was wrong.** The Stipend economy does not exist anywhere in the
> tree: `grep -rn "stipend\|price\|STARTING_STIPEND" src/` returns **nothing**. `GearItem` is
> still `{ id, name } & ({kind:'PERCEPTION',channel} | {kind:'PROBE',stimulus})` — no `price`, no
> `description`. `handleRequisition` validates `BAG_SLOTS` only; there is no
> `INSUFFICIENT_STIPEND`. The claim has been corrected in CLAUDE.md.
>
> Actual state, task by task:
> - **T122–T123 (server) — DONE.** The board pool and reversible leader `SELECT_CONTRACT` ship
>   and are tested; the notice-board spec reuses them unchanged.
> - **T124 (client board) — SUPERSEDED.** Replaced by the Notice Board render, and its
>   `ThreatPips` were later deleted outright (TD-061).
> - **T125–T126 (Stipend economy, server/shared) — NOT BUILT.** Real, unstarted work. `Stipend`
>   is a canonical GLOSSARY term and part of the preparation pillar ("spent to requisition the
>   loadout and to place the Surety"), so this is a genuine gap, not dead scope.
> - **T127–T128 (client Quartermaster / Deploy Gate) — NOT BUILT.** The Quartermaster is still a
>   plain `CheckBox` list with a slot counter and one "Requisition (replaces your bag)" button;
>   the Deploy Gate is a single "DEPLOY the expedition" button. No prices, no balance, no
>   contract summary, no roster-with-bags. Both depend on T125–T126.
> - **T129 — PARTLY DONE.** The shared theme exists as `ui/popup_theme.gd` (`PopupTheme.build`,
>   TD-067 T226) and every popup wears it; the `threat_pips`/`contract_card` reuse half is moot
>   (pips deleted, TD-061).
> - **T130 — unrun**, and needs two clients.


> T# continues from T121. Order is dependency order and phase order (A → B → C);
> each phase is shippable on its own. Server/shared tasks name a Vitest file;
> client tasks name a `playtest.md` item (no GDScript unit harness — prior
> client-spec convention). Nothing is done without its named test passing.

## Phase A — Contract Board

- [x] T122 [R109 / P58] — `generateBoard(rng, seed, size)` in
      `src/server/src/incarnate/generateBoard.ts`: `BOARD_SIZE` distinct contracts
      via `generateContract`. Add `board: ContractRecord[]` to `RoomRecord`; build
      it in `createRoom`. Add `board: ContractIntel[]` to `LobbySnapshot` +
      snapshot builder (`toContractIntel`).
      Test: `generateBoard.test.ts` — same seed → identical board (determinism);
      board size; ids distinct. `snapshot.test.ts` — board present and every entry
      has **only** `ContractIntel` keys (no trait axis; P58).

- [x] T123 [R110 / P59] — `SELECT_CONTRACT` in the message registry
      (`messages.ts`, regen `protocol.gd` via `pnpm gen:protocol`); add
      `UNKNOWN_CONTRACT`. `handleSelectContract` (guards: in-room, leader,
      at CONTRACT_BOARD, WAITING, ready, id on board) → promote board entry to
      `room.contract`, phase → DEPLOYING, broadcast `ROOM_DEPLOYING`. Reconcile
      `ACCEPT_CONTRACT` (redefine as select-first, or retire) and update its tests.
      Test: `selectContract.test.ts` — each guard rejects to sender only with no
      mutation; unknown id → `UNKNOWN_CONTRACT`; success promotes the *chosen*
      board entry and stakes DEPLOYING (P59).

- [x] T124 [R111 / P62] — Client Contract Board: `scenes/ui/contract_card.tscn`,
      `threat_pips.tscn`, `contract_detail.tscn`; `_build_contract_board()` renders
      `snapshot.board` as cards (name/site/pips/verb, **no art**), selection →
      detail → Accept (leader) → `SELECT_CONTRACT`. Log `board cards=N` / `select <id>`.
      Verify: playtest items 1–2 (board renders with N cards and no Incarnate art;
      leader selects → DEPLOYING; raced `PARTY_NOT_READY`/`NOT_AT` still surfaces).

## Phase B — Quartermaster / Stipend

- [ ] T125 [R112 / P61] — Add `price` + `description` to `GearItem` and every
      `GEAR_CATALOG` entry (authored table, utility-keyed); add `STARTING_STIPEND`.
      Test: `gear.test.ts` — every item has `price > 0` and a non-empty
      `description`; catalog stays wire-safe (no trait axes); prices are not assumed
      monotonic in power (P61).

- [ ] T126 [R113 / P60] — Add `stipend` to `RoomRecord` (init at `createRoom`) and
      `LobbySnapshot`. Extend `handleRequisition`: recompute cost from catalog,
      reject `INSUFFICIENT_STIPEND` (over budget) / slot error (over `BAG_SLOTS`)
      with no mutation, else set bag + debit balance.
      Test: `requisition.test.ts` — over-budget and over-slot mutate nothing;
      success debits exactly the catalog-summed cost; re-requisition recomputes
      without drift; balance never negative (P60).

- [ ] T127 [R114 / P62] — Client Quartermaster: `gear_slot.tscn`, `item_detail.tscn`;
      `_build_quartermaster()` — catalog grid, detail panel (name/kind/description/
      "Reads: <channel>"), equipped row, `used/BAG_SLOTS` + Stipend balance +
      selected cost, **Requisition**. Log `requisition cost=C balance=B`.
      Verify: playtest items 3–4 (grid + detail render; requisition within budget
      succeeds and debits; over-budget raced error surfaces).

## Phase C — Deploy Gate

- [ ] T128 [R115 / P63] — Client Deploy Gate: `_build_deploy_gate()` — contract
      summary (reuse `contract_detail` read-only) + party roster (name · ready ·
      **bag**, no class label) + **Deploy** (leader) → `DEPLOY`. Log `deploy target=<name>`.
      Verify: playtest item 5 (summary from selected contract; roster shows bags,
      no assigned roles; deploy → FIELD_STARTED; raced gate error surfaces).

## Cross-cutting

- [ ] T129 [R117 / P62,P63] — Fold the three builders onto one `ui_theme.gd`
      (extends `_build_popup_theme`); make `threat_pips` + `contract_card` reusable;
      confirm no game logic in any UI scene (render + emit intent only).
      Verify: playtest item 6 (all three popups share the theme; ThreatPips reused
      on board + deploy; a code-review pass finds no logic in `scenes/ui/*`).

- [ ] T130 [R109–R117] — Full MCP playtest pass: run `specs/station-ui/playtest.md`
      (all items) via `run_project` + `get_debug_output` against `pnpm dev:server`,
      two clients for the leader/non-leader gates; fix any GDScript errors; clean
      `stop_project`. Mark the spec complete only when every item passes and the
      full server suite is green.
      Verify: `playtest.md` all items green; `pnpm --filter @testament/server test`
      and `pnpm --filter @testament/shared test` pass.
