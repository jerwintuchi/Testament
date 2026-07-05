import type { RoomRecord, ServerPlayerEntry } from './types.js';
import { spawnFanOut } from '../site/spawn.js';
import { COLLEGIUM } from '../collegium/collegium.js';

// Place a player in the Collegium on entry (R95): a distinct floor tile fanned
// from the spawn anchor, indexed by the player's slot in the room so no two
// present players share a tile. Deterministic (spawnFanOut is), so the Nth
// present player always lands on the Nth fan-out tile. Sets moveIntent to rest.
export function spawnInCollegium(room: RoomRecord, player: ServerPlayerEntry): void {
  const spawns = spawnFanOut(COLLEGIUM.grid, COLLEGIUM.spawn, room.players.length);
  const idx = room.players.indexOf(player);
  player.pos = spawns[idx] ?? spawns[spawns.length - 1]!;
  player.moveIntent = { dx: 0, dy: 0 };
}
