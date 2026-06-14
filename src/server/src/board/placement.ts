import type { RelicBoard, Relic, RelicId } from '@veins/shared';
import type {
  PlaceRelicRequest,
  GamePhase,
  RelicPlacedEvent,
  RelicPlaceErrorEvent,
} from '@veins/shared';
import { hexCoordKey } from '@veins/shared';
import { evaluateSynergies } from './synergy.js';

export type PlaceRelicSuccess = {
  ok: true;
  board: RelicBoard;
  event: RelicPlacedEvent;
};

export type PlaceRelicFailure = {
  ok: false;
  error: RelicPlaceErrorEvent;
};

export type PlaceRelicResult = PlaceRelicSuccess | PlaceRelicFailure;

export function placeRelic(
  board: RelicBoard,
  request: PlaceRelicRequest,
  phase: GamePhase,
  registry: Map<RelicId, Relic>
): PlaceRelicResult {
  if (phase !== 'loot') {
    return {
      ok: false,
      error: { code: 'WRONG_PHASE', message: 'Relics can only be placed during the loot phase.' },
    };
  }

  const key = hexCoordKey(request.coord);
  const slot = board.slots[key];

  if (slot === undefined) {
    return {
      ok: false,
      error: { code: 'INVALID_COORD', message: 'That coordinate is not on the board.' },
    };
  }

  if (slot.relicId !== null) {
    return {
      ok: false,
      error: { code: 'SLOT_OCCUPIED', message: 'That slot is already occupied.' },
    };
  }

  const newBoard: RelicBoard = {
    slots: {
      ...board.slots,
      [key]: { ...slot, relicId: request.relicId },
    },
  };

  return {
    ok: true,
    board: newBoard,
    event: {
      coord: request.coord,
      relicId: request.relicId,
      ownerId: request.ownerId,
      synergyMap: evaluateSynergies(newBoard, registry),
    },
  };
}
