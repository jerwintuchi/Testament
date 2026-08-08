import type { ItemId } from '@testament/shared';
import { BAG_SLOTS, GEAR_CATALOG } from '@testament/shared';
import type { RoomManager } from '../RoomManager.js';
import type { EmitFn, BroadcastFn } from '../types.js';
import { assertAnyPhase } from '../phaseGuard.js';
import { atStation } from '../stations.js';
import { toSnapshot } from '../snapshot.js';
import { SERVER_MESSAGES } from '@testament/shared';

const CATALOG_IDS = new Set(GEAR_CATALOG.map(g => g.id));

export function handleRequisition(
  socketId: string,
  payload: unknown,
  roomManager: RoomManager,
  emit: EmitFn,
  broadcast: BroadcastFn,
): void {
  const p = payload as Record<string, unknown> | null;
  const itemIds = p !== null && typeof p === 'object' ? p['itemIds'] : undefined;
  if (!Array.isArray(itemIds) || itemIds.some(id => typeof id !== 'string')) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'INVALID_PAYLOAD', message: 'Payload must include an itemIds array of strings.' });
    return;
  }
  const ids = itemIds as ItemId[];

  const unknown = ids.find(id => !CATALOG_IDS.has(id));
  if (unknown !== undefined) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'UNKNOWN_ITEM', message: `No such item in the catalog: ${unknown}` });
    return;
  }
  if (new Set(ids).size !== ids.length) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'INVALID_PAYLOAD', message: 'Duplicate items in requisition.' });
    return;
  }
  if (ids.length > BAG_SLOTS) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'BAG_OVERFLOW', message: `The bag holds at most ${BAG_SLOTS} items.` });
    return;
  }

  // Packing is legal while the contract is KNOWN and the party has not deployed
  // (R65) — which is exactly what this now checks. It used to require DEPLOYING,
  // strictly narrower than the requirement it cited: the contract is known from
  // SELECT_CONTRACT onward, and DEPLOYING only begins at the Deploy Gate's first
  // press. That gap made the leader cross the hall three times (board -> gate ->
  // counter -> gate) and left everyone else at a shut counter until someone else
  // acted (TD-096, author ruling after playtest).
  //
  // Still bounded on both sides: no contract means nothing to bet on, and once the
  // party is in FIELD the bag is fixed — you may re-pack freely while deciding, but
  // never after seeing a sign.
  const room = roomManager.getRoomBySocketId(socketId);
  if (!assertAnyPhase(room, ['WAITING', 'DEPLOYING'], emit)) return;
  if (room.contract === null) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, {
      code: 'NO_CONTRACT_SELECTED',
      message: 'The Collegium issues instruments against a charge. Take one from the board first.',
    });
    return;
  }

  // Own bag only: the sender is resolved by socket, so there is no way to pack
  // another Seeker's bag. Replace-not-merge: the payload is the whole bag.
  const sender = room.players.find(pl => pl.socketId === socketId)!;
  // Requisition is an action at the Quartermaster (R100): stand there to pack.
  if (!atStation(sender.pos, 'QUARTERMASTER')) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_AT_QUARTERMASTER', message: 'Stand at the Quartermaster to requisition gear.' });
    return;
  }
  sender.bag = ids;

  broadcast(room.code, SERVER_MESSAGES.LOBBY_UPDATED, { snapshot: toSnapshot(room) });
}
