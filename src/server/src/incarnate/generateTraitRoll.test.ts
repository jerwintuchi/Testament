// T43: generateTraitRoll — tier-gating, determinism, value set membership, no Math.random
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { generateTraitRoll } from './generateTraitRoll.js';
import { createRng, hashSeed } from '../rng/seeded.js';

const ASPECT_VALUES      = ['EMBER', 'FROST', 'ROT', 'MIRE'] as const;
const FRAILTY_VALUES     = ['FLAME', 'COLD', 'SALT', 'LIGHT'] as const;
const TELL_VALUES        = ['LUNGE', 'SWEEP', 'RECOIL', 'SHUDDER'] as const;
const WARD_VALUES        = ['FLAME', 'COLD', 'SALT', 'LIGHT'] as const;
const DISPOSITION_VALUES = ['STALKER', 'AMBUSHER', 'TERRITORIAL', 'FRENZIED'] as const;
const RITE_KEY_VALUES    = ['PENANCE', 'IMMOLATION', 'INTERMENT', 'SILENCE'] as const;

describe('generateTraitRoll', () => {
  it('Vigil roll has aspect, frailty, tell and no optional axes', () => {
    const rng = createRng(hashSeed('vigil-test'));
    const roll = generateTraitRoll(rng, 'VIGIL');
    const keys = Object.keys(roll);
    expect(keys).toContain('aspect');
    expect(keys).toContain('frailty');
    expect(keys).toContain('tell');
    expect(keys).not.toContain('ward');
    expect(keys).not.toContain('disposition');
    expect(keys).not.toContain('riteKey');
  });

  it('Interdict roll adds ward and disposition, still no riteKey', () => {
    const rng = createRng(hashSeed('interdict-test'));
    const roll = generateTraitRoll(rng, 'INTERDICT');
    const keys = Object.keys(roll);
    expect(keys).toContain('ward');
    expect(keys).toContain('disposition');
    expect(keys).not.toContain('riteKey');
  });

  it('Anathema roll has all six fields', () => {
    const rng = createRng(hashSeed('anathema-test'));
    const roll = generateTraitRoll(rng, 'ANATHEMA');
    const keys = Object.keys(roll);
    expect(keys).toContain('aspect');
    expect(keys).toContain('frailty');
    expect(keys).toContain('tell');
    expect(keys).toContain('ward');
    expect(keys).toContain('disposition');
    expect(keys).toContain('riteKey');
  });

  it('determinism: same seed + tier → same roll (P15/R36)', () => {
    const seed = hashSeed('determinism-seed');
    const rollA = generateTraitRoll(createRng(seed), 'ANATHEMA');
    const rollB = generateTraitRoll(createRng(seed), 'ANATHEMA');
    expect(rollA).toEqual(rollB);
  });

  it('different seeds produce different rolls (probabilistic)', () => {
    const rollA = generateTraitRoll(createRng(hashSeed('seed-alpha')), 'ANATHEMA');
    const rollB = generateTraitRoll(createRng(hashSeed('seed-beta')), 'ANATHEMA');
    // With 4^6 = 4096 possibilities, collision probability is ~0.024%; accept the test.
    expect(rollA).not.toEqual(rollB);
  });

  it('all generated values fall within v1 enum sets — checked across 20 seeds', () => {
    for (let i = 0; i < 20; i++) {
      const rng = createRng(hashSeed(`value-check-${i}`));
      const roll = generateTraitRoll(rng, 'ANATHEMA');
      expect(ASPECT_VALUES).toContain(roll.aspect);
      expect(FRAILTY_VALUES).toContain(roll.frailty);
      expect(TELL_VALUES).toContain(roll.tell);
      expect(WARD_VALUES).toContain(roll.ward);
      expect(DISPOSITION_VALUES).toContain(roll.disposition);
      expect(RITE_KEY_VALUES).toContain(roll.riteKey);
    }
  });

  // T337 (R326, P150/P151) — a thing is never warded against what it is frail to.
  describe('ward !== frailty (R326)', () => {
    it('never rolls a ward equal to the frailty — across 300 seeds, both rolling tiers', () => {
      for (let i = 0; i < 300; i++) {
        for (const tier of ['INTERDICT', 'ANATHEMA'] as const) {
          const roll = generateTraitRoll(createRng(hashSeed(`ward-frailty-${tier}-${i}`)), tier);
          expect(roll.ward).not.toBe(roll.frailty);
        }
      }
    });

    it('still reaches every ward value — the rule must not bias toward one (P150)', () => {
      const seen = new Set<string>();
      for (let i = 0; i < 300; i++) {
        seen.add(generateTraitRoll(createRng(hashSeed(`ward-spread-${i}`)), 'ANATHEMA').ward!);
      }
      expect([...seen].sort()).toEqual([...WARD_VALUES].sort());
    });

    it('pairs every frailty with all three of its permitted wards (no dead combination)', () => {
      const pairs = new Set<string>();
      for (let i = 0; i < 2000; i++) {
        const roll = generateTraitRoll(createRng(hashSeed(`ward-pairs-${i}`)), 'ANATHEMA');
        pairs.add(`${roll.frailty}->${roll.ward}`);
      }
      // 4 frailties x 3 permitted wards each = 12 reachable combinations.
      expect(pairs.size).toBe(12);
    });

    it('determinism survives the filtered pick — same seed, same roll (I3, P151)', () => {
      for (const tier of ['VIGIL', 'INTERDICT', 'ANATHEMA'] as const) {
        const a = generateTraitRoll(createRng(hashSeed('determinism-probe')), tier);
        const b = generateTraitRoll(createRng(hashSeed('determinism-probe')), tier);
        expect(a).toEqual(b);
      }
    });

    it('consumes exactly one draw for the ward, so the stream keeps its shape (P151)', () => {
      // A rejection loop would consume a variable number of draws and shift riteKey,
      // which is drawn after the ward. Same seed at ANATHEMA must reproduce riteKey too.
      const rng = createRng(hashSeed('stream-shape'));
      const roll = generateTraitRoll(rng, 'ANATHEMA');
      // Draw order is aspect, frailty, tell, ward, disposition, riteKey — six picks.
      const control = createRng(hashSeed('stream-shape'));
      for (let i = 0; i < 6; i++) control.float();
      // The generator and a six-draw control leave the stream at the same place.
      expect(control.float()).toBe(rng.float());
      expect(roll.riteKey).toBeDefined();
    });
  });

  it('source file does not import crypto or call Math.random (R41)', () => {
    const src = fileURLToPath(new URL('./generateTraitRoll.ts', import.meta.url));
    const content = readFileSync(src, 'utf-8');
    expect(content).not.toMatch(/Math\.random/);
    expect(content).not.toMatch(/['"]node:crypto['"]/);
    expect(content).not.toMatch(/require\(['"]crypto['"]\)/);
  });
});
