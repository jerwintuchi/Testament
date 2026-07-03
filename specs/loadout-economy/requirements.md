# Requirements — Loadout & Bag Economy (v1)

> Phase 4, spec 6. Where Pillar 1 (preparation) and Pillar 4 (cooperation) become
> one decision (TD-007, docs/systems/loadout-economy.md): every Seeker packs a
> bounded bag during DEPLOYING, and what the party carries decides who can read
> which channels and who can probe with what.
>
> **v1 scope.** A minimal gear catalog ships inside this spec (the SIGN_LEXICON
> precedent): 6 perception gear items (one per channel) and 4 probe kits (one per
> stimulus). Rites and combat tools are deferred (no system consumes them yet).
> The bag-slot budget is the only constraint; Stipend pricing and the Surety are
> deferred to the economy spec. Probes are reusable in v1; consumable probes and
> cache resupply arrive with sites.
>
> Perception source changes: the interim seeded assignment from spec 5 (TD-026)
> is replaced by gear-derived perception for parties. Solo still perceives all
> tier channels regardless of gear (TD-008: solo is balanced by tempo and bag
> pressure, never by withholding information). The filtering machinery from
> spec 5 is unchanged.
>
> R# numbering continues from R63 (distributed-perception spec).

---

## Functional Requirements

**R64**: As the shared wire protocol, the gear catalog is typed data with no
trait information.
- AC: `GearItem` is `{ id: ItemId; name: string } & ({ kind: 'PERCEPTION'; channel: Channel } | { kind: 'PROBE'; stimulus: Stimulus })`,
  exported from `src/shared/src/gear.ts` along with `ItemId = string` and
  `BAG_SLOTS = 4`.
- AC: `GEAR_CATALOG` contains exactly one PERCEPTION item per `Channel` (6) and
  one PROBE item per `Stimulus` (4), with unique ids. It references no trait
  type or axis value.
- AC: `RequisitionPayload = { itemIds: ItemId[] }` (client → server) is exported
  from `src/shared/src/lobbyMessages.ts` (it is a lobby-phase action);
  `LobbyErrorCode` gains `'UNKNOWN_ITEM' | 'BAG_OVERFLOW'`, and
  `'MISSING_GEAR'` for the probe path.
- AC: `LobbyPlayer.bag: ItemId[]` is a required field, so every `LobbySnapshot`
  (lobby updates, reconnect) shows the party's packed bags — coordination is
  the point, bags are not secret within the party.

**R65**: As the server, `REQUISITION` validates and replaces the sender's bag
during DEPLOYING.
- AC: Payload must be an array of strings; each id must exist in `GEAR_CATALOG`
  (else `UNKNOWN_ITEM`); duplicates are rejected (`INVALID_PAYLOAD`); more than
  `BAG_SLOTS` items → `BAG_OVERFLOW`. Errors go to the sender only; no state
  change, no broadcast.
- AC: Only legal in DEPLOYING phase (`WRONG_PHASE` otherwise; `NOT_IN_ROOM` when
  the socket has no room). The contract is known during DEPLOYING, so packing is
  a bet on its (falsifiable) intel.
- AC: A valid `REQUISITION` replaces the sender's bag (idempotent; an empty
  array empties it) and broadcasts `LOBBY_UPDATED` with the room snapshot, whose
  player entries carry the updated bags. Any player may requisition their own
  bag; nobody can set another Seeker's.

**R66**: As the server, perception is derived from gear at DEPLOY.
- AC: `perceivedChannelsFor(bag, isSolo, tier)` is a pure function: solo →
  `channelsForTier(tier)` regardless of bag; party → the channels of the
  PERCEPTION items carried, in canonical order.
- AC: `handleDeploy` sets each player's `perceivedChannels` from their bag via
  this function; the seeded `assignPerception` from spec 5 is deleted (its
  purpose is fulfilled; the filtering machinery of TD-026 is untouched).
- AC: A party that packs no perception gear for a channel is blind on it — union
  coverage is now the party's responsibility, not the server's guarantee
  (preparation is a bet, loadout-economy non-negotiable 4).

**R67**: As the server, probing requires the matching probe kit.
- AC: A `PROBE` whose sender does not carry the PROBE item for that stimulus →
  `LOBBY_ERROR` code `MISSING_GEAR` to the sender only; no exposure, no
  delivery, no state change.
- AC: Carrying the kit makes the probe legal for every player, solo included
  (solo's balance is bag pressure: reading is free, testing is not).
- AC: Probe kits are reusable in v1 — probing does not remove the item.

**R68**: As the server, bags follow the player entry across the room lifecycle.
- AC: `ServerPlayerEntry.bag: ItemId[]` starts empty at room creation/join and
  survives reconnection (keyed to playerId, like perception).
- AC: A reconnecting player's `STATE_RESYNC` snapshot shows all players' current
  bags (via `LobbyPlayer.bag`).
