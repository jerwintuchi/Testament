import type { Tier } from '@testament/shared';
import type { ContractRecord } from './contractRecord.js';
import { createRng, hashSeed } from '../rng/seeded.js';
import { generateContract } from './generateContract.js';

// How many contracts the Collegium posts on the board at once.
export const BOARD_SIZE = 4;

// v1 board tier. Collegium Rank gates tier (docs/systems/contracts.md, TD-012);
// until Rank exists the whole board is APPRENTICE. The tier is per-entry data, so
// raising or mixing it later is a data change, not a shape change.
const BOARD_TIER: Tier = 'APPRENTICE';

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
  const board: ContractRecord[] = [];
  for (let i = 0; i < size; i++) {
    const entrySeed = `${expeditionSeed}:contract:${i}`;
    const rng = createRng(hashSeed(entrySeed));
    const contractId = `ctr-${(hashSeed(`${entrySeed}:id`) >>> 0).toString(36)}`;
    board.push(generateContract(rng, BOARD_TIER, contractId, entrySeed));
  }
  return board;
}
