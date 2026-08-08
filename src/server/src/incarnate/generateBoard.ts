import type { Tier } from '@testament/shared';
import type { ContractRecord } from './contractRecord.js';
import { createRng, hashSeed } from '../rng/seeded.js';
import { generateContract } from './generateContract.js';

// How many contracts the Collegium posts on the board at once. Canonically 8
// (TD-045) — a full commission wall (the 4×2 grid of the Notice Board, Prototype v1),
// so the board reads as a busy Collegium, not a short list.
export const BOARD_SIZE = 8;

// The wall's spread of danger (R353, TD-095). A commission wall reads as mostly
// ordinary work with a few things nobody wants to touch, so a board is composed
// rather than rolled: 5 Vigils, 2 Interdicts, 1 Anathema at the canonical size.
//
// A GUARANTEED COMPOSITION, deliberately, not an independent weighted draw per
// entry. Once Rank gates acceptance (TD-095 Phase B), independent draws could
// produce a board with nothing a low-rank Seeker may accept — a dead wall, by
// luck. Composing then shuffling makes that unreachable: a Seeker always has
// work, and always sees what they cannot yet take.
//
// APOCRYPHA is excluded: adding a tier to the union does not put it on the wall.
// It arrives with the Mutation system (specs/tiers/ Phase B).
const TIER_SHARE: ReadonlyArray<readonly [Tier, number]> = [
  ['INTERDICT', 2],
  ['ANATHEMA',  1],
];
const TIER_SHARE_OF = 8;

// The pool of tiers for a board of `size`, before shuffling. Higher tiers take
// their proportional share; VIGIL is the remainder, so rounding can only ever
// make the wall safer, never leave it with fewer accepted contracts than planned.
export function tierPool(size: number): Tier[] {
  const pool: Tier[] = [];
  for (const [tier, share] of TIER_SHARE) {
    for (let i = 0; i < Math.floor((size * share) / TIER_SHARE_OF); i++) pool.push(tier);
  }
  while (pool.length < size) pool.push('VIGIL');
  return pool;
}

// The Contract Board: a seeded pool of contracts the party browses and picks from
// ("the board is free, the rank is the gate", contracts.md). Pure and
// deterministic (I3) — the same expedition seed yields the same board.
//
// Each entry is its OWN self-contained seeded expedition (its own seed + rng +
// contractId), so the one the leader selects carries a valid, unique trait roll
// straight into DEPLOY with no re-roll. The contractId is derived through the
// one-way hashSeed, never from the raw seed string, so it is a safe wire handle:
// the expedition seed itself never leaves the server (I3), and toContractIntel
// additionally strips expeditionSeed + traitRoll before anything is broadcast.
export function generateBoard(expeditionSeed: string, size = BOARD_SIZE): ContractRecord[] {
  // The tier shuffle rides its OWN board-level stream, so no entry's rng is
  // touched: adding this draw cannot shift any value inside a contract (P151 —
  // the stream-shape lesson from `ward !== frailty`).
  const tiers = tierPool(size);
  const shuffle = createRng(hashSeed(`${expeditionSeed}:tiers`));
  for (let i = tiers.length - 1; i > 0; i--) {           // Fisher-Yates, seeded (I3)
    const j = shuffle.int(0, i);
    [tiers[i], tiers[j]] = [tiers[j]!, tiers[i]!];
  }

  const board: ContractRecord[] = [];
  for (let i = 0; i < size; i++) {
    const entrySeed = `${expeditionSeed}:contract:${i}`;
    const rng = createRng(hashSeed(entrySeed));
    const contractId = `ctr-${(hashSeed(`${entrySeed}:id`) >>> 0).toString(36)}`;
    board.push(generateContract(rng, tiers[i]!, contractId, entrySeed));
  }
  return board;
}
