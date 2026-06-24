# Veins — Progression & Rewards

> **Status:** Canon
> **Sources:** DESIGN.md + GLOSSARY.md (Meta-progression); LORE_DESIGN.md §15 (Endings as milestones); SYSTEM DESIGN DOC.md §7 (Reward logic)
> **See also:** [systems/extraction.md](systems/extraction.md) · [lore.md](lore.md) · [technical/stack-and-deployment.md](technical/stack-and-deployment.md)

## Meta-progression

Cross-run persistent data: **unlocked relics, cosmetics, achievement flags**. This is the *only* data that hits the database (Supabase). Active runs are never persisted (see [technical/netcode.md](technical/netcode.md), invariant I7).

Meta horizon: **months**. Per-run sessions: 20–40 min.

What persists across runs:
- unlocks (new relics entering the roster)
- relic roster expansion
- cosmetics

## Reward logic

Rewards at run end depend on:
- depth reached,
- doctrine alignment strength (see [systems/doctrine-tracking.md](systems/doctrine-tracking.md)),
- boss interpretation outcome (see [content/bosses.md](content/bosses.md)).

A meaningful per-run stat already surfaced today: **enemies killed**, shown on the post-run screen.

## Endings as progression milestones

Endings are layered (narrative detail in [lore.md](lore.md)):

- **Run endings** — escape, wipe, sacrifice.
- **Zone endings** — local truths.
- **Cycle endings** — meta-progression milestones.
- **Faction endings** — interpretive conclusions (see [factions.md](factions.md)).

> Every ending is valid but incomplete.

Extraction outcomes (normal / forced / sacrificial / wipe) that feed reward logic are specified in [systems/extraction.md](systems/extraction.md).
