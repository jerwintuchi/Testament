# Loadout (Bag) Economy

> **Status:** Drafted. Where Pillar 1 (preparation) and Pillar 4 (cooperation) become one decision (TD-007).
> **Spine:** Observe → Hypothesize → Test → Record  ·  **Index:** [../README.md](../README.md)
> **See also:** [distributed-perception.md](distributed-perception.md) · [combat.md](combat.md) · [contracts.md](contracts.md)

## Purpose

The scarce resource that turns preparation into a real decision: bag space. What the party
carries decides who can fight, who can read, and who can perform the rite, all at once.

## Design Philosophy

### Each Seeker carries a bounded bag; the party's bags are the kit

Every Seeker has a bounded **bag**. The party's combined bags are the loadout, so
preparation is a party-level coordination of individual bags. Three things compete for slots:

- **Combat tools** (the thrown relics, ward beams, and ritual casts that layer on the melee core, [combat.md](combat.md)).
- **Perception gear** (which sign channels a Seeker can read, [distributed-perception.md](distributed-perception.md)).
- **Method gear** (probes, and the rites that enable non-kill verbs via the Rite-key).

Because melee costs no slot (TD-011), the bag is *entirely* the reading-and-tool layer. So
the central tradeoff is legible: every probe or rite you carry is a fighting tool or a sign
channel you did not. A party either **specializes** (a fragile investigator loaded with
perception and rites) or **spreads** (resilient, weaker at any one thing). That is the
cooperation engine (TD-007), and it is the same decision as distributing perception.

### Unfunded — the bag pays for itself, and the bet is which four

There is **no currency** (TD-091: the Stipend is retired). Requisition is bounded by bag
slots alone, because every item is a **key** — a channel you can read, a stimulus you can
present — not a power level. A price could therefore only be a no-op (flat: any four items
cost what any other four cost) or the ladder this system forbids (varied: gear ranked by
worth). What you requisition is still a bet on the contract's (falsifiable) intel: bring the
wrong counters and the hunt is survivable but expensive.

**The accepted cost of that ruling** (TD-091, recorded so it is not rediscovered as a bug):
bag slots are per-Seeker and linear in party size, while the reading catalog is permanently
bounded at six channels and four stimuli. So a party of three or four carries **every** reading
instrument and scarcity stops binding at those sizes; solo and duo keep it. No amount of future
content changes this — only a non-linear party allowance, fewer slots, or consumable charges
would, and the first was weighed and rejected.

The **Blessing** (deferred, TD-017) layers an ephemeral per-Seeker wildcard on top of the
deliberate loadout; it never replaces the chosen kit.

## Non-negotiable Rules

1. **Melee costs no slot** (TD-011); the bag is the tool, perception, and rite layer only.
2. Gear is valued by **utility, not raw power** (TD-017, Pillar 2). No "bigger numbers" shopping ladder.
3. The bag is **bounded**; scarcity is the point. A loadout that needs nothing is a design failure.
4. Preparation is a **bet** on partial, sometimes-wrong intel ([contracts.md](contracts.md)). It must never be a guaranteed answer.
5. **No purchasable combination may yield certainty on an axis without inference** (TD-091). Carrying every probe kit currently turns Ward from a deduction into a four-step lookup; that is a memorizable *procedure* substituting for a read, which vision.md non-negotiable 1 forbids in spirit. Consumable charges are the indicated fix and are already implied by [investigation-and-probing.md](investigation-and-probing.md).
6. **There is no currency** (TD-091). If a future system wants to meter preparation, it does so in slots, charges, or instruments — never in coin, which would state an exchange rate between reading and winning the moment combat tools sit priced beside lenses.

## Implementation Notes

- **Data shape:** `Bag = { slots: Item[] (bounded) }` per Seeker; `Item` is a `CombatTool | PerceptionGear | Probe | Rite`, each tagged with what trait axis or channel it serves.
- **No Stipend, no prices** (TD-091). Requisition happens at the Collegium pre-deploy and the server validates **slot count only**; it holds loadout state and validates every field action against what the actor actually carries.
- Perception gear sets the Seeker's channel set ([distributed-perception.md](distributed-perception.md)); rites carry a Rite-key match used by [combat.md](combat.md) for the method verbs.
- New code; only light inventory plumbing patterns carry from the prototype.

## Future Expansion

- The **gear and rite catalog** as data ([../content/relics-and-rites.md](../content/relics-and-rites.md)), authored for hundreds of entries.
- The **Blessing** system (built post-core, TD-017).
- Slot-budget tuning; the requisition interface (`specs/quartermaster/` Phase A).
- **Consumable charges on probe kits** — the open follow-up from TD-091, and the fix for
  non-negotiable 5. Charges are slot-free, so they also give solo/party a clean asymmetry:
  surplus buys *depth* (more tests, fewer tools) or *breadth* (more channels, fewer tests each).
