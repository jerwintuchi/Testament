// Rank authorization (R355–R358, TD-095). The DECISION lives here, not in shared:
// `canAccept` is game logic, and I4 keeps shared to types + constants.
import type { Rank, Tier } from '@testament/shared';
import { RANK_ACCEPTS } from '@testament/shared';

// ─────────────────────────────────────────────────────────────────────────────
// A DEVELOPMENT AFFORDANCE, NOT A BALANCE DECISION (R358).
//
// Collegium Rank is persistent (TD-006), and there is no account layer to hold
// it — `src/server/` writes nothing to disk, and `playerId` is a fresh UUID per
// join, so there is nothing durable to attach a rank to. Real Rank is ROADMAP
// Phase 7; TD-095 records why it cannot use TD-082's client-side stand-in (a
// display name is a convenience, a Rank is a PERMISSION).
//
// So every player is issued the top rank, deliberately, so all content stays
// reachable while the gate itself is built and tested. When Phase 7 lands, only
// the SOURCE of this value changes — the gate and its shape stay as they are.
//
// Do not read this as "everyone is a Hierophant" balance. Nothing is balanced here.
// ─────────────────────────────────────────────────────────────────────────────
export const DEFAULT_RANK: Rank = 'HIEROPHANT';

// May this rank take responsibility for this tier?
//
// Rank gates what you may LEAD, not what you may JOIN (author ruling, TD-095):
// only the accepting player is ever checked. A Seeker may join an Anathema hunt
// led by a Confessor — a veteran bringing a newcomer along is Pillar 4 working
// for free, and it is how the sign language gets taught out loud.
export function canAccept(rank: Rank, tier: Tier): boolean {
  return RANK_ACCEPTS[rank].includes(tier);
}
