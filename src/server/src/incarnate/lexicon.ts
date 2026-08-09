import type { Channel, SignToken } from '@testament/shared';
import type { TraitAxis } from './types.js';

export type LexiconEntry = {
  axis:    TraitAxis;
  value:   string;
  channel: Channel;
  token:   SignToken;
};

/**
 * The token for one (axis, value) pair — the lookup that keeps token literals out
 * of the rest of the tree.
 *
 * Before this existed, ~25 assertions across 8 test files pinned token strings
 * directly, so re-authoring the table meant editing all of them (TD-093). Tests now
 * ask `tokenFor('FRAILTY', 'FLAME')` and the only literals left are this table and
 * its own pinning test. Server-side beside the table it reads, so I4 holds.
 *
 * Throws rather than returning undefined: a missing entry is a hole in the lexicon,
 * and `deriveSigns` would otherwise ship a silent `undefined` onto the wire.
 */
export function tokenFor(axis: TraitAxis, value: string): SignToken {
  const entry = SIGN_LEXICON.find(e => e.axis === axis && e.value === value);
  if (!entry) throw new Error(`Sign lexicon missing entry: axis=${axis} value=${value}`);
  return entry.token;
}

/**
 * The sign language: one stable token per (axis, value). Re-authored in TD-093.
 *
 * P154 governs every entry — a token names WHAT WAS SEEN, never what it means. The
 * player performs the inferential step; the table never performs it for them. Eleven
 * of the original 24 entries carried their own answer (`flinch-from-flame`), so for
 * two of six axes the reading problem was not implemented at all.
 *
 * The step must be recoverable by reasoning about the world, not by domain knowledge:
 * `spalled-stone` was rejected for EMBER because spalling is masonry jargon, and the
 * same test retires any future token leaning on a technical term.
 *
 * Tokens are OPAQUE WIRE IDENTIFIERS. They are never rendered to a player — the
 * client authors prose over them (`sign_prose.gd`), which is what lets Origin dialect
 * vary the wording later without moving the token.
 */
export const SIGN_LEXICON: ReadonlyArray<LexiconEntry> = [
  // ASPECT → RESIDUE — what the fabric of the place remembers.
  { axis: 'ASPECT', value: 'EMBER', channel: 'RESIDUE',      token: 'run-wax'            },
  { axis: 'ASPECT', value: 'FROST', channel: 'RESIDUE',      token: 'heaved-mortar'      },
  { axis: 'ASPECT', value: 'ROT',   channel: 'RESIDUE',      token: 'bloomed-iron'       },
  { axis: 'ASPECT', value: 'MIRE',  channel: 'RESIDUE',      token: 'weeping-clay'       },
  // FRAILTY → STRESS_MARK — what a wound gives up.
  //
  // These four are not four strings to memorise; they are one law (R340):
  // A WOUND NAMES THE SUBSTANCE; THE SUBSTANCE NAMES THE REMEDY. Tallow takes a
  // flame, spent heat wants cold, water held in a shape is drawn out by salt, and a
  // thing made of dark is undone by light. Learn the sentence, derive all four — and
  // the fifth when it ships. Author new values so the law still predicts them.
  { axis: 'FRAILTY', value: 'FLAME', channel: 'STRESS_MARK', token: 'tallow-sweat'       },
  { axis: 'FRAILTY', value: 'COLD',  channel: 'STRESS_MARK', token: 'fever-sweat'        },
  { axis: 'FRAILTY', value: 'SALT',  channel: 'STRESS_MARK', token: 'clear-weep'         },
  { axis: 'FRAILTY', value: 'LIGHT', channel: 'STRESS_MARK', token: 'shadow-bleed'       },
  // WARD → REACTION (probe-driven) — what it does with what you offered.
  //
  // Flavour, and labelled honestly as such (R342): Reaction is a CONFIRMATION channel.
  // The party supplies the hypothesis by choosing the stimulus (which PROBE_RESULT
  // echoes back), so no wording could make these informative. They name the INSTRUMENT
  // presented — brand, rime, grain, lamp — never the element enum, so P154 holds.
  //
  // Kept per-element rather than collapsed to one token: `revealedSigns` dedupes by
  // token and is what a reconnecting player's snapshot restores, so a shared token
  // would silently lose WHICH ward matched (P157) — on the one axis that costs
  // exposure to learn.
  { axis: 'WARD', value: 'FLAME', channel: 'REACTION', token: 'swallowed-the-brand'      },
  { axis: 'WARD', value: 'COLD',  channel: 'REACTION', token: 'swallowed-the-rime'       },
  { axis: 'WARD', value: 'SALT',  channel: 'REACTION', token: 'swallowed-the-grain'      },
  { axis: 'WARD', value: 'LIGHT', channel: 'REACTION', token: 'swallowed-the-lamp'       },
  // DISPOSITION → SPOOR — what the ground records.
  { axis: 'DISPOSITION', value: 'STALKER',     channel: 'SPOOR', token: 'prints-in-our-prints' },
  { axis: 'DISPOSITION', value: 'AMBUSHER',    channel: 'SPOOR', token: 'still-spoor'          },
  { axis: 'DISPOSITION', value: 'TERRITORIAL', channel: 'SPOOR', token: 'tracks-turn-back'     },
  { axis: 'DISPOSITION', value: 'FRENZIED',    channel: 'SPOOR', token: 'broken-stride'        },
  // RITE_KEY → LITURGY — the shape of its devotion.
  { axis: 'RITE_KEY', value: 'PENANCE',    channel: 'LITURGY', token: 'worn-knee-stone'   },
  { axis: 'RITE_KEY', value: 'IMMOLATION', channel: 'LITURGY', token: 'ash-offering'      },
  { axis: 'RITE_KEY', value: 'INTERMENT',  channel: 'LITURGY', token: 'covered-dead'      },
  { axis: 'RITE_KEY', value: 'SILENCE',    channel: 'LITURGY', token: 'voided-glyph'      },
  // TELL → OMEN — the wind-up.
  //
  // KEPT VERBATIM, and this is not an oversight (R341). The interpretation budget
  // follows the clock: OMEN is read in milliseconds while something is about to kill
  // you, so its budget is ZERO and it is transparent BY DESIGN. `full-body-tremor`
  // being a near-synonym of SHUDDER is correct — TD-013 makes the Tell the survival
  // payoff, and a player cannot deduce during a wind-up. Anyone "fixing" these has
  // misread the design.
  { axis: 'TELL', value: 'LUNGE',   channel: 'OMEN', token: 'drawn-breath-and-lean'      },
  { axis: 'TELL', value: 'SWEEP',   channel: 'OMEN', token: 'wide-shoulder-coil'         },
  { axis: 'TELL', value: 'RECOIL',  channel: 'OMEN', token: 'backward-step-brace'        },
  { axis: 'TELL', value: 'SHUDDER', channel: 'OMEN', token: 'full-body-tremor'           },
];
