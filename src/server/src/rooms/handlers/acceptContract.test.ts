import { describe, it, expect } from 'vitest';
import { handleCreateRoom } from './createRoom.js';
import { handleToggleReady } from './toggleReady.js';
import { handleAcceptContract } from './acceptContract.js';
import { RoomManager } from '../RoomManager.js';
import { ReconnectTokenStore } from '../ReconnectTokenStore.js';
import { stationCenterPx } from '../stations.js';
import type { EmitFn, BroadcastFn } from '../types.js';

// Stand the socket's player on a station so a gated prep action is allowed (R99).
function standAt(mgr: RoomManager, socketId: string, kind: 'CONTRACT_BOARD' | 'QUARTERMASTER' | 'DEPLOY_GATE'): void {
  const room = mgr.getRoomBySocketId(socketId)!;
  room.players.find(p => p.socketId === socketId)!.pos = stationCenterPx(kind);
}

function makeEmit(): { fn: EmitFn; calls: Array<[string, unknown]> } {
  const calls: Array<[string, unknown]> = [];
  return { fn: (t, p) => calls.push([t, p]), calls };
}
function makeBroadcast(): { fn: BroadcastFn; calls: Array<[string, string, unknown]> } {
  const calls: Array<[string, string, unknown]> = [];
  return { fn: (c, t, p) => calls.push([c, t, p]), calls };
}

function setup() {
  const mgr = new RoomManager();
  const store = new ReconnectTokenStore();
  handleCreateRoom('host', { displayName: 'Host' }, mgr, store, () => {}, () => {});
  return { mgr, store };
}

// T15: ACCEPT_CONTRACT handler

describe('handleAcceptContract', () => {
  it('solo leader who is ready transitions room to DEPLOYING and broadcasts ROOM_DEPLOYING', () => {
    const { mgr } = setup();
    handleToggleReady('host', mgr, () => {}, () => {});
    standAt(mgr, 'host', 'CONTRACT_BOARD');
    const { fn: broadcast, calls } = makeBroadcast();
    handleAcceptContract('host', mgr, () => {}, broadcast);
    expect(calls[0]?.[1]).toBe('ROOM_DEPLOYING');
    expect(mgr.getRoomBySocketId('host')!.phase).toBe('DEPLOYING');
  });

  it('ROOM_DEPLOYING payload includes ContractIntel with no traitRoll or expeditionSeed (R48)', () => {
    const { mgr } = setup();
    handleToggleReady('host', mgr, () => {}, () => {});
    standAt(mgr, 'host', 'CONTRACT_BOARD');
    const { fn: broadcast, calls } = makeBroadcast();
    handleAcceptContract('host', mgr, () => {}, broadcast);
    const payload = calls[0]?.[2] as { contract: Record<string, unknown> };
    expect(payload.contract).toBeDefined();
    expect(Object.keys(payload.contract)).not.toContain('traitRoll');
    expect(Object.keys(payload.contract)).not.toContain('expeditionSeed');
    expect(payload.contract['tier']).toBe('VIGIL');
    // server-side room.contract has the traitRoll
    const room = mgr.getRoomBySocketId('host')!;
    expect(room.contract?.traitRoll).toBeDefined();
  });

  it('emits LOBBY_ERROR NOT_LEADER for a non-leader socket', () => {
    const { mgr, store } = setup();
    // Manually add a second player
    const room = mgr.getRoomBySocketId('host')!;
    room.players.push({ playerId: 'p2', displayName: 'P2', socketId: 'p2-sock', isLeader: false, readyState: true, disconnectedAt: null, perceivedChannels: [], bag: [], pos: null, moveIntent: { dx: 0, dy: 0 } });
    const { fn: emit, calls } = makeEmit();
    handleAcceptContract('p2-sock', mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_LEADER');
    expect(room.phase).toBe('WAITING');
  });

  it('emits LOBBY_ERROR PARTY_NOT_READY when a player is not ready', () => {
    const { mgr } = setup();
    // host is not ready (readyState defaults to false); stand at the board so the
    // gate under test is the readiness one, not the position one.
    standAt(mgr, 'host', 'CONTRACT_BOARD');
    const { fn: emit, calls } = makeEmit();
    handleAcceptContract('host', mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('PARTY_NOT_READY');
    expect(mgr.getRoomBySocketId('host')!.phase).toBe('WAITING');
  });

  // T112 (R99): accepting is gated to the Contract Board.
  it('emits NOT_AT_CONTRACT_BOARD when a ready leader is away from the board', () => {
    const { mgr } = setup();
    handleToggleReady('host', mgr, () => {}, () => {});
    // host is at the Collegium spawn (default), not the board.
    const { fn: emit, calls } = makeEmit();
    const { fn: broadcast, calls: bcalls } = makeBroadcast();
    handleAcceptContract('host', mgr, emit, broadcast);
    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_AT_CONTRACT_BOARD');
    expect(mgr.getRoomBySocketId('host')!.phase).toBe('WAITING');
    expect(bcalls).toHaveLength(0);
  });

  // T89 (R78): a not-ready GHOST does not block acceptance.
  it('succeeds with a not-ready disconnected player in the room', () => {
    const { mgr } = setup();
    handleToggleReady('host', mgr, () => {}, () => {});
    standAt(mgr, 'host', 'CONTRACT_BOARD');
    const room = mgr.getRoomBySocketId('host')!;
    room.players.push({
      playerId: 'ghost', displayName: 'Ghost', socketId: '', isLeader: false,
      readyState: false, disconnectedAt: Date.now(), perceivedChannels: [], bag: [], pos: null, moveIntent: { dx: 0, dy: 0 },
    });
    const { fn: broadcast, calls } = makeBroadcast();
    handleAcceptContract('host', mgr, () => {}, broadcast);
    expect(room.phase).toBe('DEPLOYING');
    expect(calls.some(([, t]) => t === 'ROOM_DEPLOYING')).toBe(true);
  });
});
