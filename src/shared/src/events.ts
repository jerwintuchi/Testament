import type { HexCoord, RelicId, PlayerId, SynergyMap, RelicBoard, Relic } from './board.js';

export type GamePhase = 'loot' | 'combat' | 'transition';

// Client -> Server
export type PlaceRelicRequest = {
  coord: HexCoord;
  relicId: RelicId;
  ownerId: PlayerId;
};

// Server -> Room (broadcast)
export type RelicPlacedEvent = {
  coord: HexCoord;
  relicId: RelicId;
  ownerId: PlayerId;
  synergyMap: SynergyMap;
};

// Server -> Socket (targeted error)
export type RelicPlaceErrorEvent = {
  code: 'SLOT_OCCUPIED' | 'WRONG_PHASE' | 'INVALID_COORD';
  message: string;
};

// Server -> Socket (on room join)
export type BoardStateSyncEvent = {
  board: RelicBoard;
  synergyMap: SynergyMap;
  relicRegistry: Record<RelicId, Relic>;
};

// Server -> Room (broadcast, before a Linked Fates transfer)
export type RelicRemovedEvent = {
  coord: HexCoord;
  relicId: RelicId;
  reason: 'linked-fates' | 'run-end';
};
