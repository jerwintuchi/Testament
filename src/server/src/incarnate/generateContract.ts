import type { ContractIntel, Origin, PrimaryVerb, Requester, Tier } from '@testament/shared';
import type { Rng } from '../rng/seeded.js';
import type { ContractRecord } from './contractRecord.js';
import { generateTraitRoll } from './generateTraitRoll.js';

const TARGET_NAMES: readonly string[] = [
  'The Ashen Warden',
  'The Weeping Mire',
  'The Frost Penitent',
  'The Rot-Bloom',
];

const SITE_NAMES: readonly string[] = [
  'The Collapsed Chancel',
  'The Salt Marsh',
  'The Ember Reach',
  'The Sunken Nave',
];

const PRIMARY_VERBS: readonly PrimaryVerb[] = ['INVESTIGATE', 'ELIMINATE', 'CAPTURE', 'BANISH'];

// The genus the contract asserts. A seeded pick, independent of the trait roll —
// the assertion may be wrong (falsifiable), which is the point (GLOSSARY: Origin).
const ORIGINS: readonly Origin[] = ['BELIEF', 'SIN', 'RELIC'];

// The petitioner whose report prompted the charge — flavour intel, never trait
// data. Authored tables; a seeded ~1-in-5 chance the petition is anonymous.
const REQUESTER_NAMES:  readonly string[] = [
  'Aldis Vane', 'Sister Wren', 'Proctor Hald', 'Bede Ashmore', 'Mother Sael',
  'Osric Kell', 'Dame Ivo', 'Brother Cael', 'Widow Harrow', 'Magister Fenn',
];
const REQUESTER_ROLES:  readonly string[] = [
  'Reliquary-Steward', 'Parish-Priest', 'Proctor', 'Warden', 'Archivist', 'Almoner', 'Sexton',
];
const REQUESTER_PLACES: readonly string[] = [
  'Ashfen', 'Gall', 'Low Fen', 'the Sunken Nave', 'Hollowmere', 'Saint Duir', 'the Ember Reach',
];
const ANON_ROLES:       readonly string[] = ['penitent', 'pilgrim', 'lay witness'];

// pickRequester — pure over the seeded rng (P67). Same seed → same requester (I3).
export function pickRequester(rng: Rng): Requester {
  if (rng.float() < 0.2) {
    return { name: '', role: rng.pick(ANON_ROLES), place: rng.pick(REQUESTER_PLACES) };
  }
  return { name: rng.pick(REQUESTER_NAMES), role: rng.pick(REQUESTER_ROLES), place: rng.pick(REQUESTER_PLACES) };
}

export function generateContract(
  rng: Rng,
  tier: Tier,
  contractId: string,
  expeditionSeed: string,
): ContractRecord {
  return {
    contractId,
    tier,
    expeditionSeed,
    origin:      rng.pick(ORIGINS),
    requester:   pickRequester(rng),
    targetName:  rng.pick(TARGET_NAMES),
    siteName:    rng.pick(SITE_NAMES),
    primaryVerb: rng.pick(PRIMARY_VERBS),
    traitRoll:   generateTraitRoll(rng, tier),
  };
}

export function toContractIntel({ expeditionSeed: _, traitRoll: __, ...intel }: ContractRecord): ContractIntel {
  return intel;
}
