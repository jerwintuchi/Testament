import type { ServerPlayerEntry } from './types.js';

// Pure function. Returns true when all CONNECTED players are ready (R78):
// a disconnected ghost must never deadlock contract acceptance — it cannot
// toggle ready (no socket) and its seat is held for reconnection, not for veto.
// Vacuously true for empty/all-ghost input, but unreachable that way in
// practice: the accepter is the connected leader, and a room whose last player
// disconnects is destroyed before any intent can arrive.
export function allReady(players: ServerPlayerEntry[]): boolean {
  return players
    .filter(p => p.disconnectedAt === null)
    .every(p => p.readyState === true);
}
