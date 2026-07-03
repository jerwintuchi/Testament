// Distributed Perception (R60, R66): channel derivation and sign filtering.
// Since the loadout-economy spec, perception is a consequence of the bag (TD-007):
// a party member reads exactly the channels of the perception gear they carry.
// Solo perceives all tier channels regardless of gear (TD-008: solo is balanced
// by tempo and bag pressure, never by withholding information).
import type { Channel, ItemId, Sign, Stimulus, Tier } from '@testament/shared';
import { CHANNELS, GEAR_CATALOG } from '@testament/shared';
import type { TraitAxis } from '../incarnate/types.js';
import { AMBIENT_AXES } from '../incarnate/types.js';

const AXIS_TO_CHANNEL: Record<TraitAxis, Channel> = {
  ASPECT:      'RESIDUE',
  FRAILTY:     'STRESS_MARK',
  TELL:        'OMEN',
  WARD:        'REACTION',
  DISPOSITION: 'SPOOR',
  RITE_KEY:    'LITURGY',
};

// The channels that can carry a sign this expedition: ambient channels for the
// tier plus REACTION (probe-gated), in canonical order.
export function channelsForTier(tier: Tier): Channel[] {
  const relevant = new Set<Channel>(AMBIENT_AXES[tier].map(a => AXIS_TO_CHANNEL[a]));
  relevant.add('REACTION');
  return CHANNELS.filter(c => relevant.has(c));
}

// Gear is not filtered by tier relevance: packing a Cantor's Ear for an
// Apprentice hunt reads nothing — a wasted slot is the player's own bad bet.
export function perceivedChannelsFor(bag: ItemId[], isSolo: boolean, tier: Tier): Channel[] {
  if (isSolo) return channelsForTier(tier);
  const carried = new Set<Channel>();
  for (const item of GEAR_CATALOG) {
    if (item.kind === 'PERCEPTION' && bag.includes(item.id)) carried.add(item.channel);
  }
  return CHANNELS.filter(c => carried.has(c));
}

export function hasProbeKit(bag: ItemId[], stimulus: Stimulus): boolean {
  return GEAR_CATALOG.some(
    item => item.kind === 'PROBE' && item.stimulus === stimulus && bag.includes(item.id),
  );
}

export function filterSigns(signs: Sign[], channels: Channel[]): Sign[] {
  return signs.filter(s => channels.includes(s.channel));
}
