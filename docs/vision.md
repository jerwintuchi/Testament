# Veins — Vision & Target Experience

> **Status:** Mixed (canon design pillars + draft emotional-identity notes)
> **Sources:** DESIGN.md ("Why This Works", "Target Experience", "Session Structure"); LORE_DESIGN.md §16; SYSTEM DESIGN DOC.md §8; GPT_CHAT_HISTORY.txt (draft, "what should Veins FEEL like")
> **See also:** [pitch.md](pitch.md) · [art-bible.md](art-bible.md) · [doctrines.md](doctrines.md)

## Why This Works

- **Forced communication:** synergies require coordination to discover and exploit.
- **Asymmetric roles emerge naturally** from the board, not from class selection.
- **Every run is a different party build problem** — replayability is inherent.
- **Extraction tension** makes every floor a group negotiation, not a solo decision.

## Session Structure (experience framing)

1. Lobby → room code join (2–4 players)
2. Run starts: dungeon generated server-side from run ID seed
3. Floors: fight → loot → place relics → descend or extract
4. Bleed Clock ticks; depth multiplies drain rate
5. Extract or die → post-run meta-progression update
6. Meta-progression: unlocks, relic roster expansion, cosmetics

(The mechanical loop is specified in [prototype-v1.md](prototype-v1.md).)

## Target Experience

Sessions: 20–40 min. Meta: months. Browser-only. Free at $0 cost until hundreds of concurrent players.

## Core Psychological Hook

Players do not choose classes. They reveal beliefs under pressure.

> Build = Doctrine
> Doctrine = Behavior under stress
> Behavior = World interpretation

## Non-negotiable design principles

(from SYSTEM DESIGN DOC §8)

1. **No explicit doctrine UI.** Players never see "Sanctum +12" — only effects. See [doctrines.md](doctrines.md) and [ui-style-guide.md](ui-style-guide.md).
2. **Delayed consequence.** The world reacts *after* behavior is established, not immediately — this creates the illusion of memory and intent.
3. **Build = belief consistency, not optimization.** Consistency matters more than raw power.
4. **Co-op is structural, not optional.** The game assumes multiple players; solo is a deliberately relaxed secondary mode (see [systems/solo-play.md](systems/solo-play.md)).

---

## Draft / Exploratory — Emotional identity

> Mined from `GPT_CHAT_HISTORY.txt`. Not yet canon — captures the intended *feel*, to be ratified.

Veins should not feel heroic, bright, or like a Diablo power fantasy. The mechanics are about dependency, sacrifice, shared life, organisms, entropy, pressure, and extraction tension. Everything should say one thing:

> "We are one body trying to survive." — *Four cells inside a dying organism.*

The strongest version of Veins is **biopunk organism horror with melancholy beauty**, where every system — relic adjacency, revives, the Bleed Clock — reinforces one idea: *you are not four heroes, you are one body.* Players should walk away saying "the four of us became this weird organism and survived by sacrificing parts of ourselves," not "I played a roguelike."
