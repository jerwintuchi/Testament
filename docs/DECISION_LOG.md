# Decision Log — Testament

Append-only. Never edit a past entry; only add new ones. Each entry records a
decision, the context that forced it, and the consequences that follow.

---

## TD-001 — Reboot: Veins → Testament (2026-06-28)

**Decision.** Treat Veins as a finished prototype and build a new game, Testament,
on its technical foundations. This is not a refactor; it is a new game.

**Context.** Veins validated the multiplayer architecture (authoritative server,
ephemeral rooms, seeded procedural generation) but its design (Circulatory Board,
Bleed Clock, doctrine system) is being replaced wholesale.

**Consequences.** Kept: the Node authoritative server, room/session lifecycle, 20Hz
tick, seeded RNG, dungeon/layout generation, movement, collision, projectiles,
pathfinding, separation, and the trust boundary. Retired: all Veins game *rules*.
The React/Phaser client is replaced by a Godot client (TD-002). Veins docs moved to
`docs/archive/veins/`. The Veins WIP is preserved on branch `testament-reboot` at
checkpoint `7983aba`; `master` stays at the last clean Veins commit as a reference.

## TD-002 — Client = Godot 4.x; transport = raw WebSocket (2026-06-28)

**Decision.** Replace the React/Phaser client with a Godot 4.x (GDScript) top-down
2D pixel-art client exported to HTML5, and migrate the server transport from
Socket.io to **raw WebSocket with a JSON message envelope**.

**Context.** Godot speaks raw `WebSocketPeer` natively and exports cleanly to HTML5.
Socket.io layers its own Engine.IO handshake on top of WebSocket, which Godot does
not speak natively; community Socket.io clients are fragile. The server's handler
core is already abstracted behind an interface, so the boundary swap is contained.

**Consequences.** The wire protocol becomes the single source of truth and must be
language-neutral (TypeScript server, GDScript client honoring the same shapes).
`src/shared` shifts from "TypeScript types both halves import" to "the protocol
contract the server implements and the client mirrors." `@veins/shared` and other
Veins-named packages will be renamed in a later pass.

## TD-003 — Core spine: the scientific method as a co-op hunt (2026-06-28)

**Decision.** The core loop is **Observe → Hypothesize → Test → Record**. Players
read an Incarnate, form a theory, bet their preparation on it, and record the verdict.

**Context.** Considered three spines: diagnosis-first (A), counter-build/adaptive
hunt (B), and collective-inquiry arc (C). The chosen design grounds A's diagnosis in
B's pre-expedition preparation and a fallible hypothesis, with C reduced to a
session-scoped party knowledge base. This is the configuration where all five pillars
are load-bearing and that is furthest from "Monster Hunter with cathedrals."

**Consequences.** Every system is reviewed against the spine. The full loop is
specified in [gameplay.md](gameplay.md); the constitution is [vision.md](vision.md).

## TD-004 — No doom clock; commitment via Surety + Recant + reactive pressure (2026-06-28)

**Decision.** Field pressure is diegetic and reactive (rising Incarnate awareness,
decay, weather, closing routes), never a timer. Commitment is staked at acceptance
(the Surety); abandoning a contract (Recant) costs the stake and standing, with no
death-lock. A failed or recanted expedition still writes a Field Testament.

**Context.** A doom clock punishes careful investigation, which is the exact skill
Pillar 3 rewards. The question "does the game have to punish hesitation?" is answered:
it punishes recklessness and poor preparation, not deliberation.

**Consequences.** Preserves the prototype's extraction-tension feeling without the
Bleed Clock. Makes Pillar 5 literally true (failure teaches) and makes failure
productive for a co-op game where wipes happen.

## TD-005 — Interpretation model: sign language + active probing (2026-06-28)

**Decision.** Hidden Incarnate traits manifest as a **legible sign language**:
consistent, observable signs whose meaning is stable game-truth, plus **active
probing** to test the thing in the field. Each Incarnate's specific trait roll is
hidden and re-rolled per expedition.

**Context.** Pillar 3 forbids memorization but must not become blind guessing. The
sign language is the bridge: players learn a vocabulary (skill), then diagnose each
fresh roll (interpretation). A hunter-scholar is a doctor reading symptoms.

**Consequences.** The trait roll never leaves the server (CLAUDE.md invariant 3); the
wire carries only signs. The sign language is never a label, a percentage, or a
persisted unlock. The forced-cooperation engine is **distributed perception**:
party members perceive different sign-channels and must assemble the theory by talking.

## TD-006 — Persistence split: thin account layer only (2026-06-28)

**Decision.** Persist only identity, cosmetics, Collegium rank, customization, and
career stats. Everything about an expedition, including the party's session Archive,
is ephemeral and lives in server memory only.

**Context.** Knowledge-as-progression (Pillar 2) is satisfied by player *skill* and a
session-scoped Archive, not by a persisted knowledge database. Collegium rank grants
access and options, not raw power, to avoid a stat grind that would dull the roguelike.

**Consequences.** Supabase (or its successor) survives only for the thin account
layer. No game-state persistence mid-expedition. Server restart loses active
expeditions (acceptable; sessions are short).

## TD-007 — Loadout (bag) economy forces and shares roles (2026-06-28)

**Decision.** A limited shared bag forces a tradeoff between combat capability and
probing/ritual gear. Parties either specialize (a fragile investigator) or spread the
tools (resilient, less peak performance).

**Context.** Raised by the user as the link between preparation and role distribution.

**Consequences.** Pillar 1 (preparation) and Pillar 4 (cooperation) become the same
decision. Relic and rite *combinations* live in the loadout. Bag-slot budget is open
tuning, deferred to a spec.

## TD-008 — Party scaling: 1 to 4 players, solo fully supported (2026-06-28)

**Decision.** The game must feel complete at 1, 2, 3, and 4 players. Solo is fully
supported and never treated as lacking; co-op remains the design center.

**Context.** Not all players have friends available; party size must not be a
constraint on access. Distributed perception relaxes for solo (a lone scholar
perceives all channels but is stretched thin).

**Consequences.** Difficulty and the perception model scale with party size; the game
does not become a different game per size. This is a standing constraint on every
system design.

## TD-009 — Combat stays real-time top-down action (2026-06-28)

**Decision.** Keep real-time, top-down action combat (the prototype's 20Hz tick,
projectiles, movement), reskinned for gothic weight and tone.

**Context.** Matches the art direction (Blasphemous, Castlevania) and preserves the
most-reusable server technology.

**Consequences.** The combat tick and projectile systems carry over with reflavoring;
the doctrine/synergy/Bleed-Clock logic layered on top of them does not.

## TD-010 — Lore metaphysics: present God, sacred decay, unresolved Incarnates (2026-06-28)

**Decision.** The fiction rests on three canon pillars: (1) there is one true,
reigning, holy God, genuinely present, not dead or absent, whose apparent "silence"
is a subjective human reading; (2) reality undergoes an ongoing **sacred decay** with
no single slayable author; (3) **Incarnates** are phenomena born of belief, sin, or
broken relics whose true nature is never resolved, only classified from observable
facts. The Collegium hunts as "the last attempt to understand reality," with
historical (not magical) authority, to witness, contain, or redeem rather than to
kill for loot. The **Choirs** are generational doctrinal lineages that disagree.

**Context.** Set by the Creative Director answering the three lore questions left open
at the Phase 0 gate. The "no universal answer, only classification from observable
facts" principle makes the sign-language mechanic a truth of the world, not a game
concession (Lore = Mechanics).

**Consequences.** Enforced in code by invariant 3 (the Incarnate trait roll never
leaves the server; only signs do). Forbids any "true nature" reveal, any dead-god
framing, and any cause-boss whose death repairs reality. Proper nouns (God's name,
the world, the founding events, specific Choirs, the order's saying, the
miracle-moment system) remain open for the Director. Full fiction in docs/lore.md and
docs/lore/.

## TD-011 — Combat identity: hybrid melee core plus tools (2026-06-28)

**Decision.** Combat is a weighty **melee core** (gothic tone, Blasphemous/Castlevania
register) layered with **ritual and ranged tools** (thrown relics, ward beams, ritual
casts). The tools are the party's counters and reuse the prototype's projectile/tick tech;
melee is the always-available baseline.

**Context.** The kept prototype combat is ranged/projectile auto-fire, but the art tone is
melee. Hybrid fits the feel while still reusing the tick and projectile systems for the
tool layer.

**Consequences.** The bag economy now reads as "how much of the bag is fighting-tools vs
reading-tools vs ritual-method-tools." Melee never consumes bag space; counters do.

## TD-012 — Macro-structure: free, rank-gated contract board (no run-arc) (2026-06-28)

**Decision.** The meta-loop is a **free contract board**: pick any unlocked contract at
will, with **Collegium Rank** gating access to higher tiers. There is no roguelike
run-arc or forced finale. The *expedition* remains the roguelike unit (procedural,
high-stakes, failable); the meta is a persistent-rank hunter's board (Monster-Hunter-like
framing, diagnosis soul).

**Context.** Chosen over an escalating "pilgrimage" run and over standalone episodes. Keeps
pick-up-and-play co-op and matches "cooperative hunting RPG with roguelike *expedition*
structure" literally.

**Consequences.** A "session" is a play sitting; the session Archive (TD-006) accumulates
within it and resets next sitting. Persistent progression = Collegium Rank (gates tiers) +
player skill; ephemeral progression = the session Archive. No meta-run permadeath.

## TD-013 — Understanding pays off in three layers (2026-06-28)

**Decision.** A correct read cashes out simultaneously in **combat** (right counters bite,
wrong ones bounce), **method** (non-kill verbs like capture/banish require the correct
identification), and **survival** (reading the Tell lets the party avoid lethal moments).

**Context.** Pillar 3 forbids memorization but the payoff of a correct read was unspecified.
Layering all three keeps understanding valuable across the whole encounter, not just as a
damage-type puzzle.

**Consequences.** Each trait axis must have a concrete payoff hook (see TD-014 schema):
Aspect/Frailty -> combat, Rite-key -> method, Tell -> survival, Disposition -> tactics.

## TD-014 — Diagnosis depth scales with contract tier / Collegium rank (2026-06-28)

**Decision.** The number of active trait axes (and the presence of sign-masking mutations)
scales with the contract's tier, which Collegium Rank gates. Low tier = a few axes, quick
read; high tier = the full schema plus mutations, a forensic diagnosis.

**Context.** Set by the Creative Director. Resolves what Rank gates (harder *readings*, not
raw power) and gives the difficulty curve a knowledge-shaped vector consistent with Pillar 2.

**Consequences.** The trait schema must support a variable number of exposed axes per
expedition. Rank is the persisted account stat (TD-006) that unlocks deeper-reading contracts.

## TD-015 — Origin: the Incarnate genus (Belief / Sin / Relic) (2026-06-28)

**Decision.** Every Incarnate has an **Origin** (the in-fiction term), its genus: **Belief**
(corrupted mind/thought), **Sin** (corrupted will/deed), or **Relic** (corrupted matter, a
broken holy object). Origin is **asserted by the contract but falsifiable** at higher tiers
(the assertion can be wrong, and discovering the misclassification is a major reversal).
**Hybrid** Origins (e.g. Relic-Sin) appear at higher tiers, gated and balanced to stay
rewarding rather than punishing. A scholar's **Choir** grants a *soft, fair informational
edge* reading its own Origin's dialect, never raw power and never a gap that disadvantages
a solo player or an off-Choir party.

**The non-negotiable rule (this is the whole point).** **Origin is a property of the
Incarnate, never the script for the expedition.** It *colors* a hunt; it never *dictates*
the approach. What dictates how you must play (careful vs aggressive, kill vs capture)
comes from the orthogonal contract axes (Primary Verb, Clause, Secondary Objective, Site,
Condition), which are rolled separately. Example: "do not break the relic" is a *Clause*,
not a property of Relic-born; without that Clause a Relic-born hunt can be fought loud.

**Context.** Addresses the Director's repetition-fatigue concern ("ugh, another relic-born,
careful mode again"). The fear is real if Origin hard-codes the approach; it is resolved by
four things: genus-not-script, the falsifiable premise (you can never autopilot the Origin),
hybrids (the space is larger than three), and Origin being only one axis among roughly ten
that recombine. Origin maps to the three Choir schools (Belief->Meaning, Sin->Judgment,
Relic->Sanctity), so lore and mechanics are the same object.

**Consequences.** Origin seeds the sign *dialect*, the applicable rite/method space, site
affinities, and behavioral pull, but not the mandate. Each Origin carries a signature
verb-tension as a *design seed to be tuned*: Belief = attention/observation can feed it
(**flagged tuning risk**: must not kill the diagnosis loop; likely channel-specific or a
slow build with payoff, not "all reading is dangerous"); Sin = bound to a transgression,
resolvable by penance/absolution; Relic = its relic is heart and prize, a tension only when
a Clause requires it intact. The full trait schema lives in docs/systems/incarnates.md.

## TD-016 — Collegium identity stages, the creed, and the Name of God (2026-06-28)

**Decision.** The Collegium's members pass through three stages, which are the player's
identity and title arc: **Aspirant** (before joining), **Seeker** (after initiation, the
baseline player term, "because they seek truth, not certainty"), and **Witness** (earned
by surviving expeditions, "because now they have seen"). Players are Seekers; Witness is an
earned honorific that aligns with the higher Collegium Rank bands (TD-014). The Collegium's
**creed** is **"We seek truth, not certainty"** (this fills the previously open "order's
saying" slot). God is the one true God (TD-010), generally named **The Sovereign One**, with
forms of address that vary by the speaker's theology and encode the world's disagreement:
**The Silent Watcher** (God read as passive), **The Grand Architect** (emphasizing creation),
and others.

**Context.** Provided by the Creative Director. "Seek truth, not certainty" and "Witness /
they have seen" tie the player's identity directly to the spine (Observe; interpretation,
not memorization). The plurality of God's epithets is the theological disagreement made into
flavor, mapping onto the three Choir schools.

**Consequences.** "Aspirant", "Seeker", and "Witness" become canonical terms (to be added to
GLOSSARY). The epithet system never resolves whether God is silent (holds TD-010). Threading
into docs/GLOSSARY.md, docs/lore/collegium.md, and docs/lore/cosmology.md is pending.

## TD-017 — Pre-expedition economy: the Stipend and the Blessing rite (2026-06-28)

**Decision.** Two layers, both ephemeral (no account-level power; TD-006 holds).

- **Stipend.** A per-contract allowance from the Collegium (scaled by tier, objectives met,
  clauses honored), spent to requisition the loadout (tools, rites, probes) and to place the
  **Surety**. This is the deliberate, skill-based preparation (Pillar 1). Gear is valued by
  **utility and specialization** (the capability, method, or sign-channel it unlocks), never
  by raw power, so the Stipend is a preparation decision, not a power-shopping ladder (Pillar 2).
- **Blessing.** A pre-deploy rite: each **Seeker petitions** the Sovereign One and **receives**
  (a pure, unchosen draw, because the unpredictability of grace is the point) a divine attribute
  on a hallowed armament or on existing gear. It is **per-Seeker**, **ephemeral (one expedition)**,
  **typed and conditional** (its worth depends on the Incarnate you theorize, so it is a wildcard
  you read around, never a flat boost), **magnitude-capped below the swing of a correct read**
  (luck spices, never decides), and carries **no dead blessings** (every blessing fits *some*
  Incarnate; whether it fits *this* one is part of the read). **Built after the core diagnosis
  loop is proven**, not at launch.

**Context.** The Director wants the RNG to simulate genuine providence: grace received, then
discovered to fit or not, which makes expeditions feel alive and fits the theology. Per-Seeker
and pure-draw were chosen over party-level and choose-from-offered to maximize that feeling; the
magnitude cap and conditional typing keep it fair and not overpowered. The earlier anti-luck and
Pillar 2 concerns are mitigated by these guards rather than by removing the RNG.

**Consequences.** **Anti-pattern guard:** no persistent blessings, no flat-power blessings, and no
blessing whose magnitude exceeds the swing of a correct read. Per-Seeker variety is framed as
distributed capability (Pillar 4), not a power hierarchy. Build order: a deferred, post-core system.

## TD-019 — Switched active spec to Lobby & Room (2026-06-30)

**Decision.** The design bible phase is complete. First implementation spec is
`specs/lobby-room/` — the lobby/room system covering room creation, join, leader
and ready mechanics, stub-contract acceptance, reconnect, and the DEPLOYING
transition. This is Phase 3 scope.

**Context.** All 10 system docs were drafted and ratified (d2d3077). The next
step per the roadmap is Phase 3: expedition loop skeleton, starting with the
lobby/room infrastructure already validated by the Veins prototype.

**Consequences.** Implementation begins with shared types (`src/shared/src/lobby.ts`),
then server-only types, pure logic, handlers, and integration — in that order (T1→T22).
The real contract-generation system is Phase 4; the spec uses a `StubContract`
placeholder by design.

---

## TD-018 — Downed/revive model and expedition spatial vocabulary (2026-06-28)

**Decision.** **Revive:** per-player downed state; a teammate revives by spending **time and
exposure** (which raises field pressure), not a sacrificed relic (Linked Fates is retired). A
full-party down ends the expedition (still writes a Field Testament). Solo carries one
self-recovery rite. **Spatial vocabulary** (known topology, dynamic placement per expedition):
**Approach** (entry), **Sign-sources** (environmental evidence to read), the **Lair** (the
Incarnate's seat), **Probe-features** (interactables for active reading), **Caches** (resources),
and **Extraction**.

**Context.** Residuals from the gameplay loop. Revive needed a replacement for retired Linked
Fates; the node set gives expeditions a concrete spatial grammar for the contract/site generator.

**Consequences.** Revive cost is diegetic pressure, consistent with the no-doom-clock rule
(TD-004). The node vocabulary feeds the known-topology-dynamic-state exploration model and the
contract axes (Site).

## TD-020 — Collegium lobby as explorable space (deferred to Phase 6+) (2026-06-30)

**Decision.** The pre-expedition waiting state is conceptually set inside the Collegium
hall. An immersive, walkable version — contract board as a diegetic object you approach,
Archive shelf where Field Testaments are stored and consulted, rank-gated areas of the
hall unlocking with Collegium Rank — is on-theme and passes the 500-expedition test.
This is deferred to Phase 6+ (content scale-up). The Phase 3 lobby spec uses a minimal
UI placeholder that the Godot client renders during `RoomPhase = 'WAITING'`.

**Context.** Raised during Phase 3 lobby spec review. The immersive Collegium lobby
genuinely serves the spine: browsing the contract board is Observe; consulting the
Archive is Hypothesize; leaving for deployment feels like leaving a place, not clicking
a button. However, building it now means building against placeholder art that will be
replaced in Phase 6 or 8, and it has no bearing on the server-side room lifecycle logic
that Phase 3 is proving.

**Consequences.** The server wire protocol does not change when the immersive lobby is
built: the client-side Godot rendering of the `WAITING` phase is replaced, but
`LOBBY_UPDATED`, `ROOM_DEPLOYING`, and the rest of the message catalog stay identical.
The immersive Collegium lobby will be specced as a Godot-side spec at Phase 6+, referencing
the server protocol defined in `specs/lobby-room/design.md`.

## TD-022 — Phase 3 complete; switched active spec to Incarnate Trait Schema & Sign Language (2026-06-30)

**Decision.** Phase 3 is complete (T1–T38, 651 tests green). Phase 4 begins with the
Incarnate Trait Schema & Sign Language spec (`specs/incarnate-signs/`), covering the
hidden `TraitRoll` data model, the v1 sign lexicon (`SIGN_LEXICON`), and two pure
server functions: `deriveSigns` and `generateTraitRoll`. Tasks T39–T44.

**Context.** Phase 4 goal: "a real diagnosis can happen." Five deliverables: contract
axes, sign language, probing, loadout/bag economy, distributed perception. Sign language
is the root dependency — contracts embed a `TraitRoll`, probing returns a `Sign`,
distributed perception filters by `Channel`. Building it first keeps each subsequent
spec self-contained. The existing `Rng` from `src/server/src/rng/seeded.ts` (Mulberry32,
`createRng`/`hashSeed`) is reused as-is (I3). No handler wiring in this spec; that
arrives with the probing spec (Phase 4, spec 3).

**Consequences.** New shared types: `Channel`, `SignToken`, `Sign`, `Tier` (in
`src/shared/src/signs.ts`). New server-only module: `src/server/src/incarnate/` with
`types.ts`, `lexicon.ts`, `deriveSigns.ts`, `generateTraitRoll.ts`. `TraitRoll` is
structurally contained server-side; a compile-time check in T40's test enforces it
never appears in `@testament/shared`. Sign tokens are opaque slugs — not trait value
names — which enforces P12/R40 at the data level.

---

## TD-021 — Switched active spec to Field Phase skeleton (2026-06-30)

**Decision.** The lobby/room spec (T1–T22) is fully implemented and all 515 tests are
green. Active spec switches to `specs/field-phase/` covering the field phase skeleton,
extraction, stub Field Testament, and session Archive update. Tasks T23–T38.

**Context.** Phase 3 exit gate requires the full Observe → Hypothesize → Test → Record
loop to be walkable end-to-end, even with stub content. The lobby/room system delivers
the entry point (ROOM_DEPLOYING). The field-phase spec delivers the rest: DEPLOY →
FIELD_STARTED → EXTRACT → FIELD_TESTAMENT → ARCHIVE_UPDATED, then room destruction.

**Consequences.** `RoomPhase` is extended to `'WAITING' | 'DEPLOYING' | 'FIELD' | 'COMPLETE'`.
New shared types land in `src/shared/src/fieldPhase.ts` and `src/shared/src/fieldMessages.ts`.
New server logic lands under `src/server/src/rooms/`. The reconnect handler and message
router are extended (not replaced). The lobby-room spec and its tests are untouched.

## TD-023 — Phase 4 spec 2: Real Contract Generation (2026-06-30)

**Decision.** Replace the `StubContract` placeholder with a real `ContractRecord` that
embeds a server-side `TraitRoll` and expedition seed. `ContractIntel` (shared) is the
wire-safe view; `ContractRecord` (server-only) is the full record. `StubContract` and
`STUB_CONTRACT` are deleted.

**Context.** Spec 1 (T39–T44) delivered `TraitRoll` types and pure derivation functions.
Spec 2 wires them into the expedition lifecycle: `ACCEPT_CONTRACT` now generates a real
`ContractRecord` using `generateContract(rng, tier, id, seed)`. Entropy enters exactly
once via `randomUUID()` in the handler (I3); all downstream randomness (target name,
site name, primary verb, trait roll) flows deterministically through the seeded Rng.

**Consequences.** The wire protocol changes: `RoomDeployingPayload.contract` is now
`ContractIntel` (not `StubContract`), with `tier: Tier` (string union) instead of
`tier: number`. The `toSnapshot` path calls `toContractIntel` before building a
`LobbySnapshot`, enforcing the server containment invariant structurally. All 696 tests
green (93 shared + 603 server).

## TD-024 — Phase 4 spec 3: Ambient Sign Delivery (2026-06-30)

**Decision.** `FIELD_STARTED` and `FieldSnapshot` (reconnect) now carry a `signs: Sign[]`
array — ambient signs derived server-side from the expedition's `TraitRoll` at the
contract's `Tier` via `deriveSigns`.

**Context.** This is the first moment a client-facing message carries the diagnosis
information. Spec 1 built `deriveSigns`; spec 2 put a real `TraitRoll` in the room.
Spec 3 closes the loop by delivering the derived signs in `FIELD_STARTED` (initial entry)
and `FieldSnapshot` (reconnect path). All players currently receive all signs; per-player
channel filtering comes in spec 5 (Distributed Perception).

**Consequences.** `FieldStartedPayload.signs: Sign[]` and `FieldSnapshot.signs: Sign[]`
are required fields. The deploy handler and `buildFieldSnapshot` call `deriveSigns`.
No trait values cross the wire — `JSON.stringify(payload)` contains none of the axis
value literals (EMBER, FLAME, LUNGE, etc.). All 697 tests green (93 shared + 604 server).

## TD-025 — Phase 4 spec 4: PROBE handler; REACTION channel becomes probe-gated (2026-07-02)

**Decision.** The `PROBE` client intent is implemented (specs/probe-handler, T54–T61):
a Seeker applies a `Stimulus` (`FLAME | COLD | SALT | LIGHT`), the server derives the
reaction sign from the hidden Ward trait via pure `deriveReaction`, broadcasts a
`PROBE_RESULT` delta to the room, and charges exposure. As part of this spec the
REACTION channel is removed from ambient sign delivery: `handleDeploy` and
`buildFieldSnapshot` now use `deriveAmbientSigns` (`ACTIVE_AXES` minus `WARD`), so the
Ward can only be learned by probing.

**Context.** Spec 3 (TD-024) shipped all active-axis signs ambiently, which included
the Ward's `drinks-*` REACTION sign at Journeyman+ — that would have made probing
redundant. docs/systems/investigation-and-probing.md is explicit that the Reaction
channel is probe-driven ("you often cannot learn what an Incarnate shrugs off until
you test it"), and probing must cost something so it is a decision, not a scan
(Pillar 1, TD-004).

**Consequences.** New shared wire types: `Stimulus`/`STIMULI` (signs.ts),
`ProbePayload`, `ProbeResultPayload` (fieldMessages.ts). `RoomRecord` gains
server-only `exposure` (reset on DEPLOY, +1 per probe) and `revealedSigns` (deduped
by token; appended to `FieldSnapshot.signs` so probe results survive reconnect). A
non-matching probe returns the fixed `no-reaction` sign — deliberately identical to
a ward-less Incarnate, so a null result stays ambiguous evidence. `exposure` rides
`PROBE_RESULT` as a number: it measures party noise, not Incarnate knowledge, so it
does not violate vision.md non-negotiable 2. `deriveSigns` itself is unchanged as the
lexicon-completeness reference. All players still receive all signs; per-player
channel filtering remains spec 5 (Distributed Perception). All 734 tests green
(96 shared + 638 server).

---

> *Merge note (2026-07-02): the entry below was written on a parallel branch and
> reuses the TD-019 identifier (a different TD-019, dated 2026-06-30, appears
> above). Both are preserved verbatim; this log is append-only.*

## TD-019 — Server stripped to a clean skeleton; prototype removed from the workspace (2026-06-29)

**Decision.** Remove all retired prototype game code and references from the active
workspace. Deleted the prototype game rules (board/synergy, bleed clock, doctrine,
loot, relic effects) and the ranged-combat loop (weapon, enemy AI, spawn, auto-aim,
tick, separation) from the server, plus the matching shared types. Deleted the
`docs/archive/` and `specs/archive/` trees and the completed migration-plan doc.

**Context.** The conservative "keep the combat substrate" cut proved impractical:
foundational types (`PlayerId`) and the bleed clock lived inside prototype files, and
the combat loop was fused with relic/synergy/doctrine. The clean cut keeps the
genuinely reusable, transport-agnostic libraries plus the lobby/room lifecycle and
removes the rest (which Testament rebuilds as melee combat and the expedition loop).

**Consequences.** Kept: seeded RNG, BSP dungeon generation, collision, pathfinding,
player movement, and the room / lobby / reconnection lifecycle, behind the
`SocketIOServerLike` seam. The server is now a lobby + rooms + player-movement
skeleton; both packages type-check clean and tests pass. `PlayerId` moved to
`shared/ids.ts`, movement constants to `shared/player.ts`. Zero prototype-name
references remain in `src/`; the only ones left are the historical entries in this
append-only log (TD-001..002), which document the reboot itself. Git history
preserves everything removed.

## TD-026 — Phase 4 spec 5: Distributed Perception (2026-07-02)

**Decision.** Perception is now per-player (specs/distributed-perception, T62–T67):
at DEPLOY the server assigns each Seeker a perception set (`ServerPlayerEntry.
perceivedChannels`) and every sign delivery is filtered to it — `FIELD_STARTED`
ambient signs, `PROBE_RESULT` reactions, and the reconnect `FieldSnapshot`. Each
player also learns their own set (`perceivedChannels` on those payloads), never
other players' sets. `ProbeResultPayload.sign` is now `Sign | null`: everyone sees
who probed, with what, and the exposure cost, but only REACTION perceivers read
the response — including the prober, who may have rung the bell blind.

**Context.** Pillar 4 requires cooperation to be structural: evidence is
distributed, so the theory can only be assembled by talking
(docs/systems/distributed-perception.md). The design doc ties assignment to the
loadout, which is a later spec, so this spec ships an interim deterministic
assignment: channels relevant to the contract tier (ambient channels + REACTION)
are shuffled with a seeded rng (`hashSeed(expeditionSeed + ':perception')` — a
domain-suffixed sub-seed, I3), dealt round-robin, then topped up so every Seeker
reads at least 2 channels. Solo perceives everything (TD-008: never lacking).

**Consequences.** Filtering is information security, not UI hiding: a client never
receives what its player cannot perceive (I5). The union of the party's sets always
covers the tier's channels, so a full read stays assemblable. Assignment is keyed
to playerId and survives reconnection; a non-REACTION perceiver does not recover
revealed reaction signs on resync. When the loadout economy lands it replaces the
assignment source only — the filtering machinery stays. All 347 tests green
(44 shared + 303 server); both packages typecheck clean.

## TD-027 — Phase 4 spec 6: Loadout & Bag Economy v1, with a minimal gear catalog (2026-07-02)

**Decision.** The bag is implemented (specs/loadout-economy, T68–T74) with a v1
catalog shipped inside the spec, following the SIGN_LEXICON precedent: 6 perception
gear items (one per channel: Ashen Lens, Chirurgeon's Glass, Witness Prism,
Tracker's Fetish, Cantor's Ear, Augur's Bead) and 4 reusable probe kits (one per
stimulus: Censer of Embers, Phial of Hoarfrost, Consecrated Salt, Lantern of the
Creed). `BAG_SLOTS = 4`. A `REQUISITION` intent (DEPLOYING phase only,
replace-not-merge) packs the sender's own bag; bags are party-visible via
`LobbyPlayer.bag` in every snapshot. Perception is now gear-derived for parties
(`perceivedChannelsFor`); spec 5's interim seeded `assignPerception` is deleted as
planned (TD-026). Probing now requires the matching kit (`MISSING_GEAR` otherwise).

**Context.** TD-007: distributing the bags and distributing perception must be the
same decision. The catalog lives in `@testament/shared` (unlike SIGN_LEXICON, which
maps hidden trait values and stays server-only) because it is public requisition
data the Godot client renders; it carries channels and stimuli only, never axis
values. Solo perceives all tier channels regardless of gear (TD-008: solo is
balanced by tempo and bag pressure, never by withholding information) but still
needs kits to probe.

**Consequences.** Union coverage of the party's channels is no longer a server
guarantee — a party that packs badly is blind on a channel, which is the design
(preparation is a bet, falsifiable like the intel it is placed on). Deferred
deliberately: Stipend pricing and the Surety (economy spec), rites and combat tools
(nothing consumes them yet), consumable probes and cache resupply (sites), and the
Blessing. New error codes: UNKNOWN_ITEM, BAG_OVERFLOW, MISSING_GEAR. With this,
all five Phase 4 deliverables (contract axes v1, sign language, probing, loadout,
distributed perception) exist server-side; the exit gate ("a party reads an
Incarnate from signs and probes and forms a theory") is walkable over the wire.
All 372 tests green (50 shared + 322 server); both packages typecheck clean.

## TD-028 — Godot client catch-up: one protocol, production-wired, playable exit gate (2026-07-03)

**Decision.** The transport spike is retired and both ends now speak only the
Testament protocol (specs/godot-client-catchup, T75–T82). Server: a new
`bootstrap.ts` (`attachTestamentServer`) wires `routeMessage` +
`handleSocketDisconnect` over raw WebSocket in production — previously the
router was only ever reachable from tests while `index.ts` still booted the
spike. The bootstrap owns nothing but a socketId→socket map; broadcast
membership derives from RoomManager player entries. The spike's parallel room
system (`src/server/src/room/`) and its transport hub (`src/server/src/transport/`)
are deleted; `combat/` and `dungeon/` stay as dormant pure modules for Phase 5,
`rng/` stays live. Client: `main.gd` is rewritten from the dungeon-render spike
into the full Phase 4 walk (menu → lobby → contract/requisition → field with
probes → Field Testament), with `net.gd` (envelope transport) and `catalog.gd`
(a hand-kept protocol mirror of GEAR_CATALOG/BAG_SLOTS/STIMULI from
@testament/shared, since GDScript cannot import TypeScript).

**Context.** Two wire additions were needed for client self-identification,
both server-generated identity already public in snapshots, never trait data:
`RECONNECT_TOKEN` and `STATE_RESYNC` now carry `playerId`
(`ReconnectTokenPayload` added to shared; `StateResyncPayload` extended). A
joiner only ever saw a broadcast snapshot and could not tell which entry was
itself; a relaunched client holds only its persisted reconnect token (the one
thing the client is allowed to remember — an opaque secret, not game state)
and must relearn its identity from the resync.

**Consequences.** The Phase 4 exit gate is now playable, pending the manual
two-instance playtest (checklist in client/README.md — GDScript has no test
harness here, so client rendering is verified manually while the protocol
itself is verified by `bootstrap.integration.test.ts` walking the production
wiring end to end, including two-room broadcast isolation). Movement and
dungeon rendering left the client with the spike and return in Phase 5 through
the Testament field phase. `catalog.gd` drifts silently if shared constants
change — acceptable at one mirror; codegen becomes worth it at the second
consumer. Spike-era shared types (RoomSummary, MovePlayerRequest, dungeon wire
types) remain in shared untouched; pruning them is Phase 5 housekeeping.
All 352 tests green (51 shared + 301 server); both packages typecheck clean.

## TD-029 — Wire protocol becomes one language-neutral source of truth: registry + codegen (2026-06-29, imported 2026-07-03)

> Imported from branch `feat/protocol-contract` (D: clone), where it was numbered
> TD-020; renumbered on import because this log already assigned TD-020/021 to
> other decisions. Original text below, unedited. Its "active spec" swap and
> phase framing describe that branch's timeline, not this log's.

**Decision.** Close out the raw-ws-transport spec (Phase 1, server and client both
green) and open `specs/protocol-contract/` as the active spec. CLAUDE.md's
Active-Work block now points at the protocol-contract spec. Phase 2 makes the wire
protocol one language-neutral source of truth: a canonical message-name registry
plus shared enums in `src/shared`, and a `tools/` codegen that emits a GDScript
constants file the Godot client consumes. It commits no gameplay (gameplay is gated
to Phase 3).

**Context.** Phase 1 left the message-type strings ("create-room", "ROOM_UPDATE",
and the rest) as scattered literals in both `src/server/src/index.ts` and
`client/main.gd`. Two hand-maintained copies of the same vocabulary will drift. The
roadmap's Phase 2 exit gate requires server and client to reference the same names
from one source.

**Consequences.** The registry and the codegen-able enums are authored as runtime
values (const objects and const string arrays) with the TypeScript types derived
from them, because TS union types are erased at runtime and a codegen cannot
introspect them otherwise. This keeps `src/shared` types-and-constants-only
(invariant I4): const data, no logic. The codegen output is deterministic and
checked into git, so a drift between the registry and the generated GDScript fails a
test. The transport lifecycle events `connection` and `disconnect` are explicitly
not wire messages and stay out of the registry.

## TD-030 — Generated GDScript protocol is preload-consumed, not a global class_name (2026-06-29, imported 2026-07-03)

> Imported from branch `feat/protocol-contract`, originally TD-021 there.

**Decision.** The codegen emits `client/protocol/protocol.gd` as a plain constants
script with no `class_name`, and the client consumes it with
`const Protocol = preload("res://protocol/protocol.gd")`. This amends the
protocol-contract spec's R4 acceptance criterion, which originally specified
`class_name Protocol`.

**Context.** A Godot `class_name` global is only registered after the editor scans
and reimports the project. Because `protocol.gd` is generated outside the editor, a
headless run (the Godot MCP launching the game) and a fresh `git clone` before the
editor is opened both fail to resolve `Protocol`, with `Parser Error: Identifier
"Protocol" not declared in the current scope`. The stale global-class cache also
collided with a local `const Protocol`.

**Consequences.** `preload` resolves at compile time straight from the res:// path,
so the file works in a headless run, in the editor, and in an export with no
dependency on the global-class cache state. This let the Phase-1 round-trip be
verified through the MCP (Godot 4.7) rather than only by hand: the client compiles
and runs with no errors, and an instrumented run observed
`RUN_STARTED rooms=12 seekers=1`. The change is value-preserving (each generated
constant equals the literal it replaced), so the wire behaviour is unchanged. The
`.godot/` cache stays gitignored and regenerates per checkout.

## TD-031 — feat/protocol-contract reconciled: the registry now covers the Testament protocol (2026-07-03)

**Decision.** The protocol-contract branch (TD-029/TD-030, authored 2026-06-29 on
the D: clone against the Phase 1 spike) is merged and re-targeted at the live
protocol (specs/protocol-contract reconciliation addendum, T84–T87). The registry
in `src/shared/src/messages.ts` now names the ten client intents and ten server
events of Phases 3–4, with payload maps referencing the existing wire types.
`LobbyErrorCode` and `RoomPhase` are derived from runtime arrays declared beside
them. The codegen emits the full contract — messages, error codes, phases,
channels, stimuli, scalars, and GEAR_CATALOG — into `client/protocol/protocol.gd`;
`client/catalog.gd` keeps only display helpers over that generated data. The
server's router and every handler reference the registry constants, enforced by a
position-aware guard (`rooms/wireLiterals.test.ts`) instead of the old
index.ts-only scan.

**Context.** TD-028 shipped `catalog.gd` as a hand-kept mirror and noted "codegen
becomes worth it at the second consumer" — the codegen already existed, unmerged
on the Windows clone. Two decision logs had diverged after TD-019 with colliding
TD-020/021 numbers; the imported entries were appended renumbered (TD-029/TD-030)
with provenance notes rather than editing either history (the log stays
append-only). The port is value-preserving: every registry constant equals the
literal it replaced, so the wire behaviour and all existing tests are unchanged.

**Consequences.** Client/server drift in message names, error codes, phases, or
the gear catalog now fails a test (byte-equality reproducibility gate + the wire-
literal guard) instead of failing a playtest. Adding a wire message means: add it
to the registry, `pnpm gen:protocol`, commit both — anything less breaks the
suite. The spike-era shared types (events.ts, RoomSummary, dungeon wire types)
remain and are still Phase 5 pruning work; the registry simply does not name
them. All 372 tests green (60 shared + 7 tools + 305 server); three packages
typecheck clean; headless Godot 4.7 runs the ported client with zero errors.

## TD-032 — Lobby resilience: visible ghosts, ghost-proof readiness, leader kick (2026-07-04)

**Decision.** Three fixes from the 2026-07-03 disconnect playtest
(specs/lobby-resilience, T88–T94). (1) `LobbyPlayer.connected` crosses the wire
in every snapshot, derived in `toPublicPlayer` from `disconnectedAt` — derived,
never stored twice. (2) `allReady` counts connected players only: a ghost's
seat is held for reconnection, not for veto, so a not-ready disconnect can no
longer deadlock ACCEPT_CONTRACT. (3) New leader-only `KICK_PLAYER` intent frees
a seat held by a disconnected player in WAITING/DEPLOYING; new error code
`CANNOT_KICK` deliberately covers both "no such player" and "player is
connected" so the response reveals neither. Kicking is illegal in FIELD —
mid-expedition seats stay sacred — and can never remove a connected player (no
griefing lever). A kicked player's resume fails (`ROOM_NOT_FOUND`) and the
client forgets its token on any failed resume. Client also renders the
`(disconnected)` marker, gives the leader a Kick button, and moves screen
content into a ScrollContainer with the status line pinned (the playtest's
clipped-window complaint).

**Context.** The playtest (two windows plus a scripted bot Seeker) showed a
lobby ghost was invisible to teammates, blocked acceptance forever if
not-ready, and held one of four seats with no recourse (`ROOM_FULL` for a
would-be replacement). The registry+codegen pipeline (TD-031) carried the
whole change: KICK_PLAYER and CANNOT_KICK were added once in shared and
regenerated into protocol.gd.

**Consequences.** A party can now always proceed or recover from a lobby
disconnect; the reconnect contract is unweakened (a ghost that returns before
being kicked resumes with ready state and bag intact). Deferred deliberately:
auto-removal timeouts (adds server timers for a problem the kick already
solves) and kicking connected players (a social feature with griefing
implications, not a resilience fix). All 386 tests green (60 shared + 7 tools
+ 319 server); typecheck clean; headless Godot 4.7 check + run clean.
