import { FIELD_TICK_HZ, SERVER_MESSAGES } from '@testament/shared';
import type { PositionsPayload } from '@testament/shared';
import type { RoomRecord, BroadcastFn } from './types.js';
import { stepPlayer } from '../site/movement.js';

// The authoritative 20Hz movement integrator (I1, R87). Each tick advances every
// connected player by their stored MOVE intent through the pure stepPlayer, then
// broadcasts a single POSITIONS *delta* naming only the players who actually
// moved (I6/P45) — an all-idle tick sends nothing. Client message rate cannot
// beat SEEKER_SPEED because intent is a direction sampled once per tick, not a
// position.

const TICK_MS = 1000 / FIELD_TICK_HZ;

function runTick(room: RoomRecord, broadcast: BroadcastFn): void {
  if (room.site === null) return;
  const moved: PositionsPayload['positions'] = {};
  for (const player of room.players) {
    // Only connected players with a spawned position integrate; a disconnected
    // ghost has zeroed intent (disconnect handler) and is skipped regardless.
    if (player.disconnectedAt !== null || player.pos === null) continue;
    const { dx, dy } = player.moveIntent;
    const next = stepPlayer(player.pos, dx, dy, TICK_MS, room.site.grid);
    if (next.x !== player.pos.x || next.y !== player.pos.y) {
      player.pos = next;
      moved[player.playerId] = next;
    }
  }
  if (Object.keys(moved).length > 0) {
    broadcast(room.code, SERVER_MESSAGES.POSITIONS, { positions: moved } satisfies PositionsPayload);
  }
}

// Idempotent start: if a tick is already running for this room, do nothing.
export function startFieldTick(room: RoomRecord, broadcast: BroadcastFn): void {
  if (room.fieldTick !== null) return;
  room.fieldTick = setInterval(() => runTick(room, broadcast), TICK_MS);
}

export function stopFieldTick(room: RoomRecord): void {
  if (room.fieldTick !== null) {
    clearInterval(room.fieldTick);
    room.fieldTick = null;
  }
}
