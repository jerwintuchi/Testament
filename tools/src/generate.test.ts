import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import {
  generateProtocolGd,
  protocolInputFromShared,
  PROTOCOL_GD_PATH,
} from './generate.js';
import {
  CLIENT_MESSAGES,
  SERVER_MESSAGES,
  LOBBY_ERROR_CODES,
  ROOM_STATUSES,
  PROTOCOL_SCALARS,
} from '@testament/shared';

describe('generateProtocolGd (T6, R4, P3)', () => {
  it('is deterministic: two runs on the same input are byte-identical', () => {
    const input = protocolInputFromShared();
    expect(generateProtocolGd(input)).toBe(generateProtocolGd(input));
  });

  it('emits a well-formed GDScript shape', () => {
    const out = generateProtocolGd(protocolInputFromShared());
    expect(out.startsWith('# GENERATED FILE')).toBe(true);
    expect(out).toContain('# Source: src/shared/src/messages.ts');
    expect(out).toContain('# Regenerate: pnpm gen:protocol');
    expect(out.endsWith('\n')).toBe(true);
    expect(out).not.toContain('\r'); // LF newlines only
    // Every non-empty, non-comment line is a well-formed const declaration.
    for (const line of out.split('\n')) {
      if (line === '' || line.startsWith('#')) continue;
      expect(line, `unexpected line: ${line}`).toMatch(/^const [A-Z][A-Z0-9_]* := (".*"|-?\d+)$/);
    }
  });

  it('is preload-friendly: no global class_name, with a documented preload hint', () => {
    const out = generateProtocolGd(protocolInputFromShared());
    expect(out).not.toMatch(/^class_name /m);
    expect(out).toContain('preload("res://protocol/protocol.gd")');
  });

  it('contains every message name, enum value, and scalar', () => {
    const out = generateProtocolGd(protocolInputFromShared());
    for (const value of Object.values(CLIENT_MESSAGES)) expect(out).toContain(`:= "${value}"`);
    for (const value of Object.values(SERVER_MESSAGES)) expect(out).toContain(`:= "${value}"`);
    for (const value of LOBBY_ERROR_CODES) expect(out).toContain(`:= "${value}"`);
    for (const value of ROOM_STATUSES) expect(out).toContain(`:= "${value}"`);
    for (const [key, value] of Object.entries(PROTOCOL_SCALARS)) {
      expect(out).toContain(`const ${key} := ${value}`);
    }
  });

  it('names the message consts by their registry keys', () => {
    const out = generateProtocolGd(protocolInputFromShared());
    for (const [key, value] of Object.entries(CLIENT_MESSAGES)) {
      expect(out).toContain(`const ${key} := "${value}"`);
    }
    for (const [key, value] of Object.entries(SERVER_MESSAGES)) {
      expect(out).toContain(`const ${key} := "${value}"`);
    }
  });
});

describe('reproducibility gate (T7, R4, P3)', () => {
  it('the committed client/protocol/protocol.gd is byte-identical to a fresh generation', () => {
    const committed = readFileSync(PROTOCOL_GD_PATH, 'utf8');
    const fresh = generateProtocolGd(protocolInputFromShared());
    expect(committed).toBe(fresh);
  });
});

describe('trust boundary (R7, P4)', () => {
  it('the codegen imports nothing from server game modules', () => {
    const src = readFileSync(new URL('./generate.ts', import.meta.url), 'utf8');
    expect(src).not.toMatch(/server[/\\](room|dungeon|combat)/);
    expect(src).not.toMatch(/from ['"][^'"]*server/);
  });
});
