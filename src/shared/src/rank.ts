// Collegium Rank — the ladder of standing (TD-094/TD-095). Types and constants
// only (I4); the authorization DECISION lives server-side in rooms/rank.ts.
//
// Two ladders, and they are never crossed: a RANK names a person, a TIER names a
// place. Rank escalates in authority over what is KNOWN, never in combat power
// (TD-012) — the apex of the order is the Seeker whose account the Collegium
// records as true, not its best fighter.
import type { Tier } from './signs.js';

export type Rank = 'ASPIRANT' | 'SEEKER' | 'WITNESS' | 'CONFESSOR' | 'HIEROPHANT';

// Canonical order, lowest first. Exported so a UI can render the ladder without
// hard-coding it; it is NOT the authorization check (see RANK_ACCEPTS).
export const RANKS: ReadonlyArray<Rank> = [
  'ASPIRANT', 'SEEKER', 'WITNESS', 'CONFESSOR', 'HIEROPHANT',
];

// Which Tiers a Rank may ACCEPT. "The board is free, the rank is the gate"
// (contracts.md, TD-012): every Seeker SEES every contract; this decides only
// what they may take responsibility for.
//
// Written as an explicit map rather than an ordinal comparison on purpose — a
// future Tier or Rank must be placed deliberately, not inherit an implied
// ordering. An Aspirant accepts nothing: they are not yet a Seeker.
export const RANK_ACCEPTS: Readonly<Record<Rank, ReadonlyArray<Tier>>> = {
  ASPIRANT:   [],
  SEEKER:     ['VIGIL'],
  WITNESS:    ['VIGIL', 'INTERDICT'],
  CONFESSOR:  ['VIGIL', 'INTERDICT', 'ANATHEMA'],
  HIEROPHANT: ['VIGIL', 'INTERDICT', 'ANATHEMA'],
  // APOCRYPHA joins HIEROPHANT when specs/tiers/ Phase B ships the Mutation system.
};
