import type { Tier } from './signs.js';

export type PrimaryVerb = 'INVESTIGATE' | 'ELIMINATE' | 'CAPTURE' | 'BANISH';

// The genus the contract *asserts* for its target (GLOSSARY: Origin). This is a
// claim — falsifiable, possibly wrong, possibly hybrid — not the hidden trait
// roll. It is wire-safe intel: it colours the hunt (and the board's wax seal) but
// never reveals an axis value (I3/I5).
export type Origin = 'BELIEF' | 'SIN' | 'RELIC';

export type ContractIntel = {
  contractId:  string;
  tier:        Tier;
  origin:      Origin;
  targetName:  string;
  siteName:    string;
  primaryVerb: PrimaryVerb;
};
