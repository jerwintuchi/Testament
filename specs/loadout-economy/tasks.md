# Tasks — Loadout & Bag Economy (v1)

> T# numbering continues from T67 (distributed-perception spec). Every task names
> its test before implementation (spec-workflow golden rule).

- [x] T68 [R64, P30] — Create `src/shared/src/gear.ts` (`ItemId`, `GearItem`,
  `BAG_SLOTS`, `GEAR_CATALOG`); export from index; add `RequisitionPayload` and
  the `UNKNOWN_ITEM` / `BAG_OVERFLOW` / `MISSING_GEAR` error codes to
  `src/shared/src/lobbyMessages.ts`; add `bag: ItemId[]` to `LobbyPlayer` in
  `src/shared/src/lobby.ts`.
  Test: `src/shared/src/gear.test.ts` — exactly one PERCEPTION item per channel,
  one PROBE item per stimulus, unique ids, `BAG_SLOTS === 4`, no axis value
  literal anywhere in the catalog JSON.

- [x] T69 [R66, R67, P32] — Implement `perceivedChannelsFor(bag, isSolo, tier)`
  and `hasProbeKit(bag, stimulus)` in `src/server/src/rooms/perception.ts`;
  delete `assignPerception` and `MIN_CHANNELS_PER_PLAYER` (spec 5's interim
  source, replaced per TD-026/TD-027).
  Test: `src/server/src/rooms/perception.test.ts` — solo gets `channelsForTier`
  at every tier regardless of bag; party perception equals exactly the carried
  PERCEPTION channels in canonical order (probe kits contribute none); empty bag
  → empty set; `hasProbeKit` true only for the matching carried kit; the
  assignPerception tests are removed.

- [x] T70 [R64, R68] — Add `bag: ItemId[]` to `ServerPlayerEntry` (empty at
  create/join) and to `toPublicPlayer`.
  Test: `src/server/src/rooms/types.test.ts` — `toPublicPlayer` includes `bag`;
  `src/server/src/rooms/RoomManager.test.ts` — a created room's player has an
  empty bag.

- [x] T71 [R65, P31] — Implement `handleRequisition` in
  `src/server/src/rooms/handlers/requisition.ts`; route `REQUISITION` in
  `src/server/src/rooms/messageRouter.ts`.
  Test: `src/server/src/rooms/handlers/requisition.test.ts` — non-array /
  non-string ids → `INVALID_PAYLOAD`; unknown id → `UNKNOWN_ITEM`; duplicate ids
  → `INVALID_PAYLOAD`; 5 items → `BAG_OVERFLOW`; WAITING or FIELD phase →
  `WRONG_PHASE`; no room → `NOT_IN_ROOM`; all rejections leave the bag untouched
  and broadcast nothing; a valid requisition replaces the bag (including with
  `[]`) and broadcasts `LOBBY_UPDATED` whose snapshot carries the bags;
  `src/server/src/rooms/messageRouter.test.ts` — `REQUISITION` reaches the
  handler.

- [x] T72 [R66, P32] — `handleDeploy` derives each player's `perceivedChannels`
  via `perceivedChannelsFor` (solo rule included); the seeded-assignment block
  is removed.
  Test: `src/server/src/rooms/handlers/deploy.test.ts` — solo with an empty bag
  still perceives the full tier set and receives all ambient signs; in a
  2-player room each player's `FIELD_STARTED` signs match their gear channels
  exactly (a player with no perception gear receives no signs); the spec 5
  seeded-assignment tests are replaced.

- [x] T73 [R67, P33] — `handleProbe` rejects a probe without the matching kit
  (`MISSING_GEAR`) before any mutation.
  Test: `src/server/src/rooms/handlers/probe.test.ts` — probe without the kit →
  `MISSING_GEAR` to sender only, exposure unchanged, nothing delivered; probe
  with the kit behaves as spec 5 (existing tests updated to pack kits); solo
  needs the kit too.

- [x] T74 [R64–R68, P30–P34] — Integration: extend
  `src/server/src/rooms/field.integration.test.ts` — during DEPLOYING the party
  requisitions (host: Witness Prism + Phial of Hoarfrost; p2: Ashen Lens +
  Censer of Embers), both see each other's bags via `LOBBY_UPDATED`; after
  DEPLOY each player's signs match their gear; a probe without the kit is
  rejected; a probe with the kit delivers per spec 5 filtering; a reconnecting
  player's snapshot still shows the party's bags and their own gear-derived
  channels; update existing scenarios for the new flows.
