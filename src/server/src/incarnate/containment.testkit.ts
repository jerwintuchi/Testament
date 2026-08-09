// Test support for I5/P156 — NOT a suite (the filename is outside vitest's
// `*.test.ts` glob on purpose, so it ships assertions rather than running any).
//
// T352 (TD-093). The containment tests used to read:
//
//     expect(json).not.toContain('"FLAME"');
//
// which passed while the lexicon shipped `flinch-from-flame` — the token carried the
// answer in lowercase, unquoted, so the assertion sailed past it. The LETTER of I5
// held while the spirit did not, and that is precisely why nobody noticed the table
// was self-translating for eleven of its twenty-four entries.
//
// So: every trait-value literal, case-insensitively, unquoted.
import { expect } from 'vitest';
import { AXIS_VALUES } from './types.js';

const TRAIT_VALUE_LITERALS: ReadonlyArray<string> =
  [...new Set(Object.values(AXIS_VALUES).flat())];

/**
 * Assert a payload names no hidden trait value anywhere, in any casing.
 *
 * `allow` exists for values the party itself supplied and the server merely echoes —
 * `PROBE_RESULT.stimulus` is the party's own choice, so it is not a leak. Nothing
 * else belongs in it: an allow entry is a claim that the client already knew.
 */
export function expectNoTraitValues(payload: unknown, allow: readonly string[] = []): void {
  const json = (typeof payload === 'string' ? payload : JSON.stringify(payload)) ?? '';
  const haystack = json.toLowerCase();
  const permitted = new Set(allow.map(a => a.toLowerCase()));

  const leaked = TRAIT_VALUE_LITERALS
    .filter(v => !permitted.has(v.toLowerCase()))
    .filter(v => haystack.includes(v.toLowerCase()));

  expect(leaked, `payload names hidden trait value(s) in ${json}`).toEqual([]);
}

/** The server-only shape keys that must never ride the wire either. */
export function expectNoServerOnlyKeys(payload: unknown): void {
  const json = (typeof payload === 'string' ? payload : JSON.stringify(payload)) ?? '';
  for (const key of ['traitRoll', 'expeditionSeed', '"ward"']) {
    expect(json).not.toContain(key);
  }
}
