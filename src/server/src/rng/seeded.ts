// Deterministic seeded RNG. Server-only (netcode invariant I3): all procedural
// randomness flows through here, never Math.random(). Same seed -> same sequence.

export interface Rng {
  // Float in [0, 1).
  float(): number;
  // Integer in [min, max] inclusive.
  int(min: number, max: number): number;
  // Deterministic element pick from a non-empty array.
  pick<T>(items: readonly T[]): T;
}

// xfnv1a-style string hash: maps a runId (UUID string) to a uint32 seed.
// Deterministic and well-distributed for typical short strings.
export function hashSeed(str: string): number {
  let h = 2166136261 >>> 0;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

// mulberry32: tiny, fast, dependency-free deterministic PRNG.
export function createRng(seed: number): Rng {
  let state = seed >>> 0;

  const float = (): number => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };

  const int = (min: number, max: number): number => {
    return min + Math.floor(float() * (max - min + 1));
  };

  const pick = <T>(items: readonly T[]): T => {
    if (items.length === 0) {
      throw new Error('Rng.pick called on an empty array');
    }
    return items[int(0, items.length - 1)] as T;
  };

  return { float, int, pick };
}
