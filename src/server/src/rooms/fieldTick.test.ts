// T100 [R87, R91 / P44, P45, P46]: the 20Hz field tick integrates stored intent
// authoritatively, broadcasts only moved players as a delta, and never outlives
// its room.
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { startFieldTick, stopFieldTick } from './fieldTick.js';
import { RoomManager } from './RoomManager.js';
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
    if (y === 0 || y === h - 1) rows.push('#'.repeat(w));
    else rows.push('#' + '.'.repeat(w - 2) + '#');
  }
  return { grid: { width: w, height: h, rows }, nodes: [] };
}

function makeBroadcast(): { fn: BroadcastFn; calls: Array<[string, string, unknown]> } {
  const calls: Array<[string, string, unknown]> = [];
  return { fn: (code, type, payload) => calls.push([code, type, payload]), calls };
}

function positionsOnly(calls: Array<[string, string, unknown]>): PositionsPayload[] {
  return calls.filter(c => c[1] === SERVER_MESSAGES.POSITIONS).map(c => c[2] as PositionsPayload);
}

// Builds a FIELD-phase room with the given players placed on the open site.
function fieldRoom(mgr: RoomManager, players: Array<Partial<ServerPlayerEntry> & { playerId: string; pos: { x: number; y: number } }>): RoomRecord {
  const room = mgr.createRoom('host', 'Host');
  room.phase = 'FIELD';
  room.site = openSite();
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

describe('field tick — integration (R87)', () => {
  it('applies stored intent at SEEKER_SPEED', () => {
    const mgr = new RoomManager();
    const room = fieldRoom(mgr, [{ playerId: 'p1', pos: { x: 100, y: 100 }, moveIntent: { dx: 1, dy: 0 } }]);
    const { fn: broadcast, calls } = makeBroadcast();
    startFieldTick(room, broadcast);

    vi.advanceTimersByTime(TICK_MS);
    const expectedStep = SEEKER_SPEED * (TICK_MS / 1000);
    expect(room.players[0]!.pos!.x).toBeCloseTo(100 + expectedStep, 6);
    const payloads = positionsOnly(calls);
    expect(payloads).toHaveLength(1);
    expect(payloads[0]!.positions['p1']!.x).toBeCloseTo(100 + expectedStep, 6);

    stopFieldTick(room);
  });

  it('POSITIONS carries only the players who moved (P45)', () => {
    const mgr = new RoomManager();
    const room = fieldRoom(mgr, [
      { playerId: 'mover', pos: { x: 100, y: 100 }, moveIntent: { dx: 1, dy: 0 } },
      { playerId: 'idler', pos: { x: 200, y: 100 }, moveIntent: { dx: 0, dy: 0 } },
    ]);
    const { fn: broadcast, calls } = makeBroadcast();
    startFieldTick(room, broadcast);

    vi.advanceTimersByTime(TICK_MS);
    const payloads = positionsOnly(calls);
    expect(payloads).toHaveLength(1);
    expect(Object.keys(payloads[0]!.positions)).toEqual(['mover']);

    stopFieldTick(room);
  });

  it('an all-idle tick broadcasts nothing (P45)', () => {
    const mgr = new RoomManager();
    const room = fieldRoom(mgr, [{ playerId: 'p1', pos: { x: 100, y: 100 }, moveIntent: { dx: 0, dy: 0 } }]);
    const { fn: broadcast, calls } = makeBroadcast();
    startFieldTick(room, broadcast);

    vi.advanceTimersByTime(TICK_MS * 5);
    expect(positionsOnly(calls)).toHaveLength(0);

    stopFieldTick(room);
  });

  it('a disconnected player does not move even with stored intent (R87)', () => {
    const mgr = new RoomManager();
    const room = fieldRoom(mgr, [
      { playerId: 'ghost', pos: { x: 100, y: 100 }, moveIntent: { dx: 1, dy: 0 }, disconnectedAt: Date.now() },
    ]);
    const { fn: broadcast, calls } = makeBroadcast();
    startFieldTick(room, broadcast);

    vi.advanceTimersByTime(TICK_MS * 3);
    expect(room.players[0]!.pos).toEqual({ x: 100, y: 100 });
    expect(positionsOnly(calls)).toHaveLength(0);

    stopFieldTick(room);
  });
});

describe('field tick — no leaks (R91 / P46)', () => {
  it('after stopFieldTick, no further broadcasts', () => {
    const mgr = new RoomManager();
    const room = fieldRoom(mgr, [{ playerId: 'p1', pos: { x: 100, y: 100 }, moveIntent: { dx: 1, dy: 0 } }]);
    const { fn: broadcast, calls } = makeBroadcast();
    startFieldTick(room, broadcast);
    vi.advanceTimersByTime(TICK_MS);
    stopFieldTick(room);
    const countAfterStop = positionsOnly(calls).length;

    vi.advanceTimersByTime(TICK_MS * 10);
    expect(positionsOnly(calls).length).toBe(countAfterStop);
  });

  it('destroyRoom stops the tick — no broadcasts survive room destruction', () => {
    const mgr = new RoomManager();
    const room = fieldRoom(mgr, [{ playerId: 'p1', pos: { x: 100, y: 100 }, moveIntent: { dx: 1, dy: 0 } }]);
    const { fn: broadcast, calls } = makeBroadcast();
    startFieldTick(room, broadcast);
    vi.advanceTimersByTime(TICK_MS);

    mgr.destroyRoom(room.code);
    const countAfterDestroy = positionsOnly(calls).length;
    vi.advanceTimersByTime(TICK_MS * 10);
    expect(positionsOnly(calls).length).toBe(countAfterDestroy);
    expect(room.fieldTick).toBeNull();
  });

  it('startFieldTick is idempotent (no double timer)', () => {
    const mgr = new RoomManager();
    const room = fieldRoom(mgr, [{ playerId: 'p1', pos: { x: 100, y: 100 }, moveIntent: { dx: 1, dy: 0 } }]);
    const { fn: broadcast, calls } = makeBroadcast();
    startFieldTick(room, broadcast);
    startFieldTick(room, broadcast);

    vi.advanceTimersByTime(TICK_MS);
    // One tick → exactly one POSITIONS broadcast, not two.
    expect(positionsOnly(calls)).toHaveLength(1);

    stopFieldTick(room);
  });
});
