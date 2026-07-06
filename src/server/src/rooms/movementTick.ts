import { FIELD_TICK_HZ, SERVER_MESSAGES } from '@testament/shared';
import type { SiteGrid, PositionsPayload } from '@testament/shared';
import type { RoomRecord, BroadcastFn } from './types.js';
import { stepPlayer } from '../site/movement.js';
import { COLLEGIUM } from '../collegium/collegium.js';

// The authoritative 20Hz movement integrator (I1, R96). One tick per room, live
// for the room's whole walkable life (WAITING → DEPLOYING → FIELD). Each tick
// advances every connected player by their stored MOVE intent through the pure
// stepPlayer against the phase's *active grid* — the Collegium in the lobby, the
// generated site in the field — then broadcasts a single POSITIONS *delta*
// naming only the players who actually moved (I6/P45); an all-idle tick sends
// nothing. Client message rate cannot beat SEEKER_SPEED because intent is a
// direction sampled once per tick, not a position.

const TICK_MS = 1000 / FIELD_TICK_HZ;

// What is the party walking on right now? Collegium in the lobby phases, the
// generated site in the field, nothing once the expedition is COMPLETE.
export function activeGrid(room: RoomRecord): SiteGrid | null {
  switch (room.phase) {
    case 'WAITING':
    case 'DEPLOYING':
      return COLLEGIUM.grid;
    case 'FIELD':
      return room.site?.grid ?? null;
    case 'COMPLETE':
      return null;
  }
}

function runTick(room: RoomRecord, broadcast: BroadcastFn): void {
  const grid = activeGrid(room);
  if (grid === null) return;
  const moved: PositionsPayload['positions'] = {};
  for (const player of room.players) {
    // Only connected players with a spawned position integrate; a disconnected
    // ghost has zeroed intent (disconnect handler) and is skipped regardless.
    if (player.disconnectedAt !== null || player.pos === null) continue;
    const { dx, dy, walk } = player.moveIntent;
    const next = stepPlayer(player.pos, dx, dy, TICK_MS, grid, walk === true);
    if (next.x !== player.pos.x || next.y !== player.pos.y) {
      player.pos = next;
      moved[player.playerId] = next;
    }
  }
  if (Object.keys(moved).length > 0) {
    broadcast(room.code, SERVER_MESSAGES.POSITIONS, { positions: moved } satisfies PositionsPayload);
  }
}

// Idempotent start: if a tick is already running for this room, do nothing. The
// grid it collides against swaps under it as the room changes phase (activeGrid),
// so DEPLOY never restarts it.
export function startMovementTick(room: RoomRecord, broadcast: BroadcastFn): void {
  if (room.moveTick !== null) return;
  room.moveTick = setInterval(() => runTick(room, broadcast), TICK_MS);
  // Don't let the movement tick alone keep the process alive: the WS server holds
  // the event loop open in production, and unit tests that seed a room without
  // tearing it down won't hang on a dangling interval.
  room.moveTick.unref?.();
}

export function stopMovementTick(room: RoomRecord): void {
  if (room.moveTick !== null) {
    clearInterval(room.moveTick);
    room.moveTick = null;
  }
}
