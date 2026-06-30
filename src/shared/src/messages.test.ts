import { describe, it, expect } from 'vitest';
import {
  CLIENT_MESSAGES,
  SERVER_MESSAGES,
  LOBBY_ERROR_CODES,
  ROOM_STATUSES,
  PROTOCOL_SCALARS,
} from './messages.js';
import type {
  ClientMessageType,
  ServerMessageType,
  ClientMessagePayloads,
  ServerMessagePayloads,
  LobbyErrorCode,
  RoomStatus,
} from './messages.js';
import { CORRIDOR_HALF_WIDTH, DESIGN_VIEW_HEIGHT } from './dungeon.js';
import { MAX_PLAYERS, MIN_PLAYERS_TO_START } from './lobby.js';
import type { JoinRoomRequest, LobbyErrorEvent } from './lobby.js';
import { PLAYER_RADIUS } from './player.js';
import type { MovePlayerRequest } from './events.js';

// Compile-time assertion helpers. These are checked by `tsc` (the build), not by
// vitest (which transpiles with esbuild and strips types). They are inert at run
// time and exist so the derived-type properties (P2) fail the build if they drift.
type Equal<A, B> =
  (<T>() => T extends A ? 1 : 2) extends (<T>() => T extends B ? 1 : 2) ? true : false;
type Expect<T extends true> = T;

describe('wire registry (T1, R1)', () => {
  it('CLIENT_MESSAGES holds exactly the client-to-server catalog', () => {
    expect(Object.values(CLIENT_MESSAGES)).toEqual([
      'create-room',
      'join-room',
      'rejoin',
      'leave-room',
      'start-run',
      'move-player',
    ]);
  });

  it('SERVER_MESSAGES holds exactly the server-to-client catalog', () => {
    expect(Object.values(SERVER_MESSAGES)).toEqual([
      'ROOM_UPDATE',
      'RUN_STARTED',
      'PLAYER_MOVED',
      'STATE_RESYNC',
      'PLAYER_CONNECTION_CHANGED',
      'LOBBY_ERROR',
    ]);
  });

  it('every registry value is unique across both sets', () => {
    const all = [...Object.values(CLIENT_MESSAGES), ...Object.values(SERVER_MESSAGES)];
    expect(new Set(all).size).toBe(all.length);
    expect(all).toHaveLength(12);
  });

  it('excludes transport lifecycle events and test-only tokens', () => {
    const all = [...Object.values(CLIENT_MESSAGES), ...Object.values(SERVER_MESSAGES)];
    for (const excluded of ['connection', 'disconnect', 'PING']) {
      expect(all).not.toContain(excluded);
    }
  });

  it('derives the message-type unions from the registry values (P2)', () => {
    type _client = Expect<Equal<ClientMessageType, (typeof CLIENT_MESSAGES)[keyof typeof CLIENT_MESSAGES]>>;
    type _server = Expect<Equal<ServerMessageType, (typeof SERVER_MESSAGES)[keyof typeof SERVER_MESSAGES]>>;
    // A representative member is assignable; a foreign string is not.
    const client: ClientMessageType = 'move-player';
    const server: ServerMessageType = 'ROOM_UPDATE';
    expect([client, server]).toEqual(['move-player', 'ROOM_UPDATE']);
  });
});

describe('message-to-payload association (T1, R2)', () => {
  it('maps the payload-bearing names to their existing interfaces', () => {
    // Type-level: the maps reference the existing payload shapes (no duplicates).
    type _join = Expect<Equal<ClientMessagePayloads['join-room'], JoinRoomRequest>>;
    type _move = Expect<Equal<ClientMessagePayloads['move-player'], MovePlayerRequest>>;
    type _err = Expect<Equal<ServerMessagePayloads['LOBBY_ERROR'], LobbyErrorEvent>>;
    expect(true).toBe(true);
  });

  it('maps the four payload-free names to null', () => {
    type _create = Expect<Equal<ClientMessagePayloads['create-room'], null>>;
    type _rejoin = Expect<Equal<ClientMessagePayloads['rejoin'], null>>;
    type _leave = Expect<Equal<ClientMessagePayloads['leave-room'], null>>;
    type _start = Expect<Equal<ClientMessagePayloads['start-run'], null>>;
    expect(true).toBe(true);
  });
});

describe('shared enums as runtime values (T2, R3)', () => {
  it('LOBBY_ERROR_CODES holds exactly the eight codes in order', () => {
    expect(LOBBY_ERROR_CODES).toEqual([
      'ROOM_NOT_FOUND',
      'ROOM_FULL',
      'ALREADY_STARTED',
      'ALREADY_IN_ROOM',
      'NOT_ENOUGH_PLAYERS',
      'NOT_IN_ROOM',
      'INVALID_REQUEST',
      'CANNOT_REJOIN',
    ]);
  });

  it('ROOM_STATUSES holds exactly the three statuses in order', () => {
    expect(ROOM_STATUSES).toEqual(['lobby', 'in-progress', 'ended']);
  });

  it('derives LobbyErrorCode and RoomStatus from the arrays (P2, single source)', () => {
    type _codes = Expect<Equal<LobbyErrorCode, (typeof LOBBY_ERROR_CODES)[number]>>;
    type _status = Expect<Equal<RoomStatus, (typeof ROOM_STATUSES)[number]>>;
    // The refactored LobbyErrorEvent.code is the derived type, not a parallel union.
    type _eventCode = Expect<Equal<LobbyErrorEvent['code'], LobbyErrorCode>>;
    expect(true).toBe(true);
  });
});

describe('protocol scalar set (T2, R3)', () => {
  it('enumerates exactly the five shared scalars', () => {
    expect(Object.keys(PROTOCOL_SCALARS).sort()).toEqual(
      ['CORRIDOR_HALF_WIDTH', 'DESIGN_VIEW_HEIGHT', 'MAX_PLAYERS', 'MIN_PLAYERS_TO_START', 'PLAYER_RADIUS'].sort(),
    );
  });

  it('reads the values straight from their source modules (no redeclaration)', () => {
    expect(PROTOCOL_SCALARS.CORRIDOR_HALF_WIDTH).toBe(CORRIDOR_HALF_WIDTH);
    expect(PROTOCOL_SCALARS.DESIGN_VIEW_HEIGHT).toBe(DESIGN_VIEW_HEIGHT);
    expect(PROTOCOL_SCALARS.MAX_PLAYERS).toBe(MAX_PLAYERS);
    expect(PROTOCOL_SCALARS.MIN_PLAYERS_TO_START).toBe(MIN_PLAYERS_TO_START);
    expect(PROTOCOL_SCALARS.PLAYER_RADIUS).toBe(PLAYER_RADIUS);
  });

  it('every scalar value is a finite number (GDScript numeric const)', () => {
    for (const value of Object.values(PROTOCOL_SCALARS)) {
      expect(Number.isFinite(value)).toBe(true);
    }
  });
});

describe('messages.ts is data-only (T4, R7, P4)', () => {
  it('exports no functions and runs no logic at import time', async () => {
    const mod = await import('./messages.js');
    for (const [name, value] of Object.entries(mod)) {
      expect(typeof value, `export ${name} must be data, not a function`).not.toBe('function');
    }
  });
});
