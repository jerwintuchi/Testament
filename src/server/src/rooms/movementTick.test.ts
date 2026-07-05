// T108 [R96, R101 / P49, P52]: the generalized 20Hz movement tick integrates
// stored intent authoritatively against the phase's *active grid* (Collegium in
// the lobby, the site in FIELD), broadcasts only moved players as a delta, swaps
// its grid at phase changes without restarting, and never outlives its room.
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { startMovementTick, stopMovementTick, activeGrid } from './movementTick.js';
import { RoomManager } from './RoomManager.js';
import { COLLEGIUM } from '../collegium/collegium.js';
import type { RoomRecord, BroadcastFn, ServerPlayerEntry } from './types.js';
import { FIELD_TICK_HZ, SEEKER_SPEED, SERVER_MESSAGES } from '@testament/shared';
import type { SiteLayout, PositionsPayload } from '@testament/shared';

const TICK_MS = 1000 / FIELD_TICK_HZ;

// A wide-open floored site so movement is never wall-blocked in these tests.
function openSite(): SiteLayout {
  const w = 40;
  const h = 20;
  const rows: string[] = [];
  for (let y = 0; y < h; y++) {
    rows.push(y === 0 || y === h - 1 ? '#'.repeat(w) : '#' + '.'.repeat(w - 2) + '#');
  }
  return { grid: { width: w, height: h, rows }, nodes: [] };
}

// The Collegium spawn tile center — guaranteed floor with room to move.
const SPAWN_PX = { x: COLLEGIUM.spawn.x * 16 + 8, y: COLLEGIUM.spawn.y * 16 + 8 };

function makeBroadcast(): { fn: BroadcastFn; calls: Array<[string, string, unknown]> } {
  const calls: Array<[string, string, unknown]> = [];
  return { fn: (code, type, payload) => calls.push([code, type, payload]), calls };
}

function positionsOnly(calls: Array<[string, string, unknown]>): PositionsPayload[] {
  return calls.filter(c => c[1] === SERVER_MESSAGES.POSITIONS).map(c => c[2] as PositionsPayload);
}

// Builds a room in the given phase with the given players.
function roomWith(
  mgr: RoomManager,
  phase: RoomRecord['phase'],
  players: Array<Partial<ServerPlayerEntry> & { playerId: string; pos: { x: number; y: number } }>,
  site: SiteLayout | null = null,
): RoomRecord {
  const room = mgr.createRoom('host', 'Host');
  room.phase = phase;
  room.site = site;
  room.players = players.map((p, i) => ({
    playerId: p.playerId,
    displayName: p.playerId,
    socketId: `s-${i}`,
    isLeader: i === 0,
    readyState: true,
    disconnectedAt: p.disconnectedAt ?? null,
    perceivedChannels: [],
    bag: [],
    pos: p.pos,
    moveIntent: p.moveIntent ?? { dx: 0, dy: 0 },
  }));
  return room;
}

beforeEach(() => vi.useFakeTimers());
afterEach(() => vi.useRealTimers());

describe('activeGrid (R96 / P49)', () => {
  it('is the Collegium in the lobby, the site in FIELD, nothing in COMPLETE', () => {
    const mgr = new RoomManager();
    const site = openSite();
    const room = roomWith(mgr, 'WAITING', [{ playerId: 'p1', pos: SPAWN_PX }], site);
    expect(activeGrid(room)).toBe(COLLEGIUM.grid);
    room.phase = 'DEPLOYING';
    expect(activeGrid(room)).toBe(COLLEGIUM.grid);
    room.phase = 'FIELD';
    expect(activeGrid(room)).toBe(site.grid);
    room.phase = 'COMPLETE';
    expect(activeGrid(room)).toBeNull();
  });
});

describe('movement tick — integration (R96)', () => {
  it('applies stored intent at SEEKER_SPEED in the FIELD', () => {
    const mgr = new RoomManager();
    const room = roomWith(mgr, 'FIELD', [{ playerId: 'p1', pos: { x: 100, y: 100 }, moveIntent: { dx: 1, dy: 0 } }], openSite());
    const { fn: broadcast, calls } = makeBroadcast();
    startMovementTick(room, broadcast);

    vi.advanceTimersByTime(TICK_MS);
    const expectedStep = SEEKER_SPEED * (TICK_MS / 1000);
    expect(room.players[0]!.pos!.x).toBeCloseTo(100 + expectedStep, 6);
    const payloads = positionsOnly(calls);
    expect(payloads).toHaveLength(1);
    expect(payloads[0]!.positions['p1']!.x).toBeCloseTo(100 + expectedStep, 6);

    stopMovementTick(room);
  });

  it('moves a player against the Collegium grid while WAITING', () => {
    const mgr = new RoomManager();
    const room = roomWith(mgr, 'WAITING', [{ playerId: 'p1', pos: { ...SPAWN_PX }, moveIntent: { dx: 1, dy: 0 } }]);
    const { fn: broadcast, calls } = makeBroadcast();
    startMovementTick(room, broadcast);

    vi.advanceTimersByTime(TICK_MS);
    const expectedStep = SEEKER_SPEED * (TICK_MS / 1000);
    expect(room.players[0]!.pos!.x).toBeCloseTo(SPAWN_PX.x + expectedStep, 6);
    expect(positionsOnly(calls)).toHaveLength(1);

    stopMovementTick(room);
  });

  it('P49: the grid swaps under a running tick at the WAITING→FIELD boundary (no restart)', () => {
    const mgr = new RoomManager();
    const room = roomWith(mgr, 'WAITING', [{ playerId: 'p1', pos: { ...SPAWN_PX }, moveIntent: { dx: 1, dy: 0 } }]);
    const { fn: broadcast, calls } = makeBroadcast();
    startMovementTick(room, broadcast);
    const timer = room.moveTick;

    vi.advanceTimersByTime(TICK_MS);              // moved in the Collegium
    expect(positionsOnly(calls)).toHaveLength(1);

    // Deploy: same tick keeps running, grid becomes the site.
    room.phase = 'FIELD';
    room.site = openSite();
    room.players[0]!.pos = { x: 100, y: 100 };
    vi.advanceTimersByTime(TICK_MS);              // moved in the site
    expect(room.moveTick).toBe(timer);            // never restarted
    expect(room.players[0]!.pos!.x).toBeGreaterThan(100);
    expect(positionsOnly(calls)).toHaveLength(2);

    stopMovementTick(room);
  });

  it('POSITIONS carries only the players who moved (P45)', () => {
    const mgr = new RoomManager();
    const room = roomWith(mgr, 'FIELD', [
      { playerId: 'mover', pos: { x: 100, y: 100 }, moveIntent: { dx: 1, dy: 0 } },
      { playerId: 'idler', pos: { x: 200, y: 100 }, moveIntent: { dx: 0, dy: 0 } },
    ], openSite());
    const { fn: broadcast, calls } = makeBroadcast();
    startMovementTick(room, broadcast);

    vi.advanceTimersByTime(TICK_MS);
    const payloads = positionsOnly(calls);
    expect(payloads).toHaveLength(1);
    expect(Object.keys(payloads[0]!.positions)).toEqual(['mover']);

    stopMovementTick(room);
  });

  it('an all-idle tick broadcasts nothing (P45)', () => {
    const mgr = new RoomManager();
    const room = roomWith(mgr, 'FIELD', [{ playerId: 'p1', pos: { x: 100, y: 100 }, moveIntent: { dx: 0, dy: 0 } }], openSite());
    const { fn: broadcast, calls } = makeBroadcast();
    startMovementTick(room, broadcast);

    vi.advanceTimersByTime(TICK_MS * 5);
    expect(positionsOnly(calls)).toHaveLength(0);

    stopMovementTick(room);
  });

  it('a COMPLETE room moves nothing even with stored intent', () => {
    const mgr = new RoomManager();
    const room = roomWith(mgr, 'COMPLETE', [{ playerId: 'p1', pos: { x: 100, y: 100 }, moveIntent: { dx: 1, dy: 0 } }], openSite());
    const { fn: broadcast, calls } = makeBroadcast();
    startMovementTick(room, broadcast);

    vi.advanceTimersByTime(TICK_MS * 3);
    expect(room.players[0]!.pos).toEqual({ x: 100, y: 100 });
    expect(positionsOnly(calls)).toHaveLength(0);

    stopMovementTick(room);
  });

  it('a disconnected player does not move even with stored intent (R96)', () => {
    const mgr = new RoomManager();
    const room = roomWith(mgr, 'FIELD', [
      { playerId: 'ghost', pos: { x: 100, y: 100 }, moveIntent: { dx: 1, dy: 0 }, disconnectedAt: Date.now() },
    ], openSite());
    const { fn: broadcast, calls } = makeBroadcast();
    startMovementTick(room, broadcast);

    vi.advanceTimersByTime(TICK_MS * 3);
    expect(room.players[0]!.pos).toEqual({ x: 100, y: 100 });
    expect(positionsOnly(calls)).toHaveLength(0);

    stopMovementTick(room);
  });
});

describe('movement tick — no leaks (R96 / P52)', () => {
  it('after stopMovementTick, no further broadcasts', () => {
    const mgr = new RoomManager();
    const room = roomWith(mgr, 'FIELD', [{ playerId: 'p1', pos: { x: 100, y: 100 }, moveIntent: { dx: 1, dy: 0 } }], openSite());
    const { fn: broadcast, calls } = makeBroadcast();
    startMovementTick(room, broadcast);
    vi.advanceTimersByTime(TICK_MS);
    stopMovementTick(room);
    const countAfterStop = positionsOnly(calls).length;

    vi.advanceTimersByTime(TICK_MS * 10);
    expect(positionsOnly(calls).length).toBe(countAfterStop);
  });

  it('destroyRoom stops the tick — no broadcasts survive room destruction', () => {
    const mgr = new RoomManager();
    const room = roomWith(mgr, 'FIELD', [{ playerId: 'p1', pos: { x: 100, y: 100 }, moveIntent: { dx: 1, dy: 0 } }], openSite());
    const { fn: broadcast, calls } = makeBroadcast();
    startMovementTick(room, broadcast);
    vi.advanceTimersByTime(TICK_MS);

    mgr.destroyRoom(room.code);
    const countAfterDestroy = positionsOnly(calls).length;
    vi.advanceTimersByTime(TICK_MS * 10);
    expect(positionsOnly(calls).length).toBe(countAfterDestroy);
    expect(room.moveTick).toBeNull();
  });

  it('startMovementTick is idempotent (no double timer)', () => {
    const mgr = new RoomManager();
    const room = roomWith(mgr, 'FIELD', [{ playerId: 'p1', pos: { x: 100, y: 100 }, moveIntent: { dx: 1, dy: 0 } }], openSite());
    const { fn: broadcast, calls } = makeBroadcast();
    startMovementTick(room, broadcast);
    startMovementTick(room, broadcast);

    vi.advanceTimersByTime(TICK_MS);
    expect(positionsOnly(calls)).toHaveLength(1);

    stopMovementTick(room);
  });
});
