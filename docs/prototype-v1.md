# Veins — Prototype v1 (Playable Vertical Slice)

> **Status:** Canon
> **Sources:** SYSTEM DESIGN DOC.md §0 (Scope), §1 (Game loop + session length), §9 (Success criteria); cross-ref DECISION_LOG.md for current build status
> **See also:** [systems/](systems/) · [content/](content/) · [DECISION_LOG.md](DECISION_LOG.md)

## Scope of v1

**In scope:**
- 1 full playable dungeon run loop
- 1 biome set (the initial **Atrium** — see [content/biomes.md](content/biomes.md))
- 10–15 relics (see [content/relic-roster.md](content/relic-roster.md))
- 1 boss (the Doctrine Test Boss — see [content/bosses.md](content/bosses.md))
- Circulatory Board system (core mechanic — [systems/circulatory-board.md](systems/circulatory-board.md))
- Basic doctrine tracking (hidden — [systems/doctrine-tracking.md](systems/doctrine-tracking.md))
- Extraction + Bleed Clock loop ([systems/extraction.md](systems/extraction.md), [systems/bleed-clock.md](systems/bleed-clock.md))

**NOT in v1:**
- full faction roster
- full mutation system (see [content/mutations.md](content/mutations.md))
- multiple biomes
- full meta-progression system

## Core game loop

1. Lobby (room code join, 2–4 players — solo also supported, see [systems/solo-play.md](systems/solo-play.md))
2. Spawn in Atrium
3. Repeat: combat room → loot room (relic choice) → board placement phase → Bleed Clock updates
4. Mid-boss encounter
5. Final boss encounter
6. Extraction OR wipe
7. Reward + persistence update (see [progression.md](progression.md))

**Session length target:** 20–30 min/run · 5–8 rooms before boss · 1 boss per run (v1).

## V1 success criteria

If successful, players should say:

- "Our build felt like a philosophy."
- "The boss reacted to how we played."
- "We accidentally built synergy that felt intentional."
- "The game felt like it was watching us."

## Current build status

The implemented vertical slice has progressed well beyond the original v1 paper design (625 tests passing as of 2026-06-24). Authoritative, dated build history lives in the append-only [DECISION_LOG.md](DECISION_LOG.md); implemented systems are summarized in [systems/](systems/), [content/](content/), and [technical/](technical/). Where the paper design and the implementation differ (e.g. the doctrine *scoring* system that landed, or the realized enemy roster vs. the brainstorm "pathologies"), the system/content files note it.
