import { describe, it, expect } from 'vitest';
import { allReady } from './readyCheck.js';
import type { ServerPlayerEntry } from './types.js';

function p(ready: boolean, disconnectedAt: number | null = null): ServerPlayerEntry {
  return { playerId: 'x', displayName: 'x', socketId: 'x', isLeader: false, readyState: ready, disconnectedAt, perceivedChannels: [], bag: [], pos: null, moveIntent: { dx: 0, dy: 0 } };
}

// T8: all-ready check

describe('allReady', () => {
  it('returns true when all players are ready', () => {
    expect(allReady([p(true), p(true)])).toBe(true);
  });

  it('returns false when any player is not ready', () => {
    expect(allReady([p(true), p(false)])).toBe(false);
  });

  it('returns true for a single ready player', () => {
    expect(allReady([p(true)])).toBe(true);
  });

  it('returns true for an empty array (vacuous)', () => {
    expect(allReady([])).toBe(true);
  });

  // T89 (R78): ghosts never deadlock acceptance.
  it('ignores a not-ready DISCONNECTED player (ghost cannot veto)', () => {
    expect(allReady([p(true), p(false, Date.now())])).toBe(true);
  });

  it('still blocks on a not-ready CONNECTED player', () => {
    expect(allReady([p(true), p(false), p(true, Date.now())])).toBe(false);
  });
});
