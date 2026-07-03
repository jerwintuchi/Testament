// Gear catalog and bag constants (loadout-economy spec, R64). Types and
// constants only — no logic (invariant I4). Unlike SIGN_LEXICON (server-only,
// maps hidden trait values), this catalog is public requisition data the client
// renders; it carries channels and stimuli — wire-safe vocabulary — never axis values.
import type { Channel, Stimulus } from './signs.js';

export type ItemId = string;

export type GearItem = { id: ItemId; name: string } & (
  | { kind: 'PERCEPTION'; channel: Channel }    // lets its carrier read one sign channel
  | { kind: 'PROBE';      stimulus: Stimulus }  // lets its carrier present one stimulus
);

// The bounded bag: scarcity is the point (loadout-economy non-negotiable 3).
export const BAG_SLOTS = 4;

export const GEAR_CATALOG: ReadonlyArray<GearItem> = [
  // Perception gear — one per channel
  { id: 'ashen-lens',           name: "Ashen Lens",           kind: 'PERCEPTION', channel: 'RESIDUE' },
  { id: 'chirurgeons-glass',    name: "Chirurgeon's Glass",   kind: 'PERCEPTION', channel: 'STRESS_MARK' },
  { id: 'witness-prism',        name: "Witness Prism",        kind: 'PERCEPTION', channel: 'REACTION' },
  { id: 'trackers-fetish',      name: "Tracker's Fetish",     kind: 'PERCEPTION', channel: 'SPOOR' },
  { id: 'cantors-ear',          name: "Cantor's Ear",         kind: 'PERCEPTION', channel: 'LITURGY' },
  { id: 'augurs-bead',          name: "Augur's Bead",         kind: 'PERCEPTION', channel: 'OMEN' },
  // Probe kits — one per stimulus (reusable in v1)
  { id: 'censer-of-embers',     name: "Censer of Embers",     kind: 'PROBE', stimulus: 'FLAME' },
  { id: 'phial-of-hoarfrost',   name: "Phial of Hoarfrost",   kind: 'PROBE', stimulus: 'COLD' },
  { id: 'consecrated-salt',     name: "Consecrated Salt",     kind: 'PROBE', stimulus: 'SALT' },
  { id: 'lantern-of-the-creed', name: "Lantern of the Creed", kind: 'PROBE', stimulus: 'LIGHT' },
];
