import { describe, it, expect } from 'vitest';
import { hashSeed, createRng } from './seeded.js';

describe('hashSeed', () => {
  it('is deterministic for the same input', () => {
    expect(hashSeed('run-abc')).toBe(hashSeed('run-abc'));
  });

  it('maps distinct typical strings to distinct seeds', () => {
    const seeds = new Set([
      hashSeed('run-1'),
      hashSeed('run-2'),
      hashSeed('00000000-0000-0000-0000-000000000000'),
      hashSeed('ffffffff-ffff-ffff-ffff-ffffffffffff'),
      hashSeed('daily-2026-06-14'),
    ]);
    expect(seeds.size).toBe(5);
  });

  it('returns an unsigned 32-bit integer', () => {
    const h = hashSeed('anything');
    expect(Number.isInteger(h)).toBe(true);
    expect(h).toBeGreaterThanOrEqual(0);
    expect(h).toBeLessThanOrEqual(0xffffffff);
  });
});

describe('createRng', () => {
  it('produces an identical sequence for the same seed (determinism)', () => {
    const a = createRng(12345);
    const b = createRng(12345);
    const seqA = Array.from({ length: 20 }, () => a.float());
    const seqB = Array.from({ length: 20 }, () => b.float());
    expect(seqA).toEqual(seqB);
  });

  it('produces different sequences for different seeds', () => {
    const a = createRng(1);
    const b = createRng(2);
    const seqA = Array.from({ length: 20 }, () => a.float());
    const seqB = Array.from({ length: 20 }, () => b.float());
    expect(seqA).not.toEqual(seqB);
  });

  it('float() always returns a value in [0, 1)', () => {
    const rng = createRng(99);
    for (let i = 0; i < 10000; i++) {
      const v = rng.float();
      expect(v).toBeGreaterThanOrEqual(0);
      expect(v).toBeLessThan(1);
    }
  });

  it('int(min,max) stays within [min,max] inclusive', () => {
    const rng = createRng(7);
    for (let i = 0; i < 10000; i++) {
      const v = rng.int(3, 9);
      expect(v).toBeGreaterThanOrEqual(3);
      expect(v).toBeLessThanOrEqual(9);
      expect(Number.isInteger(v)).toBe(true);
    }
  });

  it('int(min,max) reaches both endpoints over many draws', () => {
    const rng = createRng(42);
    let sawMin = false;
    let sawMax = false;
    for (let i = 0; i < 10000; i++) {
      const v = rng.int(0, 3);
      if (v === 0) sawMin = true;
      if (v === 3) sawMax = true;
    }
    expect(sawMin).toBe(true);
    expect(sawMax).toBe(true);
  });

  it('pick() returns an element of the array deterministically', () => {
    const items = ['a', 'b', 'c', 'd'] as const;
    const a = createRng(555);
    const b = createRng(555);
    const picksA = Array.from({ length: 10 }, () => a.pick(items));
    const picksB = Array.from({ length: 10 }, () => b.pick(items));
    expect(picksA).toEqual(picksB);
    for (const p of picksA) expect(items).toContain(p);
  });

  it('pick() throws on an empty array', () => {
    const rng = createRng(1);
    expect(() => rng.pick([])).toThrow();
  });
});
