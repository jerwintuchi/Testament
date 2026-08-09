import type { Tier } from '@testament/shared';

export type TraitAxis =
  | 'ASPECT' | 'FRAILTY' | 'WARD'
  | 'DISPOSITION' | 'RITE_KEY' | 'TELL';

export type AspectValue      = 'EMBER' | 'FROST' | 'ROT'  | 'MIRE';
export type FrailtyValue     = 'FLAME' | 'COLD'  | 'SALT' | 'LIGHT';
export type WardValue        = 'FLAME' | 'COLD'  | 'SALT' | 'LIGHT';
export type DispositionValue = 'STALKER' | 'AMBUSHER' | 'TERRITORIAL' | 'FRENZIED';
export type RiteKeyValue     = 'PENANCE' | 'IMMOLATION' | 'INTERMENT' | 'SILENCE';
export type TellValue        = 'LUNGE'   | 'SWEEP'      | 'RECOIL'    | 'SHUDDER';

// The runtime enumeration of each axis's values. A union type cannot be walked at
// run time, and three places need to: the trait roll's draw, the lexicon's
// completeness check, and P154's no-self-naming rule. One list, so a new value is
// drawn, demanded of the lexicon, and forbidden from its own token, all at once.
export const AXIS_VALUES = {
  ASPECT:      ['EMBER', 'FROST', 'ROT', 'MIRE'],
  FRAILTY:     ['FLAME', 'COLD', 'SALT', 'LIGHT'],
  WARD:        ['FLAME', 'COLD', 'SALT', 'LIGHT'],
  DISPOSITION: ['STALKER', 'AMBUSHER', 'TERRITORIAL', 'FRENZIED'],
  RITE_KEY:    ['PENANCE', 'IMMOLATION', 'INTERMENT', 'SILENCE'],
  TELL:        ['LUNGE', 'SWEEP', 'RECOIL', 'SHUDDER'],
} as const satisfies Record<TraitAxis, ReadonlyArray<string>>;

export type TraitRoll = {
  aspect:       AspectValue;
  frailty:      FrailtyValue;
  tell:         TellValue;
  ward?:        WardValue;
  disposition?: DispositionValue;
  riteKey?:     RiteKeyValue;
};

export const ACTIVE_AXES: Record<Tier, ReadonlyArray<TraitAxis>> = {
  VIGIL: ['ASPECT', 'FRAILTY', 'TELL'],
  INTERDICT: ['ASPECT', 'FRAILTY', 'TELL', 'WARD', 'DISPOSITION'],
  ANATHEMA:     ['ASPECT', 'FRAILTY', 'TELL', 'WARD', 'DISPOSITION', 'RITE_KEY'],
};

// Axes whose signs ship ambiently in FIELD_STARTED / FieldSnapshot. WARD is
// excluded at every tier: the REACTION channel is probe-gated (R58, TD-025).
export const AMBIENT_AXES: Record<Tier, ReadonlyArray<TraitAxis>> = {
  VIGIL: ['ASPECT', 'FRAILTY', 'TELL'],
  INTERDICT: ['ASPECT', 'FRAILTY', 'TELL', 'DISPOSITION'],
  ANATHEMA:     ['ASPECT', 'FRAILTY', 'TELL', 'DISPOSITION', 'RITE_KEY'],
};
