// SELECT_CONTRACT (R110, revised TD-041): a reversible, non-committing selection.
// It validates every gate before any mutation (I2), promotes the *chosen* board
// entry (never a re-roll), and does NOT change phase or require the party to be
// ready — the commit to DEPLOYING happens later at the Deploy Gate (deploy.test.ts).
import { describe, it, expect } from 'vitest';
import { handleCreateRoom } from './createRoom.js';
import { handleSelectContract } from './selectContract.js';
import { RoomManager } from '../RoomManager.js';
import { ReconnectTokenStore } from '../ReconnectTokenStore.js';
import { stationCenterPx } from '../stations.js';
import type { EmitFn, BroadcastFn, ServerPlayerEntry } from '../types.js';

function standAt(mgr: RoomManager, socketId: string, kind: 'CONTRACT_BOARD' | 'QUARTERMASTER' | 'DEPLOY_GATE'): void {
  mgr.getRoomBySocketId(socketId)!.players.find(p => p.socketId === socketId)!.pos = stationCenterPx(kind);
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
  handleCreateRoom('host', { displayName: 'Host' }, mgr, new ReconnectTokenStore(), () => {}, () => {});
  return { mgr };
}

describe('handleSelectContract (R110 / P59, TD-041)', () => {
  it('a leader at the board selects a specific entry → room.contract is THAT entry, still WAITING', () => {
    const { mgr } = setup();
    standAt(mgr, 'host', 'CONTRACT_BOARD');   // note: NOT ready — selection needs no ready gate
    const room = mgr.getRoomBySocketId('host')!;
    const chosen = room.board[2]!;   // a non-first entry, to prove selection is by id
    const { fn: broadcast, calls } = makeBroadcast();
    handleSelectContract('host', { contractId: chosen.contractId }, mgr, () => {}, broadcast);

    expect(room.phase).toBe('WAITING');                       // no commit — reversible (TD-041)
    expect(room.contract?.contractId).toBe(chosen.contractId);
    // Broadcast 1: the authoritative snapshot carrying the selection as intel.
    expect(calls[0]?.[1]).toBe('LOBBY_UPDATED');
    const snap = (calls[0]?.[2] as { snapshot: { contract: Record<string, unknown> } }).snapshot;
    expect(snap.contract['contractId']).toBe(chosen.contractId);
    expect(Object.keys(snap.contract)).not.toContain('traitRoll');       // intel only (P58)
    expect(Object.keys(snap.contract)).not.toContain('expeditionSeed');
    // Broadcast 2: the transient accepted notice for the toast.
    expect(calls[1]?.[1]).toBe('CONTRACT_SELECTION');
    expect(calls[1]?.[2]).toEqual({ accepted: true, targetName: chosen.targetName, actorName: 'Host' });
  });

  it('selecting a second contract replaces the first (a fresh selection, still reversible)', () => {
    const { mgr } = setup();
    standAt(mgr, 'host', 'CONTRACT_BOARD');
    const room = mgr.getRoomBySocketId('host')!;
    handleSelectContract('host', { contractId: room.board[1]!.contractId }, mgr, () => {}, () => {});
    handleSelectContract('host', { contractId: room.board[3]!.contractId }, mgr, () => {}, () => {});
    expect(room.contract?.contractId).toBe(room.board[3]!.contractId);
    expect(room.phase).toBe('WAITING');
  });

  it('an unknown contractId → UNKNOWN_CONTRACT, nothing mutates', () => {
    const { mgr } = setup();
    standAt(mgr, 'host', 'CONTRACT_BOARD');
    const room = mgr.getRoomBySocketId('host')!;
    const { fn: emit, calls } = makeEmit();
    const { fn: broadcast, calls: bc } = makeBroadcast();
    handleSelectContract('host', { contractId: 'not-on-the-board' }, mgr, emit, broadcast);
    expect((calls[0]?.[1] as { code: string }).code).toBe('UNKNOWN_CONTRACT');
    expect(room.contract).toBeNull();
    expect(bc).toHaveLength(0);
  });

  it('a missing contractId → INVALID_PAYLOAD', () => {
    const { mgr } = setup();
    standAt(mgr, 'host', 'CONTRACT_BOARD');
    const { fn: emit, calls } = makeEmit();
    handleSelectContract('host', {}, mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('INVALID_PAYLOAD');
  });

  it('a non-leader → NOT_LEADER, no mutation', () => {
    const { mgr } = setup();
    const room = mgr.getRoomBySocketId('host')!;
    const p2: ServerPlayerEntry = {
      playerId: 'p2', displayName: 'P2', socketId: 'p2', isLeader: false, readyState: true,
      disconnectedAt: null, rank: 'HIEROPHANT', perceivedChannels: [], bag: [], pos: null, moveIntent: { dx: 0, dy: 0 },
    };
    room.players.push(p2);
    standAt(mgr, 'p2', 'CONTRACT_BOARD');
    const { fn: emit, calls } = makeEmit();
    handleSelectContract('p2', { contractId: room.board[0]!.contractId }, mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_LEADER');
    expect(room.contract).toBeNull();
  });

  it('a leader away from the board → NOT_AT_CONTRACT_BOARD', () => {
    const { mgr } = setup();
    const room = mgr.getRoomBySocketId('host')!;   // at spawn, not the board
    const { fn: emit, calls } = makeEmit();
    handleSelectContract('host', { contractId: room.board[0]!.contractId }, mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_AT_CONTRACT_BOARD');
    expect(room.contract).toBeNull();
  });

  // T365 (R356/R357, P160/P162, TD-095) — "the board is free, the rank is the gate".
  // Every case sets rank EXPLICITLY: relying on DEFAULT_RANK would only ever exercise
  // the gate in its permissive state, which is no test at all (P162).
  describe('rank gate', () => {
    it('refuses a contract above the actor rank, mutating nothing (I2)', () => {
      const { mgr } = setup();
      const room = mgr.getRoomBySocketId('host')!;
      standAt(mgr, 'host', 'CONTRACT_BOARD');
      room.players[0]!.rank = 'SEEKER';
      const anathema = room.board.find(c => c.tier === 'ANATHEMA')!;
      const errs: Array<[string, unknown]> = [];
      const bcast: Array<[string, string, unknown]> = [];

      handleSelectContract('host', { contractId: anathema.contractId }, mgr,
        (t, p) => errs.push([t, p]), (c, t, p) => bcast.push([c, t, p]));

      expect(room.contract).toBeNull();                 // unmutated
      expect(bcast).toHaveLength(0);                    // nothing broadcast
      expect(errs).toHaveLength(1);                     // sender only (I2)
      expect((errs[0]![1] as { code: string }).code).toBe('RANK_TOO_LOW');
    });

    it('allows a contract the actor rank answers for', () => {
      const { mgr } = setup();
      const room = mgr.getRoomBySocketId('host')!;
      standAt(mgr, 'host', 'CONTRACT_BOARD');
      room.players[0]!.rank = 'SEEKER';
      const vigil = room.board.find(c => c.tier === 'VIGIL')!;

      handleSelectContract('host', { contractId: vigil.contractId }, mgr, () => {}, () => {});

      expect(room.contract?.contractId).toBe(vigil.contractId);
    });

    it('an Aspirant answers for nothing at all', () => {
      const { mgr } = setup();
      const room = mgr.getRoomBySocketId('host')!;
      standAt(mgr, 'host', 'CONTRACT_BOARD');
      room.players[0]!.rank = 'ASPIRANT';
      const errs: Array<[string, unknown]> = [];

      handleSelectContract('host', { contractId: room.board[0]!.contractId }, mgr,
        (t, p) => errs.push([t, p]), () => {});

      expect(room.contract).toBeNull();
      expect((errs[0]![1] as { code: string }).code).toBe('RANK_TOO_LOW');
    });

    it('an inbound rank in the payload is ignored, never trusted (P160)', () => {
      const { mgr } = setup();
      const room = mgr.getRoomBySocketId('host')!;
      standAt(mgr, 'host', 'CONTRACT_BOARD');
      room.players[0]!.rank = 'SEEKER';
      const anathema = room.board.find(c => c.tier === 'ANATHEMA')!;
      const errs: Array<[string, unknown]> = [];

      // A client claiming a rank it does not hold changes nothing.
      handleSelectContract('host',
        { contractId: anathema.contractId, rank: 'HIEROPHANT' } as unknown as Record<string, unknown>,
        mgr, (t, p) => errs.push([t, p]), () => {});

      expect(room.contract).toBeNull();
      expect((errs[0]![1] as { code: string }).code).toBe('RANK_TOO_LOW');
      expect(room.players[0]!.rank).toBe('SEEKER');     // and does not stick
    });
  });
});
