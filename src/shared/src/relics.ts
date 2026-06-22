import type { Relic } from './board.js';

export const STARTER_RELICS: Relic[] = [
  // --- Tumor doctrine: spread, mutation, biological growth ---
  {
    id: 'blooming-wound',
    name: 'The Blooming Wound',
    tags: ['aoe', 'tumor'],
    baseEffect:    { description: 'Attacks detonate on impact, scattering caustic ichor (+5 damage).' },
    synergyEffect: { description: 'The detonation tears outward — enemies within 40 units of the target take 50% of the hit.' },
  },
  {
    id: 'systemic-rot',
    name: 'Systemic Rot',
    tags: ['tumor'],
    baseEffect:    { description: 'Wounds you open refuse to close — enemies bleed for 3 damage per second for 3 seconds.' },
    synergyEffect: { description: 'The rot is communicable: the bleeding spreads to one adjacent enemy on application.' },
  },
  // --- Sanctum doctrine: deliberate setup, stable conditions, controlled payoff ---
  {
    id: 'still-vigil',
    name: 'Still Vigil',
    tags: ['precision', 'sanctum'],
    baseEffect:    { description: 'Attacks deal +8 damage to enemies that are already bleeding.' },
    synergyEffect: { description: 'Precise strikes against bleeding enemies extend the wound\'s duration by 1.5 seconds.' },
  },
  // --- Chorus doctrine: chain propagation, cross-player neural signals ---
  {
    id: 'synaptic-filament',
    name: 'Synaptic Filament',
    tags: ['chain', 'aoe', 'chorus'],
    baseEffect:    { description: 'A sliver of neural tissue fires with each attack — 20% chance to arc to one nearby enemy for 60% damage.' },
    synergyEffect: { description: 'The arc becomes a thread: it pierces through its first target.' },
  },
  {
    id: 'resonant-cord',
    name: 'Resonant Cord',
    tags: ['chain', 'chorus'],
    baseEffect:    { description: 'A living cord strung between signals. 30% chance each attack resonates to one nearby enemy for 60% damage.' },
    synergyEffect: { description: 'The resonance radiates outward — a 35% damage wave strikes all enemies within 35 units of the chain target.' },
  },
  {
    id: 'chorus-spine',
    name: 'Chorus Spine',
    tags: ['chain', 'aoe', 'chorus'],
    baseEffect:    { description: 'Structural backbone of a distributed mind. 15% chance each attack signals through to one nearby enemy for 60% damage.' },
    synergyEffect: { description: 'The signal floods outward — a 30% damage pulse hits all enemies within 30 units of the chain target.' },
  },
  // --- Sanctum doctrine: calcification, ossification, stable structural defense ---
  {
    id: 'calcified-shell',
    name: 'Calcified Shell',
    tags: ['shield', 'sanctum'],
    baseEffect:    { description: 'A crust of ossified tissue hardens around you. Reduces all incoming damage by 5 (minimum 1).' },
    synergyEffect: { description: 'The shell reaches its ideal form: absorbs the next attack each floor. Resets on floor clear.' },
  },
  {
    id: 'latticed-node',
    name: 'Latticed Node',
    tags: ['shield', 'sanctum'],
    baseEffect:    { description: 'A geometric growth within the Veins. Reduces all incoming damage by 6 (minimum 1).' },
    synergyEffect: { description: 'When adjacent to another shield relic on the board, the lattice locks in — reduction becomes 9 instead.' },
  },
  // --- Chorus doctrine: votive offering, party protection, given tissue ---
  {
    id: 'votive-tissue',
    name: 'Votive Tissue',
    tags: ['shield', 'party', 'chorus'],
    baseEffect:    { description: 'Biological matter offered willingly. Adjacent allied players on the board take 2 less damage.' },
    synergyEffect: { description: 'The offering is reinforced by alignment — adjacent allies take 4 less damage instead.' },
  },
  // --- Neutral: crossroads of precision and void, no doctrine alignment ---
  {
    id: 'hollow-lens',
    name: 'The Hollow Lens',
    tags: ['precision', 'aoe'],
    baseEffect:    { description: 'A lens ground from absence. All attacks deal +4 damage.' },
    synergyEffect: { description: 'The void radiates outward: attacks also deal 40% of their damage to all enemies within 30 units.' },
  },
];

export const STARTER_RELIC_IDS: string[] = STARTER_RELICS.map(r => r.id);
