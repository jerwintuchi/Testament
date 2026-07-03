import type { ItemId } from '@testament/shared';
import { BAG_SLOTS, GEAR_CATALOG } from '@testament/shared';
import type { RoomManager } from '../RoomManager.js';
import type { EmitFn, BroadcastFn } from '../types.js';
import { assertPhase } from '../phaseGuard.js';
import { toSnapshot } from '../snapshot.js';

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
    emit('LOBBY_ERROR', { code: 'INVALID_PAYLOAD', message: 'Payload must include an itemIds array of strings.' });
    return;
  }
  const ids = itemIds as ItemId[];

  const unknown = ids.find(id => !CATALOG_IDS.has(id));
  if (unknown !== undefined) {
    emit('LOBBY_ERROR', { code: 'UNKNOWN_ITEM', message: `No such item in the catalog: ${unknown}` });
    return;
  }
  if (new Set(ids).size !== ids.length) {
    emit('LOBBY_ERROR', { code: 'INVALID_PAYLOAD', message: 'Duplicate items in requisition.' });
    return;
  }
  if (ids.length > BAG_SLOTS) {
    emit('LOBBY_ERROR', { code: 'BAG_OVERFLOW', message: `The bag holds at most ${BAG_SLOTS} items.` });
    return;
  }

  // Packing is only legal while the contract is known and the party has not
  // deployed (R65): the bag is a bet on the contract's intel.
  const room = roomManager.getRoomBySocketId(socketId);
  if (!assertPhase(room, 'DEPLOYING', emit)) return;

  // Own bag only: the sender is resolved by socket, so there is no way to pack
  // another Seeker's bag. Replace-not-merge: the payload is the whole bag.
  const sender = room.players.find(pl => pl.socketId === socketId)!;
  sender.bag = ids;

  broadcast(room.code, 'LOBBY_UPDATED', { snapshot: toSnapshot(room) });
}
