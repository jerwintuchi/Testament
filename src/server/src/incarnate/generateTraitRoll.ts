import type { Tier } from '@testament/shared';
import type { Rng } from '../rng/seeded.js';
import type {
  TraitRoll,
  AspectValue,
  FrailtyValue,
  WardValue,
  DispositionValue,
  RiteKeyValue,
  TellValue,
} from './types.js';

const ASPECT_VALUES:      readonly AspectValue[]      = ['EMBER', 'FROST', 'ROT', 'MIRE'];
const FRAILTY_VALUES:     readonly FrailtyValue[]     = ['FLAME', 'COLD', 'SALT', 'LIGHT'];
const TELL_VALUES:        readonly TellValue[]        = ['LUNGE', 'SWEEP', 'RECOIL', 'SHUDDER'];
const WARD_VALUES:        readonly WardValue[]        = ['FLAME', 'COLD', 'SALT', 'LIGHT'];
const DISPOSITION_VALUES: readonly DispositionValue[] = ['STALKER', 'AMBUSHER', 'TERRITORIAL', 'FRENZIED'];
const RITE_KEY_VALUES:    readonly RiteKeyValue[]     = ['PENANCE', 'IMMOLATION', 'INTERMENT', 'SILENCE'];

export function generateTraitRoll(rng: Rng, tier: Tier): TraitRoll {
  const roll: TraitRoll = {
    aspect:  rng.pick(ASPECT_VALUES),
    frailty: rng.pick(FRAILTY_VALUES),
    tell:    rng.pick(TELL_VALUES),
  };
  if (tier === 'JOURNEYMAN' || tier === 'MASTER') {
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
  if (tier === 'MASTER') {
    roll.riteKey = rng.pick(RITE_KEY_VALUES);
  }
  return roll;
}
