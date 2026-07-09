// Protocol-contract registry tests (reconciled to the Testament protocol, T84).
import { describe, it, expect } from 'vitest';
import * as messages from './messages.js';
import {
  CLIENT_MESSAGES,
  SERVER_MESSAGES,
  PROTOCOL_SCALARS,
} from './messages.js';
import { LOBBY_ERROR_CODES } from './lobbyMessages.js';
import { ROOM_PHASES, MAX_ROOM_PLAYERS, ROOM_CODE_LENGTH } from './lobby.js';
import { BAG_SLOTS } from './gear.js';
import type { ClientMessagePayloads, ServerMessagePayloads } from './messages.js';

describe('CLIENT_MESSAGES / SERVER_MESSAGES registry', () => {
  it('contains exactly the Testament protocol names, nothing else', () => {
    expect(Object.values(CLIENT_MESSAGES).sort()).toEqual([
      'ACCEPT_CONTRACT', 'CREATE_ROOM', 'DEPLOY', 'DESELECT_CONTRACT', 'EXTRACT',
      'JOIN_ROOM', 'KICK_PLAYER', 'LEAVE_ROOM', 'MOVE', 'PROBE', 'RECONNECT',
      'REQUISITION', 'SELECT_CONTRACT', 'TOGGLE_READY',
    ]);
    expect(Object.values(SERVER_MESSAGES).sort()).toEqual([
      'ARCHIVE_UPDATED', 'CONTRACT_SELECTION', 'FIELD_STARTED', 'FIELD_TESTAMENT',
      'LOBBY_ERROR', 'LOBBY_UPDATED', 'POSITIONS', 'PROBE_RESULT', 'RECONNECT_TOKEN',
      'ROOM_CREATED', 'ROOM_DEPLOYING', 'STATE_RESYNC',
    ]);
  });

  it('keys equal values (the codegen identifier IS the wire name)', () => {
    for (const [key, value] of Object.entries({ ...CLIENT_MESSAGES, ...SERVER_MESSAGES })) {
      expect(key).toBe(value);
    }
  });

  it('all wire names are unique across both directions', () => {
    const all = [...Object.values(CLIENT_MESSAGES), ...Object.values(SERVER_MESSAGES)];
    expect(new Set(all).size).toBe(all.length);
  });

  it('transport lifecycle events are not wire messages', () => {
    const all = [...Object.values(CLIENT_MESSAGES), ...Object.values(SERVER_MESSAGES)] as string[];
    expect(all).not.toContain('connection');
    expect(all).not.toContain('disconnect');
  });

  it('the payload maps cover every registry name (type-level, checked at compile time)', () => {
    // Exhaustiveness: a registry name missing from its payload map fails to compile.
    type ClientCovered = keyof ClientMessagePayloads extends keyof typeof CLIENT_MESSAGES
      ? keyof typeof CLIENT_MESSAGES extends keyof ClientMessagePayloads ? true : never
      : never;
    type ServerCovered = keyof ServerMessagePayloads extends keyof typeof SERVER_MESSAGES
      ? keyof typeof SERVER_MESSAGES extends keyof ServerMessagePayloads ? true : never
      : never;
    const clientCovered: ClientCovered = true;
    const serverCovered: ServerCovered = true;
    expect(clientCovered).toBe(true);
    expect(serverCovered).toBe(true);
  });
});

describe('codegen-able enums and scalars', () => {
  it('LOBBY_ERROR_CODES holds exactly the twenty codes with no duplicates', () => {
    expect(LOBBY_ERROR_CODES).toHaveLength(20);
    expect(new Set(LOBBY_ERROR_CODES).size).toBe(20);
  });

  it('ROOM_PHASES holds exactly the four phases in lifecycle order', () => {
    expect(ROOM_PHASES).toEqual(['WAITING', 'DEPLOYING', 'FIELD', 'COMPLETE']);
  });

  it('PROTOCOL_SCALARS enumerates exactly the scalars that cross to GDScript', () => {
    expect(PROTOCOL_SCALARS).toEqual({
      MAX_ROOM_PLAYERS,
      ROOM_CODE_LENGTH,
      BAG_SLOTS,
    });
  });
});

describe('registry purity (R7): data and types only', () => {
  it('every runtime export is a plain object, array, or primitive — no functions', () => {
    for (const [name, value] of Object.entries(messages)) {
      expect(typeof value, `${name} must not be a function`).not.toBe('function');
    }
  });
});
