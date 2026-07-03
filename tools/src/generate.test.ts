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
  ROOM_PHASES,
  CHANNELS,
  STIMULI,
  GEAR_CATALOG,
  PROTOCOL_SCALARS,
} from '@testament/shared';

describe('generateProtocolGd (T6, R4, P3; reconciled T85)', () => {
  it('is deterministic: two runs on the same input are byte-identical', () => {
    const input = protocolInputFromShared();
    expect(generateProtocolGd(input)).toBe(generateProtocolGd(input));
  });

  it('emits a well-formed GDScript shape', () => {
    const out = generateProtocolGd(protocolInputFromShared());
    expect(out.startsWith('# GENERATED FILE')).toBe(true);
    expect(out).toContain('# Regenerate: pnpm gen:protocol');
    expect(out.endsWith('\n')).toBe(true);
    expect(out).not.toContain('\r'); // LF newlines only
    // Every non-empty, non-comment line is a well-formed const declaration or a
    // line of the GEAR array literal.
    for (const line of out.split('\n')) {
      if (line === '' || line.startsWith('#')) continue;
      const isConst = /^const [A-Z][A-Z0-9_]* := (".*"|-?\d+|\[.*\])$/.test(line);
      const isGearOpen = line === 'const GEAR := [';
      const isGearEntry = /^\t\{.*\},$/.test(line);
      const isGearClose = line === ']';
      expect(isConst || isGearOpen || isGearEntry || isGearClose, `unexpected line: ${line}`).toBe(true);
    }
  });

  it('is preload-friendly: no global class_name, with a documented preload hint (TD-030)', () => {
    const out = generateProtocolGd(protocolInputFromShared());
    expect(out).not.toMatch(/^class_name /m);
    expect(out).toContain('preload("res://protocol/protocol.gd")');
  });

  it('contains every message name, enum value, gear item, and scalar', () => {
    const out = generateProtocolGd(protocolInputFromShared());
    for (const value of Object.values(CLIENT_MESSAGES)) expect(out).toContain(`const ${value} := "${value}"`);
    for (const value of Object.values(SERVER_MESSAGES)) expect(out).toContain(`const ${value} := "${value}"`);
    for (const value of LOBBY_ERROR_CODES) expect(out).toContain(`const ERR_${value} := "${value}"`);
    for (const value of ROOM_PHASES) expect(out).toContain(`const PHASE_${value} := "${value}"`);
    for (const value of CHANNELS) expect(out).toContain(`"${value}"`);
    for (const value of STIMULI) expect(out).toContain(`"${value}"`);
    for (const item of GEAR_CATALOG) {
      expect(out).toContain(`"id": "${item.id}"`);
      expect(out).toContain(`"name": "${item.name.replace(/"/g, '\\"')}"`);
    }
    for (const [key, value] of Object.entries(PROTOCOL_SCALARS)) {
      expect(out).toContain(`const ${key} := ${value}`);
    }
  });

  it('never leaks trait vocabulary: no axis values, only channels and stimuli', () => {
    const out = generateProtocolGd(protocolInputFromShared());
    // Server-only trait axis names must not appear in the client contract.
    for (const forbidden of ['traitRoll', 'aspect', 'frailty', 'ward', 'disposition', 'riteKey', 'tell']) {
      expect(out.toLowerCase()).not.toContain(forbidden.toLowerCase());
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
    expect(src).not.toMatch(/server[/\\](room|dungeon|combat|rooms|incarnate)/);
    expect(src).not.toMatch(/from ['"][^'"]*server/);
  });
});
