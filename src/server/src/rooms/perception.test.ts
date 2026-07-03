// T63: channelsForTier, filterSigns (R60, P26)
// T69: perceivedChannelsFor, hasProbeKit — perception follows gear (R66, R67, P32)
import { describe, it, expect } from 'vitest';
import { channelsForTier, perceivedChannelsFor, hasProbeKit, filterSigns } from './perception.js';
import type { Sign, Tier } from '@testament/shared';
import { CHANNELS } from '@testament/shared';

const TIERS: Tier[] = ['APPRENTICE', 'JOURNEYMAN', 'MASTER'];

describe('channelsForTier', () => {
  it('Apprentice: ambient channels plus REACTION, canonical order', () => {
    expect(channelsForTier('APPRENTICE')).toEqual(['RESIDUE', 'STRESS_MARK', 'REACTION', 'OMEN']);
  });

  it('Journeyman: adds SPOOR', () => {
    expect(channelsForTier('JOURNEYMAN')).toEqual(['RESIDUE', 'STRESS_MARK', 'REACTION', 'SPOOR', 'OMEN']);
  });

  it('Master: all six channels', () => {
    expect(channelsForTier('MASTER')).toEqual(CHANNELS);
  });
});

describe('perceivedChannelsFor (T69, P32)', () => {
  it('solo perceives the full tier set regardless of bag (TD-008)', () => {
    for (const tier of TIERS) {
      expect(perceivedChannelsFor([], true, tier)).toEqual(channelsForTier(tier));
      expect(perceivedChannelsFor(['censer-of-embers'], true, tier)).toEqual(channelsForTier(tier));
    }
  });

  it('party perception equals exactly the carried PERCEPTION channels, canonical order', () => {
    const bag = ['augurs-bead', 'ashen-lens'];  // OMEN + RESIDUE, packed out of order
    expect(perceivedChannelsFor(bag, false, 'MASTER')).toEqual(['RESIDUE', 'OMEN']);
  });

  it('probe kits contribute no perception', () => {
    const bag = ['censer-of-embers', 'phial-of-hoarfrost', 'consecrated-salt', 'lantern-of-the-creed'];
    expect(perceivedChannelsFor(bag, false, 'MASTER')).toEqual([]);
  });

  it('empty bag in a party → empty set (blindness is a legal bad bet)', () => {
    expect(perceivedChannelsFor([], false, 'JOURNEYMAN')).toEqual([]);
  });

  it('gear is not filtered by tier relevance (a wasted slot is the player\'s bet)', () => {
    // Cantor's Ear reads LITURGY, which carries no sign at Apprentice — still assigned.
    expect(perceivedChannelsFor(['cantors-ear'], false, 'APPRENTICE')).toEqual(['LITURGY']);
  });

  it('unknown ids are ignored', () => {
    expect(perceivedChannelsFor(['not-a-real-item'], false, 'MASTER')).toEqual([]);
  });
});

describe('hasProbeKit (T69, R67)', () => {
  it('true only for the matching carried kit', () => {
    const bag = ['phial-of-hoarfrost', 'ashen-lens'];
    expect(hasProbeKit(bag, 'COLD')).toBe(true);
    expect(hasProbeKit(bag, 'FLAME')).toBe(false);
    expect(hasProbeKit(bag, 'SALT')).toBe(false);
    expect(hasProbeKit(bag, 'LIGHT')).toBe(false);
  });

  it('false for an empty bag', () => {
    expect(hasProbeKit([], 'COLD')).toBe(false);
  });

  it('perception gear is not a probe kit', () => {
    expect(hasProbeKit(['witness-prism'], 'COLD')).toBe(false);
  });
});

describe('filterSigns', () => {
  const signs: Sign[] = [
    { channel: 'RESIDUE',     token: 'scorched-wax' },
    { channel: 'STRESS_MARK', token: 'flinch-from-flame' },
    { channel: 'OMEN',        token: 'drawn-breath-and-lean' },
    { channel: 'REACTION',    token: 'drinks-cold' },
  ];

  it('keeps exactly the in-set signs, preserving order (P28)', () => {
    expect(filterSigns(signs, ['RESIDUE', 'REACTION'])).toEqual([
      { channel: 'RESIDUE',  token: 'scorched-wax' },
      { channel: 'REACTION', token: 'drinks-cold' },
    ]);
  });

  it('returns everything when the set covers all channels, nothing for an empty set', () => {
    expect(filterSigns(signs, [...CHANNELS])).toEqual(signs);
    expect(filterSigns(signs, [])).toEqual([]);
  });
});
