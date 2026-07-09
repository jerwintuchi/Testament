import type { Tier } from './signs.js';

export type PrimaryVerb = 'INVESTIGATE' | 'ELIMINATE' | 'CAPTURE' | 'BANISH';

// The genus the contract *asserts* for its target (GLOSSARY: Origin). This is a
// claim — falsifiable, possibly wrong, possibly hybrid — not the hidden trait
// roll. It is wire-safe intel: it colours the hunt (and the board's wax seal) but
// never reveals an axis value (I3/I5).
export type Origin = 'BELIEF' | 'SIN' | 'RELIC';

// Who petitioned the charge — the party whose report of a Manifestation prompted
// the Collegium to dispatch it (docs/lore/collegium.md). Wire-safe intel: it is
// the notice's signature, never trait data. `name` is "" for an anonymous
// petitioner ("an unnamed <role> of <place>").
export type Requester = {
  name:  string;
  role:  string;
  place: string;
};

export type ContractIntel = {
  contractId:  string;
  tier:        Tier;
  origin:      Origin;
  requester:   Requester;
  targetName:  string;
  siteName:    string;
  primaryVerb: PrimaryVerb;
};
