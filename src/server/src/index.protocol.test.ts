import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { CLIENT_MESSAGES, SERVER_MESSAGES } from '@testament/shared';

// Guard for R5: the server references the shared message-name registry, with no
// bare wire-message string literal left in index.ts. (Behavioural coverage that a
// create-room still yields a ROOM_UPDATE lives in transport/wsHub.test.ts.)
const SOURCE = readFileSync(new URL('./index.ts', import.meta.url), 'utf8');
const WIRE_MESSAGE_VALUES = [
  ...Object.values(CLIENT_MESSAGES),
  ...Object.values(SERVER_MESSAGES),
];

describe('server wire-message literals (T8, R5)', () => {
  it('index.ts contains no bare wire-message literal from the catalog', () => {
    for (const value of WIRE_MESSAGE_VALUES) {
      expect(SOURCE.includes(`'${value}'`), `bare literal '${value}' remains`).toBe(false);
      expect(SOURCE.includes(`"${value}"`), `bare literal "${value}" remains`).toBe(false);
    }
  });

  it('index.ts references the shared registry constants', () => {
    expect(SOURCE).toContain('CLIENT_MESSAGES.CREATE_ROOM');
    expect(SOURCE).toContain('SERVER_MESSAGES.ROOM_UPDATE');
  });

  it('disconnect is a transport lifecycle event, absent from the wire registry', () => {
    expect(WIRE_MESSAGE_VALUES).not.toContain('disconnect');
    // It is still wired as a raw-socket lifecycle handler, not via the registry.
    expect(SOURCE).toContain("socket.on('disconnect'");
  });
});
