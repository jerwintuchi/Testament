import type { Tier } from '@testament/shared';
import type { Rng } from '../rng/seeded.js';
import type { TraitRoll } from './types.js';
import { AXIS_VALUES } from './types.js';

// One runtime list of each axis's values (types.ts), shared with the lexicon's
// completeness and no-self-naming checks — so a new value cannot be drawable
// without also being demanded of the lexicon. Order is load-bearing: `rng.pick`
// indexes into these, so reordering re-rolls every seeded expedition (I3).
const {
  ASPECT:      ASPECT_VALUES,
  FRAILTY:     FRAILTY_VALUES,
  TELL:        TELL_VALUES,
  WARD:        WARD_VALUES,
  DISPOSITION: DISPOSITION_VALUES,
  RITE_KEY:    RITE_KEY_VALUES,
} = AXIS_VALUES;

export function generateTraitRoll(rng: Rng, tier: Tier): TraitRoll {
  const roll: TraitRoll = {
    aspect:  rng.pick(ASPECT_VALUES),
    frailty: rng.pick(FRAILTY_VALUES),
    tell:    rng.pick(TELL_VALUES),
  };
  if (tier === 'INTERDICT' || tier === 'ANATHEMA') {
    // R326/P150 — a thing is never warded against what it is frail to. This makes an
    // AMBIENT channel (Stress-mark, read by a lens) a falsifiable prediction about a
    // PROBE-GATED one (Reaction): "Stress-mark says salt, so don't waste the salt probe."
    // It is a law of the world, learned once (Pillar 2); it shrinks the search and never
    // reveals the Ward (Pillar 3).
    //
    // A FILTERED pick, deliberately, not a rejection loop: this consumes exactly one draw,
    // so the seeded stream keeps its shape (I3/P151). A `do…while` would consume a variable
    // number and shift every downstream value depending on what was rejected.
    roll.ward        = rng.pick(WARD_VALUES.filter(w => w !== roll.frailty));
    roll.disposition = rng.pick(DISPOSITION_VALUES);
  }
  if (tier === 'ANATHEMA') {
    roll.riteKey = rng.pick(RITE_KEY_VALUES);
  }
  return roll;
}
