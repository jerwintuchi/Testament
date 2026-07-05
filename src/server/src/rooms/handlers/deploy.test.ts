import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { handleDeploy } from './deploy.js';
import { handleCreateRoom } from './createRoom.js';
import { handleAcceptContract } from './acceptContract.js';
import { handleToggleReady } from './toggleReady.js';
import { RoomManager } from '../RoomManager.js';
import { ReconnectTokenStore } from '../ReconnectTokenStore.js';
import { stationCenterPx } from '../stations.js';
import type { EmitFn, EmitToFn, BroadcastFn } from '../types.js';

function standAt(mgr: RoomManager, socketId: string, kind: 'CONTRACT_BOARD' | 'QUARTERMASTER' | 'DEPLOY_GATE'): void {
  const room = mgr.getRoomBySocketId(socketId)!;
  room.players.find(p => p.socketId === socketId)!.pos = stationCenterPx(kind);
}

function makeEmit(): { fn: EmitFn; calls: Array<[string, unknown]> } {
  const calls: Array<[string, unknown]> = [];
  return { fn: (t, p) => calls.push([t, p]), calls };
}
function makeEmitTo(): { fn: EmitToFn; calls: Array<[string, string, unknown]> } {
  const calls: Array<[string, string, unknown]> = [];
  return { fn: (sid, t, p) => calls.push([sid, t, p]), calls };
}
const noBroadcast: BroadcastFn = () => {};

// handleDeploy starts the 20Hz field tick (a setInterval); fake timers keep it
// from actually firing or leaking a handle across tests.
beforeEach(() => vi.useFakeTimers());
afterEach(() => vi.useRealTimers());

function setupDeployingRoom() {
  const mgr = new RoomManager();
  const store = new ReconnectTokenStore();

  handleCreateRoom('host', { displayName: 'Host' }, mgr, store, () => {}, () => {});
  const room = mgr.getRoomBySocketId('host')!;
  room.players[0]!.readyState = true;

  // acceptContract is gated to the Contract Board (R99); deploy to the Deploy
  // Gate (R101). Walk the leader through both, ending on the gate so the deploy
  // under test is allowed.
  standAt(mgr, 'host', 'CONTRACT_BOARD');
  const { fn: emit } = makeEmit();
  handleAcceptContract('host', mgr, emit, noBroadcast);
  standAt(mgr, 'host', 'DEPLOY_GATE');
  return { mgr, store, room };
}

// T33: DEPLOY handler

describe('handleDeploy', () => {
  it('valid DEPLOY from leader sets phase to FIELD and emits FIELD_STARTED per player', () => {
    const { mgr, store } = setupDeployingRoom();
    const { fn: emitTo, calls: emitToCalls } = makeEmitTo();

    handleDeploy('host', mgr, store, () => {}, emitTo, noBroadcast);

    // Room is now in FIELD phase.
    const room = mgr.getRoomBySocketId('host')!;
    expect(room.phase).toBe('FIELD');
    expect(room.fieldData).not.toBeNull();

    // FIELD_STARTED emitted once per player (solo room: 1 player).
    const fieldStarted = emitToCalls.filter(([, t]) => t === 'FIELD_STARTED');
    expect(fieldStarted).toHaveLength(1);
    const payload = fieldStarted[0]?.[2] as { fieldData: { siteName: string }; reconnectToken: string };
    expect(typeof payload.fieldData.siteName).toBe('string');
    expect(payload.fieldData.siteName.length).toBeGreaterThan(0);
    expect(typeof payload.reconnectToken).toBe('string');
  });

  it('FIELD_STARTED payload includes signs array with no traitRoll (R49/R50)', () => {
    const { mgr, store } = setupDeployingRoom();
    const { fn: emitTo, calls: emitToCalls } = makeEmitTo();
    handleDeploy('host', mgr, store, () => {}, emitTo, noBroadcast);
    const payload = emitToCalls[0]?.[2] as Record<string, unknown>;
    // No server-only fields at top level.
    expect(Object.keys(payload)).not.toContain('traitRoll');
    expect(Object.keys(payload)).not.toContain('expeditionSeed');
    expect(Object.keys(payload.fieldData as object)).not.toContain('traitRoll');
    // signs is present and is an array.
    const signs = payload['signs'] as Array<Record<string, unknown>>;
    expect(Array.isArray(signs)).toBe(true);
    expect(signs.length).toBe(3);  // Apprentice tier: RESIDUE, STRESS_MARK, OMEN
    // Each sign has exactly channel and token.
    for (const sign of signs) {
      expect(Object.keys(sign).sort()).toEqual(['channel', 'token']);
    }
    // Signs channels are correct for Apprentice tier.
    expect(signs.map(s => s['channel'])).toEqual(['RESIDUE', 'STRESS_MARK', 'OMEN']);
    // No axis value literal in JSON output.
    const json = JSON.stringify(signs);
    for (const lit of ['EMBER', 'FROST', 'ROT', 'MIRE', 'FLAME', 'COLD', 'SALT', 'LIGHT', 'LUNGE', 'SWEEP', 'RECOIL', 'SHUDDER']) {
      expect(json).not.toContain(`"${lit}"`);
    }
  });

  it('resets exposure and revealedSigns when the field phase begins (T57, R57/R58)', () => {
    const { mgr, store } = setupDeployingRoom();
    const room = mgr.getRoomBySocketId('host')!;
    room.exposure = 7;
    room.revealedSigns = [{ channel: 'REACTION', token: 'no-reaction' }];

    handleDeploy('host', mgr, store, () => {}, () => {}, noBroadcast);

    expect(room.exposure).toBe(0);
    expect(room.revealedSigns).toEqual([]);
  });

  it('FIELD_STARTED signs contain no REACTION channel even when the tier has a ward (T60, P22)', () => {
    const { mgr, store } = setupDeployingRoom();
    const room = mgr.getRoomBySocketId('host')!;
    room.contract = {
      ...room.contract!,
      tier: 'JOURNEYMAN',
      traitRoll: { aspect: 'EMBER', frailty: 'FLAME', tell: 'LUNGE', ward: 'COLD', disposition: 'STALKER' },
    };
    const { fn: emitTo, calls: emitToCalls } = makeEmitTo();

    handleDeploy('host', mgr, store, () => {}, emitTo, noBroadcast);

    const payload = emitToCalls[0]?.[2] as { signs: Array<{ channel: string }> };
    expect(payload.signs.map(s => s.channel)).toEqual(['RESIDUE', 'STRESS_MARK', 'OMEN', 'SPOOR']);
  });

  // T64/T72: perception at deploy — solo rule, then gear-derived (R61, R66, P28, P32)

  it('solo with an empty bag still perceives the full tier channel set and all ambient signs (P32)', () => {
    const { mgr, store } = setupDeployingRoom();
    const { fn: emitTo, calls: emitToCalls } = makeEmitTo();

    handleDeploy('host', mgr, store, () => {}, emitTo, noBroadcast);

    const payload = emitToCalls[0]?.[2] as { signs: Array<{ channel: string }>; perceivedChannels: string[] };
    // Apprentice tier: ambient RESIDUE, STRESS_MARK, OMEN + probe-gated REACTION.
    expect(payload.perceivedChannels).toEqual(['RESIDUE', 'STRESS_MARK', 'REACTION', 'OMEN']);
    expect(payload.signs.map(s => s.channel)).toEqual(['RESIDUE', 'STRESS_MARK', 'OMEN']);
  });

  it('2-player room: each player\'s signs match their gear channels exactly (P32, P28)', () => {
    const { mgr, store } = setupDeployingRoom();
    const room = mgr.getRoomBySocketId('host')!;
    room.players[0]!.bag = ['ashen-lens', 'censer-of-embers'];  // RESIDUE + a probe kit
    room.players.push({
      playerId: 'p2', displayName: 'P2', socketId: 'p2-sock',
      isLeader: false, readyState: true, disconnectedAt: null, perceivedChannels: [],
      bag: ['augurs-bead', 'chirurgeons-glass'],                // OMEN + STRESS_MARK
      pos: null, moveIntent: { dx: 0, dy: 0 },
    });
    const { fn: emitTo, calls: emitToCalls } = makeEmitTo();

    handleDeploy('host', mgr, store, () => {}, emitTo, noBroadcast);

    const byId = new Map(emitToCalls
      .filter(([, t]) => t === 'FIELD_STARTED')
      .map(([sid, , p]) => [sid, p as { signs: Array<{ channel: string }>; perceivedChannels: string[] }]));
    expect(byId.get('host')?.perceivedChannels).toEqual(['RESIDUE']);
    expect(byId.get('host')?.signs.map(s => s.channel)).toEqual(['RESIDUE']);
    expect(byId.get('p2-sock')?.perceivedChannels).toEqual(['STRESS_MARK', 'OMEN']);
    expect(byId.get('p2-sock')?.signs.map(s => s.channel)).toEqual(['STRESS_MARK', 'OMEN']);
    // Stored server-side, keyed to the player entry (R63).
    expect(room.players[0]!.perceivedChannels).toEqual(['RESIDUE']);
  });

  it('a party member with no perception gear receives no signs (blindness is a legal bad bet)', () => {
    const { mgr, store } = setupDeployingRoom();
    const room = mgr.getRoomBySocketId('host')!;
    room.players.push({
      playerId: 'p2', displayName: 'P2', socketId: 'p2-sock',
      isLeader: false, readyState: true, disconnectedAt: null, perceivedChannels: [], bag: [], pos: null, moveIntent: { dx: 0, dy: 0 },
    });
    const { fn: emitTo, calls: emitToCalls } = makeEmitTo();

    handleDeploy('host', mgr, store, () => {}, emitTo, noBroadcast);

    const p2Payload = emitToCalls.find(([sid, t]) => sid === 'p2-sock' && t === 'FIELD_STARTED')?.[2] as
      { signs: unknown[]; perceivedChannels: string[] };
    expect(p2Payload.perceivedChannels).toEqual([]);
    expect(p2Payload.signs).toEqual([]);
  });

  it('non-leader sender emits LOBBY_ERROR NOT_LEADER with zero state mutations', () => {
    const { mgr, store } = setupDeployingRoom();
    // Add a second player.
    const room = mgr.getRoomBySocketId('host')!;
    room.players.push({
      playerId: 'p2', displayName: 'P2', socketId: 'p2-sock',
      isLeader: false, readyState: true, disconnectedAt: null, perceivedChannels: [], bag: [], pos: null, moveIntent: { dx: 0, dy: 0 },
    });

    const { fn: emit, calls } = makeEmit();
    const { fn: emitTo, calls: emitToCalls } = makeEmitTo();
    handleDeploy('p2-sock', mgr, store, emit, emitTo, noBroadcast);

    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_LEADER');
    expect(emitToCalls).toHaveLength(0);
    expect(room.phase).toBe('DEPLOYING');
  });

  it('DEPLOY in a WAITING room emits LOBBY_ERROR WRONG_PHASE', () => {
    const mgr = new RoomManager();
    const store = new ReconnectTokenStore();
    handleCreateRoom('host', { displayName: 'Host' }, mgr, store, () => {}, () => {});
    const { fn: emit, calls } = makeEmit();
    handleDeploy('host', mgr, store, emit, () => {}, noBroadcast);
    expect((calls[0]?.[1] as { code: string }).code).toBe('WRONG_PHASE');
  });

  it('sender not in any room emits LOBBY_ERROR NOT_IN_ROOM', () => {
    const { fn: emit, calls } = makeEmit();
    handleDeploy('unknown-sock', new RoomManager(), new ReconnectTokenStore(), emit, () => {}, noBroadcast);
    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_IN_ROOM');
  });

  // T114 (R101): deploy is gated to the Deploy Gate.
  it('leader away from the Deploy Gate emits NOT_AT_DEPLOY_GATE, stays DEPLOYING, no FIELD_STARTED', () => {
    const { mgr, store } = setupDeployingRoom();
    // Walk the leader off the gate (to the far Contract Board).
    standAt(mgr, 'host', 'CONTRACT_BOARD');
    const { fn: emit, calls } = makeEmit();
    const { fn: emitTo, calls: emitToCalls } = makeEmitTo();
    handleDeploy('host', mgr, store, emit, emitTo, noBroadcast);

    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_AT_DEPLOY_GATE');
    expect(emitToCalls).toHaveLength(0);
    expect(mgr.getRoomBySocketId('host')!.phase).toBe('DEPLOYING');
  });
});

// T101 [R85 / P41, P47]: DEPLOY places the party in a generated site.

type StartedPayload = {
  site: { grid: { width: number; height: number; rows: string[] }; nodes: Array<{ kind: string; x: number; y: number }> };
  positions: Record<string, { x: number; y: number }>;
};

// Adds a second player and pins the expedition seed so spawns are reproducible.
function twoPlayerDeploying(seed: string) {
  const { mgr, store } = setupDeployingRoom();
  const room = mgr.getRoomBySocketId('host')!;
  room.players.push({
    playerId: 'p2', displayName: 'P2', socketId: 'p2-sock',
    isLeader: false, readyState: true, disconnectedAt: null, perceivedChannels: [], bag: [],
    pos: null, moveIntent: { dx: 0, dy: 0 },
  });
  room.contract = { ...room.contract!, expeditionSeed: seed };
  return { mgr, store, room };
}

describe('handleDeploy — field space (R85)', () => {
  it('FIELD_STARTED carries a site and a spawn position per player', () => {
    const { mgr, store, room } = twoPlayerDeploying('seed-alpha');
    const { fn: emitTo, calls } = makeEmitTo();
    handleDeploy('host', mgr, store, () => {}, emitTo, noBroadcast);

    const started = calls.filter(([, t]) => t === 'FIELD_STARTED').map(([sid, , p]) => [sid, p as StartedPayload] as const);
    expect(started).toHaveLength(2);
    for (const [, payload] of started) {
      expect(payload.site.grid.rows).toHaveLength(payload.site.grid.height);
      // Every player's spawn appears in the shared positions map.
      expect(Object.keys(payload.positions).sort()).toEqual([...room.players.map(p => p.playerId)].sort());
    }
    // Server stored a position per player.
    expect(room.players.every(p => p.pos !== null)).toBe(true);
  });

  it('spawns are distinct, on floor tiles', () => {
    const { mgr, store, room } = twoPlayerDeploying('seed-beta');
    const { fn: emitTo, calls } = makeEmitTo();
    handleDeploy('host', mgr, store, () => {}, emitTo, noBroadcast);

    const payload = calls.find(([, t]) => t === 'FIELD_STARTED')![2] as StartedPayload;
    const pts = Object.values(payload.positions);
    const keys = new Set(pts.map(p => `${p.x},${p.y}`));
    expect(keys.size).toBe(pts.length);  // distinct
    for (const p of pts) {
      const tx = Math.floor(p.x / 16);
      const ty = Math.floor(p.y / 16);
      expect(payload.site.grid.rows[ty]![tx]).toBe('.');
    }
    // room.site is set and matches the delivered site.
    expect(room.site).not.toBeNull();
  });

  it('same expedition seed → identical site and spawns (P41)', () => {
    const a = twoPlayerDeploying('same-seed');
    const b = twoPlayerDeploying('same-seed');
    const ea = makeEmitTo();
    const eb = makeEmitTo();
    handleDeploy('host', a.mgr, a.store, () => {}, ea.fn, noBroadcast);
    handleDeploy('host', b.mgr, b.store, () => {}, eb.fn, noBroadcast);

    const pa = ea.calls.find(([, t]) => t === 'FIELD_STARTED')![2] as StartedPayload;
    const pb = eb.calls.find(([, t]) => t === 'FIELD_STARTED')![2] as StartedPayload;
    expect(pa.site).toEqual(pb.site);
    // playerIds are random per room, so compare the spawn *values* (assigned in
    // player order, which is deterministic) rather than the keyed maps.
    const sortPts = (m: Record<string, { x: number; y: number }>) =>
      Object.values(m).sort((u, v) => u.x - v.x || u.y - v.y);
    expect(sortPts(pa.positions)).toEqual(sortPts(pb.positions));
  });

  it('stringified FIELD_STARTED carries no trait-axis literal (P47)', () => {
    const { mgr, store } = twoPlayerDeploying('seed-contain');
    const { fn: emitTo, calls } = makeEmitTo();
    handleDeploy('host', mgr, store, () => {}, emitTo, noBroadcast);
    const json = JSON.stringify(calls.find(([, t]) => t === 'FIELD_STARTED')![2]);
    for (const lit of ['EMBER', 'FROST', 'ROT', 'MIRE', 'FLAME', 'COLD', 'SALT', 'LIGHT', 'LUNGE', 'SWEEP', 'RECOIL', 'SHUDDER', 'STALKER']) {
      expect(json).not.toContain(`"${lit}"`);
    }
  });
});
