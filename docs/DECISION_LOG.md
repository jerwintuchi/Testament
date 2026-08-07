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

## TD-033 — 2D top-down pixel art reaffirmed; Blender 3D and MediBang directions deprecated (2026-07-05)

**Decision.** Testament's client art is 2D top-down pixel art, full commitment:
16x16 tiles, 480x270 internal resolution integer-scaled, Nearest filtering,
Seeker 16x24 logical / 48x48 canvas / feet anchor (24,44), part-lag animation
rig, per-frame weapon sockets, grayscale ADD-blend VFX, palette-locked Aseprite
sources. The sanctioned toolchain is a closed list — Godot 4.7 (engine + UI),
Aseprite (hand-authored sources), Python/PIL generators (programmatic sheets) —
now recorded in CLAUDE.md; adding any tool beyond it requires explicit user
approval. The Blender 3D-to-sprite direction and the MediBang HD-raster
direction are dead.

**Context.** A Blender render-to-sprite pipeline was spiked in June 2026
(headless Blender 5.1.2 via blender-mcp, a 4-direction 48px Seeker prototype).
The spike's outputs lived in Windows temp and the MCP environment only —
audited 2026-07-05, this repo contains zero 3D assets (`.blend`/`.fbx`/
`.gltf`/`.obj`), zero MediBang/HD raster sources (`.mdp`/`.psd`), no addons,
and its single scene (`client/main.tscn`) is a bare Node2D — so the purge is a
ruling, not a deletion. `docs/technical.md` already stated "top-down 2D pixel
art"; this entry makes the toolchain boundary explicit.

**Consequences.** No 3D or painterly asset may enter the repo; sprite sources
are Aseprite files under `art/src/` or `gen_*.py` generator output. The
blender-mcp tooling is no longer part of Testament's pipeline. Project
settings work (480x270 integer scaling, Nearest default filtering) lands with
the first sprite assets — the current `project.godot` (960x540, code-built UI,
no textures yet) predates the art phase and has nothing to misfilter.

## TD-034 — Spike-era dungeon/movement chain pruned from shared and server (2026-07-05)

**Decision.** The transport-spike's world-geometry code is deleted:
`src/shared/src/{dungeon,player,events}.ts` (plus `dungeon.test.ts`),
`src/server/src/dungeon/` (BSP generation, collision, A* pathfinding, 3 test
files), and `src/server/src/combat/movement.ts` (plus test). The corresponding
`export *` lines are removed from the shared index. This is the "prune
spike-era shared types" housekeeping named as Phase 5's lead-in.

**Context.** The chain dated to the raw-WS transport spike ("connect, render
dungeon, move a Seeker") and survived the Godot client catch-up (TD-028) as
dead code: nothing outside the chain imported it — no live server handler, no
protocol registry name, no GDScript client reference. Its spike wire types
(`RunStartedEvent`, `MovePlayerRequest`, `PlayerMovedEvent`,
`StateResyncEvent`) were superseded by the Testament protocol's
`lobbyMessages`/`fieldMessages`; the live `STATE_RESYNC` payload comes from
`lobbyMessages` and is unaffected. Its geometry model (free world-unit rects,
40-unit corridors, `PLAYER_RADIUS` circles) also contradicts the canonical
2D grid (TD-033: 16x16 tiles, 480x270, TileMap autotiles), so Phase 5's field
space is a fresh design, not a revival — git history keeps the spike code if
reference is ever wanted.

**Consequences.** The repo now has no movement, position, or site-geometry
code at all: the field phase is the abstract probe/sign loop. Phase 5 must
build field space v1 (seeded tile-based site generation, positions, movement
intents, collision) on the tile grid before combat can exist. Test counts
drop from 386 to 337 (56 shared + 7 tools + 274 server), all green; tsc
build clean.

## TD-035 — Phase 5 opens; active spec is Field Space v1 (2026-07-05)

**Decision.** Phase 4 is closed and Phase 5 (Combat & Incarnate v1) begins. The
active spec switches from `specs/lobby-resilience/` to `specs/field-space/`
(R81–R91, T95–T103): the spatial substrate combat needs — a seeded tile-based
site on the canonical 16×16 grid (TD-033), player positions, an authoritative
20Hz movement tick with feet-AABB collision, the TD-018 node vocabulary
(Approach / Sign-source / Lair / Extraction), and position-gated extraction.

**Context.** Combat (`docs/systems/combat.md`) is "downstream of the read" and
needs a space to happen in, but after the TD-034 prune the repo has no
movement, position, or geometry code at all — the field phase is currently the
abstract probe/sign loop. Rather than revive the spike's free-world-unit model
(deleted, and contradicting the canonical grid), Phase 5 rebuilds field space
fresh on tiles. Field Space is specced before the melee/Omen/verb systems
because every one of them presupposes positions and collision. The encounter
cadence that combat must serve is fixed in `docs/systems/encounter-flow.md`
(now in-repo): investigation never stops, combat is the highest-risk probe.

**Consequences.** New shared module `src/shared/src/site.ts` (grid/node types +
tile/speed/tick constants); `MovePayload`/`PositionsPayload` join
`fieldMessages.ts`; `MOVE`/`POSITIONS` join the protocol registry and codegen.
New server modules `src/server/src/site/` (pure `generateSite`, `stepPlayer`)
and `src/server/src/rooms/fieldTick.ts`. `RoomRecord` gains `site`/`fieldTick`;
`ServerPlayerEntry` gains `pos`/`moveIntent`. `FIELD_STARTED`, `FieldSnapshot`,
and the reconnect path carry `site` + `positions`; `EXTRACT` becomes
position-gated (`NOT_AT_EXTRACTION`). Trait containment holds — none of the new
payloads carry axis values. The next playtest is blocked on the follow-up Godot
client spec (render the site, send `MOVE`), since extraction now requires
standing on the Extraction node.

## TD-036 — Field Space v1 shipped; active spec is Collegium (Staging Site) v1 (2026-07-05)

**Decision.** Field Space v1 is complete (T95–T103, committed): seeded tile
site, authoritative 20Hz movement with feet-AABB collision, position-gated
extraction. The active spec switches from `specs/field-space/` to
`specs/collegium/` (R92–R101, T104–T114): the party's **preparation map** — a
fixed, walkable Collegium the party occupies during the lobby phases
(WAITING + DEPLOYING), with prep actions gated to **spatial stations** (accept
at the Contract Board, requisition at the Quartermaster, deploy at the Deploy
Gate), mirroring field extraction's `NOT_AT_EXTRACTION` gate.

**Context.** The user asked to make the Collegium a walkable staging site rather
than a UI-only lobby: "join a room in the Collegium → walk to the board → accept
→ walk to the gate → deploy." Chosen scope is **spatial stations** (gate the
existing, working prep handlers behind station radii) — the walkable-space
substrate plus spatial *access*. **Full spatial prep** (new interaction verbs,
per-station UIs, the Archive as a physical room) is explicitly deferred to a
later spec; it needs each station to earn its spine cost (Observe / Hypothesize
/ Test / Record), which is design work not to be rushed. The Collegium is
**fixed/authored, not seeded** — a home base should be stable and recognizable,
unlike the per-expedition site.

**Consequences.** New shared module `src/shared/src/collegium.ts` (station
vocabulary + `CollegiumLayout`, reusing the field-space `SiteGrid` and
`SEEKER_*` constants); `LobbySnapshot` gains `collegium` + `positions`;
`LOBBY_ERROR_CODES` gains the three station codes (codegen refreshed). No new
message *names* — stations reuse `ACCEPT_CONTRACT`/`REQUISITION`/`DEPLOY`,
movement reuses `MOVE`/`POSITIONS`. New server content
`src/server/src/collegium/collegium.ts` (the one authored `COLLEGIUM` layout).

This **evolves the field-space tick (R87/R91)**: `fieldTick.ts` becomes
`rooms/movementTick.ts`, one integrator per room that runs across
WAITING/DEPLOYING/FIELD and collides against `activeGrid(room)` (the Collegium
grid in the lobby, `room.site.grid` in the field). It now **starts at room
creation** (not on DEPLOY) and stops on `destroyRoom`; the WAITING→FIELD
boundary swaps the grid under a running timer rather than restarting it.
`room.fieldTick` → `room.moveTick`; `MOVE` becomes legal in any walkable phase
(COMPLETE still `WRONG_PHASE`). Field-space's `spawnPoints` is generalized to a
shared `spawnFanOut(grid, anchor, count)` reused by Collegium and field spawns;
`handleExtract`'s radius check is extracted to a `withinRadius` util reused by
the station gates. Trait containment holds — the lobby snapshot carries no
axis literals. The next playtest remains blocked on the follow-up Godot client
spec (now: render the Collegium + the field, send `MOVE`, walk to stations).

## TD-037 — Collegium (Staging Site) v1 shipped; active spec is Collegium Client (Walkable Spaces) v1 (2026-07-05)

**Decision.** The Collegium server+shared spec is complete (T104–T114, committed,
full suite green): the fixed walkable `COLLEGIUM`, one `moveTick` spanning
WAITING/DEPLOYING/FIELD, spatial prep stations (`NOT_AT_CONTRACT_BOARD` /
`NOT_AT_QUARTERMASTER` / `NOT_AT_DEPLOY_GATE`), and `LobbySnapshot.collegium` +
`.positions`. The active spec switches from `specs/collegium/` to
`specs/collegium-client/` (R102–R108, T115–T121): the follow-up Godot client that
renders the walkable spaces and sends `MOVE`.

**Context.** A manual playtest confirmed the gap TD-036 predicted: the Phase 4
text/UI client has no way to send `MOVE`, so the leader spawns in the atrium 96 px
from the Contract Board and `ACCEPT_CONTRACT` returns `NOT_AT_CONTRACT_BOARD` —
the lobby is un-progressable. Tracing further, the **field is broken the same
way**: field-space (TD-035/036) made `EXTRACT` position-gated
(`NOT_AT_EXTRACTION`) and the text field screen can't walk to the Extraction node
either, so field-space's own playtest was already blocked on this same client
work. The user chose the **full-loop scope**: one reusable renderer covering both
spaces, not the Collegium alone.

**Consequences.** Client-only spec (render + input; no server/shared change — the
wire is already complete: `MOVE`, `POSITIONS`, snapshot `collegium`/`positions`,
`FIELD_STARTED.site`/`positions`, `STATE_RESYNC.fieldSnapshot`, `NOT_AT_*`, all
codegen'd into `protocol.gd`). One `SpaceView` (`class_name`, render-only) draws
any `SiteGrid` + tile-coord markers — it serves both `CollegiumLayout.stations`
and `SiteLayout.nodes` because they share the shape `{ grid, <markers> }`. `main.gd`
gains a world layer beneath its UI, a phase router feeding `SpaceView` the right
layout, an input loop emitting `MOVE { dx, dy }` on intent *edges* only (raw
{-1,0,1}; the server normalizes the diagonal), and proximity affordances that
mirror the server gates (Accept/Requisition/Deploy at the stations, Extract at the
Extraction node). Trust boundary held on the client side: a body's position is
only ever set from a server message (`_apply_positions`), never from input —
proximity is a display affordance, never an authorization (P54/P56). No GDScript
unit harness exists, so verification is the MCP-driven `specs/collegium-client/
playtest.md` (10 numbered items; the client logs load-bearing events for
`get_debug_output`). v1 art is a deliberate functional greybox (Godot-drawn
tiles/glyphs/bodies) — no new tool or asset, closed-list-safe; authored pixel
tilesets and the strict 480×270 SubViewport pipeline are a later art task.

**Tooling note.** The Godot MCP is now registered (local scope) so this client
work can be driven and observed directly: Windows node + Windows paths, with
`WSLENV=GODOT_PATH` whitelisting the exe path across the WSL→Win32 boundary
(verified: `get_godot_version` → 4.7.stable). Runs the Windows clone
`D:\Projects\Testament\client`, which must be reconciled with the WSL repo before
client edits land.

## TD-038 — Collegium Client walkable + themed popups landed; active spec is Station UI v2 (2026-07-06)

**Decision.** The Collegium Client (Walkable Spaces) work is functionally in place
and the active spec switches from `specs/collegium-client/` to `specs/station-ui/`
(R109–R117, T122–T130): the three station popups (Contract Board, Quartermaster,
Deploy Gate) grow into the full **preparation loop** the user mocked up, in the
gothic parchment-and-gold aesthetic. User chose the "write a full spec first" path
over an ad-hoc client-only visual pass.

**Context.** `specs/collegium-client/` T115–T120 are implemented (SpaceView,
Player puppet, input→MOVE, phase router, proximity affordances) and were driven
live via the Godot MCP against `pnpm dev:server`. A playtest surfaced three
follow-ups, all fixed client-side within the trust boundary: (a) bodies were only
spawned from the `POSITIONS` delta, so the local Seeker was invisible until first
movement — added the missing initial body-sync from the lobby snapshot in
`_show_lobby`/`_show_deploying`; (b) a Shift-to-walk register — since speed is
server-authoritative (I1), `walk` became an optional `MovePayload` field the
server validates and applies (`SEEKER_SPEED` run / new `WALK_SPEED` walk in
`stepPlayer`), the client sends it on intent edges, and the animation picks
walk/run/idle from server-derived motion speed (not local input, so teammates
animate correctly); (c) label blur → crispness via `default_font_antialiasing=0`,
then a readability regression (hinting off dropped thin strokes) fixed with
`default_font_hinting=2`. A themed **9-slice popup** was added: a procedural
gothic panel (`client/assets/ui/gen_panel.py` → `panel.png`, pure-stdlib PNG since
PIL is absent) wired through a `Theme` on the popup `PanelContainer`
(`_build_popup_theme`), with a `StyleBoxFlat` fallback. Server suite stayed green
(343 tests, incl. new walk-speed and walk-intent cases). **T121 (the full
collegium-client MCP playtest) is not yet run — that spec is left code-complete
but not marked done; its flows will be re-exercised by the Station UI playtest.**

**Consequences.** Station UI v2 is a genuine cross-layer feature, grounded in
existing canon so it invents no mechanics: the browsable multi-contract **board**
is `docs/systems/contracts.md` ("the board is free, the rank is the gate", TD-012);
the **Stipend**-priced Quartermaster is `docs/systems/loadout-economy.md` (priced
by utility, not power, TD-017); the Deploy Gate shows each Seeker's **bag**, not a
class/role, per the Hunter-Scholar rule (roles emerge from the loadout). Trait
containment holds throughout — the board ships `ContractIntel[]` via the existing
`toContractIntel`, never the hidden roll (I3/I5), and **no Incarnate art appears on
the board** (mystery is the mechanic, vision.md pillar 3). Server/shared grow a
`board`, a `stipend`, a `SELECT_CONTRACT` message, and priced/descriptive gear;
the client rebuilds the popups as render-only themed scenes emitting the existing
intents. v1 gear icons stay greybox glyphs (authored Aseprite icons + the Stipend
reward-scaling and rank-gated tiers are later tasks). Verified by colocated Vitest
(server/shared) plus the MCP-driven `specs/station-ui/playtest.md` (client).

## TD-039 — Contract Board reframed as a commission wall: asserted Origin on the wire + procedural charge prose (2026-07-07)

**Context.** While polishing the T124 Contract Board, the board read as a generic
bounty list. Two changes make it read as the Collegium's commission wall without
touching a mechanic. Both are additive to the Station UI v2 spec (Phase A), not a
new direction.

**Decision 1 — asserted `Origin` becomes wire intel.** `ContractIntel` gains
`origin: Origin` (`'BELIEF' | 'SIN' | 'RELIC'`) in `src/shared/src/contract.ts`;
`generateContract` picks it from the seeded RNG (a `rng.pick`, independent of the
trait roll). This is the genus the contract **asserts** — a claim the GLOSSARY
already defines as *"falsifiable, possibly hybrid,"* not the hidden roll — so it is
trait-safe by construction (I3/I5): it is not a trait-roll axis (Aspect/Frailty/
Ward/Disposition/Rite-key/Tell), and `toContractIntel` still strips only seed+roll.
The client renders it as an **Origin-keyed wax seal** (colour + pressed sigil per
genus: Belief indigo/eye, Sin crimson/cross, Relic gold/diamond), reusable via
`client/scripts/ui/wax_seal.gd` (preloaded, not a global `class_name`, per TD-029/
30). The seal turns "read the board at a glance" into real, teachable vocabulary
that never spoils the roll (vision.md pillar 3). Trait-containment tests updated:
`toContractIntel` now returns 6 keys incl. `origin`; a new membership test asserts
origin ∈ the 3 literals.

**Decision 2 — procedural charge prose.** The fixed per-verb flavor sentences
(`VERB_FLAVOR`) are replaced by a client-side grammar: a verb **synonym** + a
**locale** frame + a reinforcing **qualifier**, assembled deterministically from
the `contractId` (salted hashes, so slots vary independently but a contract always
reads the same). Every synonym of a verb still carries that verb's meaning and the
qualifier restates it, so the server's `primaryVerb` hint survives the rephrase.
This is presentation only — the server's verb is the authority; the client invents
no game state (I1). Card text was also centred and pulled inside the parchment's
torn edges so no glyph rides the tear.

**Incidental fix.** `UNKNOWN_CONTRACT` (added to `LOBBY_ERROR_CODES` in T123) was
missing from the exhaustive-switch test in `lobbyMessages.test.ts`, so `tsc`
(the build) failed while vitest/tsx stayed green — a latent break. Added the case
and bumped the count to nineteen; `pnpm build` is green again.

**Consequences.** Server + shared + client all touched; full suite green (server
356, shared 65) and `pnpm build` clean. The board now teaches Origin vocabulary
via the seal and reads as scribed intent via the procedural brief, both trait-free.
Authored per-Origin intel prose and Aseprite seal art remain later enhancements;
the `origin` field is now available to the Deploy Gate summary (Phase C) for free.

## TD-040 — Notice Board arrangement: dense organic scatter, dramatic sizes, carved placard (2026-07-08)

**Context.** The notice-board client render (specs/notice-board, R122/T134) laid
the 4 live contracts in a tidy upper row and flavor notices in a row below, with a
strict "no live notice's text is clipped or overlapped" rule and a plain text
title. A reference image (a tavern **Notice Board** — papers of varied size pinned
at angles, overlapping, filling the whole board, under a carved hanging sign) set
the target feel. In a `gds-ux`-facilitated pass the stakeholder chose, per option:
dense organic scatter (overlap permitted), dramatic size variety, a carved hanging
placard, and keep the take-down-to-read flow.

**Decision.** `_build_contract_board` becomes a full-board seeded scatter:
- **Arrangement** — quadrant anchor slots spread across the whole board (not a row)
  plus `_seed_jitter`/`_seed_tilt` (deterministic per `contractId`), so papers fill
  the board at human angles. Notices **may overlap** at corners. Live notices draw
  **above** flavor and are clamped inside the wooden frame; a hovered live notice
  raises to front (`move_to_front`). Flavor stays `MOUSE_FILTER_IGNORE` so overlap
  never steals a live click (P65 intact).
- **Size** — live sizes span small notes → big posters, seeded from `contractId`.
  Explicitly **aesthetic, never tier-encoding** — contracts stay equal-weight, the
  mystery is the mechanic (vision.md pillar 3).
- **Header** — a carved `_notice_placard` ("PETITIONS BEFORE THE COLLEGIUM") hung at
  top-centre on two nails, replacing the plain `_popup_title` on the board only
  (title restored for the other stations).

Reversal of R122's original "no overlap" AC; R122/T134 updated to match, and the
overlap-with-readable-live-text invariant added in their place.

**Boundary.** Client presentation only — no server/shared/protocol change. All game
state, contract selection, and readiness remain server-authoritative over the
existing `SELECT_CONTRACT`/`TOGGLE_READY` intents (I1/I2). No trait data added; every
notice string still derives from `ContractIntel` + `contractId` + client flavor
(P64). The placard and scatter use styleboxes + the shared wood palette — no new art
(greybox convention holds; Aseprite placard/tack art is a later task).

**Verification.** `main.gd` loads clean in Godot 4.7 via the MCP `run_project`
(parse/API check; one `sign`-shadows-builtin warning fixed). The board's live render
+ `board live=4 flavor=N` log is confirmed by the `specs/notice-board/playtest.md`
pass with `pnpm dev:server` up (T134/T137).

**Process note.** This UX pass used the `gds-ux` skill, installed via `skillfish add
bmad-code-org/bmad-module-game-dev-studio gds-ux` (skills-dir, no hooks/MCP). An
earlier MCPmarket plugin install of the same skill was removed for carrying a
SessionStart sync hook + per-skill telemetry + an embedded API token (not on the
sanctioned toolchain).

## TD-041 — Contract acceptance decoupled from commit: reversible seal, two-stage deploy, scalable board (2026-07-08)

**Context.** Playtest feedback on the notice board: (1) the Contract Board broke
under a fullscreen toggle — laid out against raw window pixels with no reflow, it
lingered over-sized on the next windowed open; (2) parchment scaling differed
between windowed and fullscreen; (3) acceptance should be a **reversible seal** the
leader stamps/lifts, notified to the whole party, with the Countersign + per-Seeker
ready ledger removed. This is Pass 1 (functional, greybox) of a two-pass overhaul;
Pass 2 is the pixel-art reskin toward the reference notice board.

**Decision — acceptance is a reversible selection, distinct from commit.**
Previously `SELECT_CONTRACT` was a one-way commit: it staked the Surety and moved
`WAITING → DEPLOYING`. Now:
- `SELECT_CONTRACT` (leader, WAITING, at the board) sets `room.contract` **reversibly**
  — no Surety, no phase change — and broadcasts the snapshot plus a transient
  `CONTRACT_SELECTION { accepted, targetName, actorName }` notice (a client toast).
  The ready-gate is dropped (party-ready belongs to the future pre-deployment stage).
- New `DESELECT_CONTRACT` (leader, WAITING, at the board) lifts the seal, clearing
  `room.contract`; idempotent no-op when nothing is selected.
- `DEPLOY` is now **two-stage**: in WAITING it is the COMMIT (`WAITING → DEPLOYING`,
  requires a selection, else `NO_CONTRACT_SELECTED` — this is where the Surety will
  be staked once that system lands); in DEPLOYING it launches to FIELD as before.
- `ACCEPT_CONTRACT` is retained only as a legacy/test convenience (select-first +
  commit); the client no longer uses it. New error `NO_CONTRACT_SELECTED` (20 codes).

**Decision — the seal UI.** The reader's Countersign button and per-Seeker ready
ledger are replaced by a single **"Stamp your seal"** affordance: a wax seal that is
faint (low-opacity) until stamped and firm once sealed, with the whole area as the
hit target. The leader clicks to `SELECT`, clicks the stamped seal to `DESELECT`;
non-leaders see the seal state read-only. Affordance ≠ authority: a raced
`NOT_*`/`WRONG_PHASE` still surfaces (P56/P66 heritage).

**Decision — scalable board.** Root cause of the fullscreen bugs was the absence of
a content-scale mode. Set `window/stretch/mode = canvas_items`, `aspect = keep`
(base 960×540): the logical viewport is now a constant 960×540 in windowed AND
fullscreen, so the board (laid out against the viewport) is resolution-independent
and the whole canvas — UI and camera view — scales uniformly to the window. Added a
`size_changed` reflow + re-center as belt-and-suspenders.

**Boundary.** Server-authoritative throughout (I1/I2). New wire: client
`DESELECT_CONTRACT`, server `CONTRACT_SELECTION`, error `NO_CONTRACT_SELECTED`;
protocol.gd regenerated. No trait data added. Verified: server 362 + shared 65 green,
`pnpm build` clean, client loads clean in Godot 4.7 via MCP. Live board render +
two-client seal/toast paths remain a user playtest (no screenshot tool over MCP).

**Deferred to Pass 2.** The pixel-art asset set (carved frame + corner joints, plank
backing, hanging routed sign, torn/deckled parchment variants, tacks, cobweb, torch
glow) and the reskin toward the reference, via PIL generators (sanctioned toolchain).
The `canvas_items` stretch change affects the whole game; the field/world view in
fullscreen wants a human eyeball since MCP can't screenshot it.

## TD-042 — Internal resolution is 640×360; script-driven integer fill; mobile is a target platform (2026-07-10)

**Context.** The client launched windowed at a 960×540 base with
`stretch/aspect="keep"` and `scale_mode="integer"`. That is exact only on 1080p and
4K; every other screen letterboxes. Asked whether the game "scales best in
fullscreen on any monitor and/or phone," the honest answer was no. Separately, no
document in the repo had ever named **mobile** as a target, though it is one.

**Finding — the base viewport decides which screens letterbox** (measured, not
derived; via the new `DebugCapture` harness, see `docs/technical/dev-environment.md`):

| Screen | 480×270 (old canon) | 640×360 | 960×540 (old actual) |
|---|---|---|---|
| 1280×720 | bars | exact ×2 | bars |
| 1920×1080 | exact ×4 | exact ×3 | exact ×2 |
| 2560×1440 | bars | exact ×4 | **bars** |
| 3840×2160 | exact ×8 | exact ×6 | exact ×4 |

Note both the documented canon (480×270) and the shipped value (960×540) get 1440p
wrong. `640×360` is exact on 720p, 1080p, 1440p and 4K.

**Finding — `aspect="expand"` does not solve it.** Expand grows the logical viewport
only on an *aspect-ratio* mismatch (ultrawide, portrait). When the ratio matches but
the scale is fractional, it does nothing: 2560×1440 on a 960×540 base measured
`logical=960×540` with bars. Worse, Godot derives the logical viewport from the
*fractional* scale and then floors the draw scale, so `expand` + `integer` still bars
on phone-class screens (2778×1284 measured `bars=444×204`).

**Decision — choose the integer factor first, then size the viewport to it.** New
render-only autoload `client/scripts/pixel_scale.gd` (`PixelScale`): on every window
resize, `factor = max(1, min(win.x/640, win.y/360))` (integer division), then
`content_scale_size = win / factor`, clamped to `MAX_LOGICAL = 1280×720`. The draw
scale is then exactly `factor` — crisp pixels, art canon intact — and the viewport
covers the window. Measured `bars=0×0` at 1280×720, 1920×1080, 2560×1440, 3840×2160,
ultrawide 3440×1440, and phone 2400×1080 / 2340×1080 / 2778×1284 / 2556×1179.

**Decision — internal resolution is 640×360**, superseding the 480×270 written in
CLAUDE.md and in `specs/notice-board/ux-designs/*/DESIGN.md`. Existing UI metrics were
authored against 960×540 and overflowed at the new base (the title screen's "Resume
unfinished expedition" fell off); the menu's fonts, margins and separations were
rescaled. **The Contract Board's Pass-2 layout has not been re-verified at 640×360**
and its `min_glyph` / contrast floor were specified against 480×270 — both need
reconciling before T147 signs off. Compare TD-041, where the board already proved
brittle against raw window pixels.

**Decision — mobile is a target platform**, recorded here for the first time. This is
a UI constraint, not a scaling setting: `PixelScale` handles landscape phones, but
touch input (there is none — the client is WASD/`E`/`Esc`), tap-target minimums,
hover-free affordances, and orientation handling are unbuilt. Portrait could not be
verified on a 1080p desktop (Windows clamps an over-tall window, so the measurement
is invalid); it needs a device or emulator. A mobile-input spec is owed.

**Consequences.** Trade accepted: with a filled viewport, a wider screen sees *more
area* rather than bigger pixels. `MAX_LOGICAL` caps that at 1280×720 so an ultrawide
cannot reveal an unbounded slice of the field; beyond the cap, bars return. The field
camera may still want its own clamp. Fractional scaling remains forbidden (shimmer).

## TD-043 — Art direction pivots to weathered HD-pixel with in-engine lighting; TD-033's palette-lock relaxed (2026-07-11)

**Context.** Reviewing the Notice Board Pass-2 against a Darkest-Dungeon-style
reference (an ornate, aged, torch-lit commission wall), the shipped board read
**flat and brand-new** — the direct, structural consequence of TD-033's strict
15-colour palette-lock and its "no lighting, flat colour" posture. The user's target
vibe is the opposite: **weathered through time, warm, dramatically lit**. They
explicitly authorized overriding the palette-lock canon to reach it, and — asked
whether the pivot was board-only or game-wide — chose **game-wide now**.

**Method.** A throwaway PIL study (`client/assets/ui/gen_prototype.py`) composited the
board with richer ramps, baked weathering (moss, water streaks, foxing, water-stain
rings, torn/curled paper, rust, grime) and a **baked warm light pass** (two torch
pools + centre fill → cool dark edges) to preview the mood. That single light pass is
what dissolved the flatness; it stands in for the real engine lighting.

**Decision — the art target is weathered gothic HD-pixel.** Smooth 24-bit shading at
the native **640×360** (TD-042), upscaled **nearest** — the HD-pixel register
(Blasphemous / Dead Cells / Curse of the Dead Gods), not flat greybox and not
painterly HD raster. TD-033's **strict palette-lock is relaxed**: richer, weathered
ramps and gradients are now allowed. `ashember.py`'s `assert_on_palette` / `quantize`
become **advisory**, not a gate; the Pass-2 generators may be re-authored with fuller
ramps.

**Decision — lighting is now a core visual pillar.** Scenes are **lit, not evenly
bright**: per-torch **Light2D** + **particle** flames + **shaders** on wall, board and
cards. Ambient occlusion, drop shadows and warm/cool falloff are part of the canon
look, not optional polish.

**Decision — scope is game-wide.** The weathered HD-pixel + lighting language governs
**every** surface — field tiles, Seeker sprites, HUD, menus — as they are built or
re-skinned. The **Notice Board is the first canonical example**; other screens adopt
it from there.

**What does NOT change.** TD-033's *tool purge* stands: **no** Blender 3D, MediBang,
painterly external raster, `.blend`/`.fbx`/`.gltf`/`.obj`, or Node3D scenes. The
sanctioned toolchain is unchanged — **Godot 4.7 / Aseprite / Python-PIL generators**.
640×360, nearest filtering, 16×16 tiles, the Seeker 16×24/48×48 rig and part-lag
animation (TD-042) all stand. The **trust boundary** is untouched: lighting/shaders
are render-only; no game logic moves to the client. And the **game-truth invariants**
hold — still no reward coins (TD-017), no Incarnate art on the board (mystery is the
mechanic), every card trait-free `ContractIntel` (I3/I5).

**Consequences / owed work.**
- CLAUDE.md "Art Direction & Sanctioned Toolchain — CLOSED LIST" is amended to state
  the weathered HD-pixel target + lighting pillar and the relaxed lock (done alongside
  this entry).
- The Notice Board Pass-2 layout pivots **scatter → framed grid** (ref-faithful),
  which **moots T145's keep-out/scatter solver**; T145–T147 are re-scoped to the
  grid + weathering + the Godot lighting layer. Godot build order (user choice):
  **layout + interaction first** (grid, real `ContractIntel`, seals/pips, hover,
  selection → DEPLOYING), lit afterward.
- New work is owed: a Godot **lighting layer** spec (Light2D torches + wall/board/card
  shaders + flame particles), and a later sweep re-skinning field/HUD/sprites to match.
- `gen_prototype.py` is a **throwaway study**, not a shipped generator; it is kept only
  as the look reference for the Godot pass.

## TD-044 — Painterly/HD-raster restriction lifted; the contract board's target is Prototype v1 richness (2026-07-11)

**Context.** The contract board is being built toward the pinned **Prototype v1** study
(the rich, weathered, torch-lit board that references a hand-painted HD-raster contract
board). The user judged the code-generated board too crude, and an HTML/CSS reference
mock a regression to a flat "old" style. TD-033's tool purge (kept by TD-043) forbade
"painterly / HD raster sources," which the user named as the restriction to lift.

**Decision — the painterly / HD-raster restriction is lifted (user-authorized, 2026-07-11).**
Painterly / HD raster source art is **no longer forbidden** for the Notice/Contract Board
(and, for cohesion, game-wide as adopted). The target look is **Prototype v1's richness**:
rich weathered aged parchment, an ornate carved **gilded** frame with a crest, **red
banner torches**, a dense **4-over-3 grid**, **legend + active-assignment** bars, and a
deep torch-lit ambience. This supersedes — does not edit — the raster clause of TD-033 /
TD-043 (the log is append-only, Key Invariant #4).

**Capability note (a tooling fact, not a rule).** Claude Code builds art **through code**
(the Python generators) + Godot; it has **no image-painting tool** in this environment.
So what Claude can deliver itself is **rich HD-pixel matching Prototype v1** — v1 is
itself a code/PIL composite, so this is achievable end-to-end. True hand-painted raster
*beyond* v1 would need **author-supplied** painted / AI-generated source images, which
Claude then slices, composites, and wires into Godot. **Chosen path (user, 2026-07-11):
match Prototype v1 in code-generated rich HD-pixel — no external assets.**

**What still stands.** The rest of TD-033's purge is unchanged: **no** Blender 3D, no
Node3D scenes, no `.blend`/`.fbx`/`.gltf`/`.obj`, no MediBang, no `.mdp`. Toolchain stays
Godot 4.7 / Aseprite / Python generators. Trust boundary and game-truth invariants are
untouched — the board's cards stay **trait-free** `ContractIntel` (the user's "Neither"
call: **no threat, no reward** on the wall; I3/I5 hold), and there is no Incarnate art.

**Owed work.** Rebuild the live Godot contract board 1:1 to Prototype v1 — dense 4-over-3
grid, ornate gilded frame + crest, red banner torches, legend + active-assignment bars,
richer aged parchment — pushing `gen_structure.py` / `gen_detail.py` to v1-grade richness;
resync the notice-board spec's card/layout language to the grid + v1 richness.

## TD-045 — Contract Board is canonically 8 contracts (2026-07-11)

**Decision (user, 2026-07-11).** The Collegium posts **8** contracts on the board at once,
up from 4 — a full commission wall that fills the Notice Board's **4×2 grid** (Prototype
v1) and reads as a busy Collegium, not a short list. `BOARD_SIZE = 8` in
`src/server/src/incarnate/generateBoard.ts`; the generator already honours an arbitrary
`size`, so this is a **one-constant data change**, not a shape change — determinism (I3)
and the trait-free wire (`toContractIntel` strips seed+roll, I3/I5) are unchanged. The
client grid caps at 8 and the preview fixture carries 8.

**Consequences.** `generateBoard.test.ts` asserts length via `BOARD_SIZE`, so it stays
green (verified). R109's "board pool" is now size 8 (spec note owed). No balance system
depends on the count yet; if Collegium-Rank gating later varies how many are shown, that
is a further data change. The board stays **APPRENTICE**-tier v1 until Rank exists.

## TD-046 — Canonical art register is hand-painted raster 2D pixel art; Claude generates raster PNGs directly (2026-07-12)

**Context.** Through TD-033 → TD-043 → TD-044 the art canon accreted a tangle of
qualifiers: a *strict palette-lock* (TD-033, later "relaxed" and "advisory"), a
*"weathered HD-pixel"* register (TD-043), and a raster clause that was forbidden
(TD-033), then "lifted but **author-supplied only**" because "Claude has no image-painting
tool, so its own deliverable is **code-generated HD-pixel**" (TD-044). In practice this
left contradictory guidance and pushed Claude toward runtime-drawn vector primitives
(the wax seals, the verb badges) that read flat against the hand-painted board. The user
asked to **name one canonical style — hand-painted raster 2D pixel art — and remove the
prior competing direction.**

**Decision (user-authorized, 2026-07-12).** Testament's single canonical visual register
is **hand-painted raster 2D pixel art**: warm, weathered, dramatically torch-lit, in the
Prototype-v1 idiom. Every UI/world surface is authored as a **raster PNG** (aged
parchment, carved gilded frame, wax seals, verb sigils, tacks, banner, crest), imported
**Nearest**, and lit in-engine (TD-043's Light2D pillar stands). The strict
palette-lock is **retired outright** (not merely "advisory"): 24-bit painted ramps,
gradients, AO, and bevel shading are the norm. This supersedes — does not edit (Invariant
#4) — the *register* language of TD-043 and the *author-supplied-only* clause of TD-044.

**The tooling correction (the load-bearing change).** TD-044 said true raster "beyond
v1" needs **author-supplied** images because Claude cannot paint. That constraint is
**dropped.** Verified 2026-07-12: Claude generates raster PNGs end-to-end with the Python
generators (`ashember.py` + `gen_*.py`) and imports brand-new files **headlessly** via
`godot --headless --import` (creates the `.png.import` so a game-run loads them — this
removes the prior "new PNGs don't load without the editor" blocker). So **raster is now a
first-class Claude deliverable**, not only an author hand-off. Author-supplied painted /
AI-generated source art remains welcome for richness beyond what the generators reach, but
is no longer *required* for raster.

**Consequences (this pass).** The wax seals (`wax_seal.gd`) and verb badges
(`verb_badge.gd`), previously drawn at runtime with `draw_*` primitives, are **redesigned
as hand-painted raster PNGs** with generators, imported headlessly. Orphaned/superseded
sprites were deleted (`board_backing/frame/wood`, `foxing`, `stone_tile`, `parch_card_*`,
`parch_live_*`); the live asset set is the 20 PNGs the board actually loads plus the
`_proto_board.png` reference. `docs/art.md` + `docs/art/style-guide.md` are updated to
this register; CLAUDE.md's art block is rewritten to name it and drop the palette-lock /
"code-generated-only" framing.

**What still stands.** TD-033's **tool purge** is unchanged: **no** Blender 3D, no Node3D
scenes, no `.blend`/`.fbx`/`.gltf`/`.obj`, no MediBang, no `.mdp`. Toolchain stays Godot
4.7 / Aseprite / Python generators. Canonical conventions hold: 16×16 tiles, **640×360**
internal (TD-042), Nearest, integer scale, mobile a target. Trust boundary and game-truth
invariants untouched — the board stays trait-free `ContractIntel`, no Incarnate art, no
reward/threat on the wall (I3/I5).

## TD-047 — Board lighting goes dynamic: normal-mapped surfaces + hybrid light shader + particle fire; new active spec (2026-07-12)

**Context.** After the TD-046 art-director polish, the board's lighting was still largely
**baked**: `frame_v1.png` carried painted highlights and the fire was a 4-frame additive
sprite sheet. The user asked to make the surround **dynamically** lit — recolour `frame_v1`
generic and let the light "reflect" on it (shader), and redo the sconce/fire as a **particle**
flame with flicker — and to **spec it first**.

**Decisions (user-authorized, 2026-07-12).** New active visual spec **`specs/board-lighting/`**
(R129–R135, P71–P74, T148–T154), client render-only (I1/I2 hold — no server/shared/wire change):
- **Technique = hybrid: normal map + `light()` shader.** The surround (frame, backing, wall)
  becomes `CanvasTexture` diffuse+normal, lit natively by the torch `PointLight2D`s; a thin
  `canvas_item` `light()` override adds a stylised ember rim/warmth. Chosen over a bare custom
  shader because Godot's 2D renderer already does normal-mapped lighting for free — the shader
  adds only what Light2D can't, and reads the light **natively** so it can't desync (P72).
- **Fire = CPUParticles2D** (renders in the DebugCapture pipeline so it's eyeball-verifiable;
  mobile-portable per TD-042). GPU particles declined for capture/mobile risk.
- **Scope = frame + backing + wall.** `wall_v1`/`backing_v1` keep their painted diffuse (art
  unchanged, normal map added); **`frame_v1.png` is re-authored NEUTRAL** so the torchlight
  supplies its colour. This **explicitly lifts the earlier "don't redesign the wall/frame" note
  — for lighting only** (frame diffuse neutralised; wall art untouched).
- **Reduced motion** (F9) freezes the flame to a static sprite + pinned-peak light (P73);
  everything stays **capture-verifiable** and headless-parseable (P74).
- **Diegetic props (added same day, R136–R141).** The **parchments** (notices + reader) and the
  **banner** are also lit by the one rig — the banner is redesigned as clean raster (frayed crimson,
  plain, no stray pixels) + a cloth normal; the parchments get warm falloff under a **legibility
  floor** (ambient fill + unlit ink so a writ never sinks below readable, P75). The **backing**
  diffuse is re-authored **darker** (hard modulate dropped; light supplies brightness). The **crest +
  placard** are top-center, **out of the bottom torches' reach, so they are deliberately NOT lit**
  (user ruling — no faked top hotspot, P77): **restyled + recoloured only**, tonally matched. All
  board surfaces unified to the one hand-painted raster register (P78).

**One flagged risk (T149 go/no-go).** If `CanvasTexture` normal-mapping does not light a
`NinePatchRect`/`TextureRect` *Control* on this Godot build, the fallback is a per-surface
`canvas_item` shader that samples the normal itself (still the hybrid) — to be recorded here if
taken.

**Resolution (Phase A, 2026-07-12) — the risk hit; fallback taken.** Godot's `Light2D` (2D
lighting) **does not reach these Control nodes at all**: a torch `PointLight2D` cranked to
energy 8 / scale 7 changed the render by a measured `(0,1)` — i.e. nothing. The "torch glow" on
the board was always the **additive glow sprites**, never Light2D lighting the wood. So the
native-`CanvasTexture`-lit-by-`PointLight2D` path is **dead for this UI**, and Phase A ships the
flagged fallback: a `canvas_item` **fragment** shader (`assets/ui/board_surface.gdshader`) that
samples the normal map and lights it from **uniform torch lights** (rgb+energy+radius in
`SCREEN_UV` space) — no Light2D dependency. One rig (`BoardDecor.torch_rig`) drives both the
torch-sprite placement and the shader uniforms so they can't desync (P72 preserved). The frame is
a shader-lit `NinePatchRect` **overlay** tracking the popup rect (a `StyleBox` can't hold a
material, and an in-canvas frame is clipped by the board's `ScrollContainer`); backing (NinePatch)
+ wall (TextureRect) take the material directly; the dark `backing_v1` is pre-lifted in-shader via
`diffuse_gain`. **9-slicing survives the shader** (per-patch UV interpolation is unaffected —
verified on backing + frame). The dead `PointLight2D` block is removed; `--lights-off` now zeroes
the shader `light_count`. **V1 green:** lit rakes warm relief across frame/backing/wall,
`--lights-off` shows flat neutral wood (lit-vs-off diff `(0,213)` vs the PointLight2D's `(0,1)`).
**Consequence for Phase C:** the particle fire's sympathetic light must also feed the shader rig
(animate `light_col[i].a`), not a Light2D.

**Notice-board Pass-2 status.** T145–T147 (a11y/keyboard, empty-board, error-toast, the L1–L8
verification) remain **open/deferred** — several T145 items already folded into the TD-046 pass
(keep-out, pinned paper, legibility). This log switches the *active* spec to board-lighting; the
notice-board spec is paused, not abandoned.

## TD-048 — Board lighting re-graded to dungeon-dark; Phase-A frame neutralisation reversed (2026-07-13)

**Context.** Phase B's warmth/reach tuning (T150: warm `ambient_tint`, `smoothstep`+extended torch
`radius` 0.62→0.74, plus the standing broad additive gutter wash) **over-corrected**. On review the
user judged the firelight so bright it **washed out the dark ambient Collegium/dungeon mood** and
drowned the **material colour** of the frame edges, backing, and wall — the sconce fire was *stealing
the show*. The board should read as a dark gothic surface where the **material** is the subject and
the fire is merely **alive**, not a floodlight.

**Decisions (user-authorised, 2026-07-13; three locked answers).**
- **Mood = deep dungeon-dark.** The surround sits mostly near-black; the flames are the only warm
  source and cast **near-zero** onto surfaces (a tight cup halo at most); wood/stone colour only
  *whispers* out of the dark. Canon "lit, not evenly bright" (TD-043) is weighted hard toward *dark*.
- **Colour source = restore the material's own colour.** **`frame_v1.png` is re-authored BACK to
  carved warm wood** (baked hue, legible even unlit), from the preserved original `_frame_v1_src.png`
  (kept at T148). This **reverses the Phase-A / TD-047 premise** that the frame be *neutralised* so
  "the torchlight supplies its colour" — that premise is **retired for the frame** (its normal map
  `frame_v1_n.png` is kept). Backing + wall read in their own colour at a low key (the shader
  `diffuse_gain` over-lift is dropped).
- **Fire reach = flame visible, near-zero cast.** The flame flickers/looks alive but lights surfaces
  almost not at all: shader `gain`/`radius`/energy pulled well in, warm `ambient_tint` retired (or set
  to a low **cool** dungeon fill), and the broad additive **gutter wash** sprite shrunk-hard-or-dropped
  with the cup glow reduced to a small dim halo.

**Scope & containment.** Still `specs/board-lighting/`, **client render-only** (I1/I2 hold — no
server/shared/wire/game-state change, R135 stands). New **Phase B-2 — Lighting Restraint**: R142–R146,
P79–P81, T160–T162, verification V11–V13. The Phase-A normal-map/uniform-shader machinery and the one
`torch_rig` (P72) are **kept but scoped** to a tight, dim halo. **Supersession:** the T150 grade is
superseded (its warmth/reach walked back); **V11 supersedes V1's old "`--lights-off` ⇒ flat neutral
wood" expectation** — with baked colour restored, lights-off now shows a *coloured dark wooden board*
and R129's "light does the work" proof shifts to the small **local** lit-vs-off delta at each sconce,
not a global one. The parchment notices are unlit baked paper, so their T145 contrast floor is
unaffected by however dark the surround goes.

## TD-049 — Board header goes heraldic: ornate blade-and-laurel crest + carved nameplate; new active spec (2026-07-13)

**Context.** With board-lighting closed (TD-047/TD-048), the board header was still plain: the
radiant-star medallion (T158) + routed placard (T159) were tonally cohesive but simple. The user
supplied a Prototype-v1-family reference — a **Blasphemous-idiom carved header**: an ornate gilded-
bronze emblem (upright **sword** + encircling **ring** + **laurel wreath** + **filigree scrollwork**)
crowning a wide **carved-plank nameplate** with **iron corner brackets** and a two-line gilt title
("THE COLLEGIUM" / "CONTRACT BOARD") — and ruled: "the crest and placard should look like this — not
exactly, but **the design itself**."

**Decision.** Open a new spec `specs/board-heraldry/` (R147–R151, P82–P85, T163–T166) to re-author the
header to that design language: a generated ornate crest (`gen_heraldry.py`), a carved nameplate with
iron corner brackets (9-slice), a widened header, and a big-title/subtitle. Binding = the *design
language* (blade-and-laurel crest; carved plate with corner brackets; title + subtitle); the exact
pixels are not. Origin-neutral (the blade of inquiry + the scholar's laurel is the **Collegium's**, not
a trait sigil — P84). The title wording moves to the reference's signage form ("THE COLLEGIUM / CONTRACT
BOARD"), on-canon (the order + the station name), trivially revertible to the diegetic petition-line.

**Scope & containment.** **Client render-only** (I1/I2 hold — no server/shared/wire/game-state change,
R151). Continues the TD-048 dungeon-dark grade: the header is **baked + tonally matched** (no dynamic
shader — same reach ruling as the crest/placard), an accent on the dark, never a bright slab. **Supersedes**
the T158 radiant-star crest + T159 routed placard (the immediate baseline). Generator gotchas carry over
(run from `client/assets/ui/`; new PNGs need `--headless --import`).

## TD-050 — Contract Board consistency pass: crest resize/crisp, single-line title, de-crowd, style-level, banners, surfaces (2026-07-13)

**Context.** After the heraldry header (TD-049) shipped, the user reviewed the whole Contract Board
scene and asked for a consistency pass. Their requests + rulings (2026-07-13):
- **Crest** — too large + blurry; make it **smaller and crisp** (the sword + laurel must read as defined
  forms). The blur is the LINEAR downscale of the 150×132 source to ~82×72; the size crowds the top notice row.
- **Title** — drop "THE COLLEGIUM"; the nameplate reads **"CONTRACT BOARD"** only (single line).
- **Contract spacing** — **keep the organic scatter** (TD-040); the inconsistent spacing is the oversized
  crest crowding, not the scatter — fixing the crest fixes it.
- **Style consistency** — the scene's pixel styling is inconsistent; make it **one register**, fixing
  **both sharpness AND detail** (crisp the soft/blurry, level DOWN the over-busy). **Keep the carved frame**
  (the user likes it) — it is the **reference register**. **DON'T deviate the styling** (stay in TD-046
  hand-painted raster canon).
- **Banners** — too long, overlapping the sconces; **shorten** so they end above the sconce with a gap.
- **Backing + wall** — not visible (over-sunk by TD-048); make them **visible but still moody** (read the
  grain + masonry, kept darker than the parchments/frame).

**Decision.** Open a new spec `specs/board-consistency/` (R152–R158, P86–P91, T167–T172): re-author the
crest smaller + crisp (author near display size, NEAREST), single-line title, restore the notice reserve so
the kept scatter de-crowds, shorten the banners off the sconces, lift the backing + wall to a visible-but-
moody key, and run a one-register sharpness+detail consistency pass anchored to the (untouched) frame.

**Scope & containment.** **Client render-only** (I1/I2 hold — no server/shared/wire/game-state change, R158).
**Re-tunes TD-049** (two-line title + 82×72 crest → single line + smaller crisp crest; heraldry design kept).
**Partially walks back TD-048** for the **backing + wall only** — the surfaces rise to visible; the frame's
restored colour, the parchment legibility floor, and the near-zero fire cast all **stand**. The carved frame
is deliberately **not** touched.

## TD-051 — Dependency map: generate the script↔asset graph, don't hand-maintain it (2026-07-13)

**Context.** Every fresh session burned context re-scouring the tree to answer basic wiring questions
— "which script `load`s this PNG? which `gen_*.py` writes it? who `preload`s this `.gd`?". The board
work especially has a dense web (`gen_heraldry.py` → `crest_v1.png` → `board_decor.gd`, placed by
`board_geometry.gd`, …). The user asked for durable dependency documentation so a fresh session can
continue without re-deriving the graph, and invited a better solution.

**Decision.** DERIVE the graph, don't hand-write it. Open `specs/dependency-map/` (R159–R164,
P92–P94, T173–T177): a stdlib-Python tool `tools/asset_map.py` statically scans `client/` for the four
edge kinds (gd `load`/`preload`, tscn `ext_resource`, py `write_png`) and emits
`docs/technical/asset-map.md` — every asset's producer(s) + consumer(s), each script's
loads/preloads/loaded-by, generators' writes, plus **Orphans** (dead art), **Dangling** (ref to a
missing file), and **Unresolved dynamic references** (paths built from a variable — declared blind
spots, never silently dropped). Templated paths (`%d`/`%s`/`{}`) are globbed against on-disk files.

**Why generated, not a hand-written doc or inline-only comments.** A dependency doc is only useful if
a session can *trust* it without re-verifying; the moment it can drift, the session must re-scour
anyway and the doc bought nothing — a **stale** map is worse than none. So the graph is derived and a
**`--check`** mode makes staleness a hard failure (exit 1), keeping the committed map honest. Inline
**provenance headers** are kept for the orthogonal thing a scanner can't infer — *why* a dependency
exists (a clip escape, a filter choice, a superseded twin); documented in `docs/technical/code-map.md`
(placeholder filled). The named test is the tool's own `--selftest` (asserts known edges +
determinism) + the `--check` round-trip (Python-tooling convention, mirrors `ashember.py`).

**Immediate findings (the payoff).** The first generated map surfaced, with zero scouring: two
generators both write `crest_v1.png` (`gen_emblems.py` legacy + `gen_heraldry.py` current — a latent
conflict), and `parch_live_*` + `board_placard.png` are orphaned dead art. Exactly the kind of
knowledge that used to cost a session to rediscover.

**Scope & containment.** Dev-tooling / docs only (P94): stdlib-only, reads `client/`+`src/`, writes
only under `docs/`, imported by nothing at runtime, mutates no asset/script/scene. No server/shared/
client-runtime change. CLAUDE.md + `.claude/rules/spec-workflow.md` point new work at "regenerate
`asset-map.md` + pass `--check` when a dependency changes".

**Auto-update (keeps the map current with no manual step).** Two hooks close the drift gap:
- **PostToolUse** (`.claude/settings.json` → `tools/asset_map_hook.py`): regenerates the map in-session
  whenever a `client/` `.gd`/`.tscn` or a generator `.py` is edited.
- **git pre-commit** (`tools/git-hooks/pre-commit`, installed via `git config core.hooksPath
  tools/git-hooks`): blocks a commit whose map has drifted from source — the backstop for edits made
  outside a Claude session (human/IDE/merge). A CI `--check` step is the remaining natural follow-up.

---

## TD-052

**Switched active spec from `dependency-map` (TD-051) to `board-banner`.** A Contract Board scene
polish on the user's review of the emblem/heraldry work. Client render + generated art only — no
server/shared/logic change (I1/I2); verified by `--board-preview` captures (client-spec convention).

**Scope (user rulings, do not re-litigate):**
- The board **crest is too big** → reduce it (R165).
- The flanking **banners read as ragged greybox** with ugly mount hardware (iron rod + nails, the
  "wooden stand/lock") → re-author as **proper hanging banners**: clean woven crimson, baked folds/AO,
  a **swallowtail** hem, a baked top hem (retire the separate rod + nails) (R166).
- **Imprint the Collegium emblem** on BOTH banners as a **pale bone-dye** printed device (a tonal
  color change from the gilt, crimson showing through — baked into `banner_v1.png` so it drapes/lights
  with the cloth) (R167).
- **Two matching banners**, each **centered in its wall gutter** and **widened** (overflow past the
  screen edge is allowed); the **torch light rig stays coherent** — one shared `GUTTER_CX` read by both
  `torch_rig` and `add_torches` so the wall shader lighting never desyncs (R168, P95).
- Re-cut the **"CONTRACT BOARD" placard** as **refined carved wood** (`gen_heraldry.nameplate_px`,
  same 9-slice margins) (R169).

`gen_banner.py` gains a PIL dependency (sanctioned for generators) to read + recolor
`collegium_logo.png`; it still writes via `ashember.write_png` so the asset-map producer edge holds.
The generator→emblem INPUT edge is invisible to the text-static scanner — recorded via a provenance
header. Numbering: R165–R170, P95–P97, T178–T182.

---

## TD-053

**Switched active spec from `board-banner` (TD-052) to `board-header`.** A Contract Board **header**
redesign on the user's brief: the header should read as a **handcrafted institutional object** inside
the Collegium HQ — an ancient expedition board maintained for generations — not a modern game UI.
Register: **ecclesiastical grimdark** (Blasphemous, Darkest Dungeon, Diablo II, Castlevania; medieval
church furnishings, illuminated manuscripts, carved cathedral woodwork). Client render + generated art
only — no server/shared/logic change (I1/I2); verified by `--board-preview` captures.

**Scope (user rulings, do not re-litigate):**
- **Preserve the overall board composition + layout.** Only the header block is reworked — notices,
  scatter, bottom bar, and the TD-052 flanking banners keep their composition (R174).
- The flat title bar → a believable **handcrafted placard**: carved oak / aged dark walnut, reinforced
  with forged iron or weathered bronze, worn from centuries of use, physically mounted onto the board.
  **Utilitarian and institutional, not decorative or luxurious** (R171).
- The Collegium emblem must **not appear pasted above the header**. It becomes an **inset bronze seal**
  (user's pick among carved / branded / embossed medallion / forged brass / engraved relief) — a forged
  bronze medallion set INTO the wood, emblem in raised relief, iron rim, socket shadow. **No glowing
  logos, no floating icons** — the emblem becomes part of the physical board (R172).
- **Text hierarchy: THE COLLEGIUM (primary) over Contract Board (secondary)** — the institution always
  outranks the object. Lettering **engraved / carved cathedral signage**, slightly weathered, not
  perfectly uniform. Increase vertical breathing room; the seal + both lines read as **one cohesive
  centered object** (R173).
- Materials: **aged wood, bronze, iron, aged brass, parchment only** — no polished modern surfaces.
  Lighting: warm **candlelit** ambience, soft highlights, subtle edge wear — **no bloom, no gloss** (R175).

**Consequences.** The crowning `_board_crest` overlay + its per-frame `_process` position chase are
**retired** (P98) — that machinery existed only to escape the ScrollContainer clip (TD-049), which a
seal set into the plaque no longer needs. `gen_heraldry.py`'s `nameplate_px`/`board_nameplate.png` is
superseded by the new `gen_header.py`, and its already-dead `crest_px`/`crest_v1.png` goes with it —
clearing the double-producer conflict (`gen_emblems.py` writes the same path) that TD-051's first
dependency map surfaced. `TOP_RESERVE_FRAC` and `placard_rect` grow for the taller header; the keep-out
self-check is the guard that the scatter survived (P99). Numbering: R171–R176, P98–P101, T183–T187.

---

## TD-054

**Contract Board header re-cut toward the author's reference; Cinzel adopted as the display
face.** The author supplied a reference image of the Contract Board and asked how close we
could get. Analysis first, three findings:

1. **The reference is a repaint of our own board** — same eight fixture contracts, same
   "— no charge sealed —", same bottom bar. So the *composition already matched*; the gap was
   craft, not layout.
2. **Resolution is NOT the blocker.** Pushing the reference through our own pipeline
   (LANCZOS to the internal 640×360, integer-scale back) keeps its header legible: that block
   is only **184×78 internal px** — smaller than the 248×76 header TD-053 shipped — and the
   ring medallion, strap hinges and sword-and-laurel all survive. The register can hold it.
3. **The typeface was the blocker.** The reference sets its title in a Roman inscriptional
   serif; we were letter-spacing Godot's default sans to imitate gravitas. No amount of
   generator work closes that gap.

**Rulings (author, do not re-litigate):**
- **Cinzel adopted as the display face** (SIL Open Font License 1.1, `client/assets/fonts/`,
  OFL.txt shipped alongside per the licence). It IS the face in the reference. Display/titles
  only; body text keeps the existing face. This is an **asset addition approved explicitly**
  (CLAUDE.md requires approval before adding to the sanctioned toolchain). The face imports
  with its **own** antialiasing — the project default is no-AA for crisp pixel text, which
  shatters Cinzel's fine serifs at this size.
- **The emblem returns to a ring medallion crowning the sign**, reversing TD-053's
  "inset seal / not pasted above" ruling. It is not a floating icon: scroll bosses at 3 and
  9 o'clock seat it ON the sign's top rail, so it reads as bolted hardware. The inset vesica
  seal is retired.
- **Scope: header first**, then review before touching banners, torches, or wall brackets.

**Verdict on 1:1: not achievable, and the reason is register, not effort.** The reference is
a painted, continuous-tone render; our art is generated from equations and rendered at a fixed
640×360. Composition, form and type can match; brush-level irregularity and the reference's
bloom cannot (2D glow via WorldEnvironment exists but would be a new rendering pillar, and the
author has ruled "no bloom" for the header). Realistic ceiling ≈ **85% with the font**, ~65%
without.

**Form.** `board_header.png` becomes a **short strapped sign** (248×**44**, was a 248×76 slab):
vertical iron end-straps (a bar between two bolted plates) inside the 9-slice margins, an open
plank field, a lit top rail and a slim routed bottom rail. `board_seal.png` becomes the
**40×40 ring medallion** (bronze annulus with a bead-and-fillet profile around a recessed field
carrying the emblem in raised relief). The medallion **overlaps** the sign's top rail, so the
two **share one 76px header budget** — critical, because header height is zero-sum against the
writs (`live_bounds.h = 184.24 - placard_h`, split across two rows). Writs therefore hold at
**93×48**; `placard_rect` and `TOP_RESERVE_FRAC` are unchanged from TD-053.

Client render + generated art only. Remaining reference gaps (banner rods with brass finials,
standing floor torches, wall corner brackets, the medallion's laurel, the reference's lowercase
subtitle) are deferred pending the author's review; a spec follows if that work proceeds.

---

## TD-055

**Hi-res painted UI considered and REJECTED; the pixel-art register is reaffirmed.** Asked
whether the board's art could be antialiased to sit closer to the author's reference. The
investigation corrected two standing misconceptions, both worth recording:

1. **The UI already rasterizes at the window's NATIVE resolution.** `window/stretch/mode` is
   **`canvas_items`** (not `viewport`), which scales the canvas *transform* rather than
   upscaling a 640×360 framebuffer. Fonts and vector draws therefore come out at the full
   device pixel count — which is why adopting Cinzel (TD-054) produced such a large jump.
   Verified empirically, not from docs: in a 1280×720 capture, ~34% of horizontal colour
   changes in the title land on ODD x. A 2× upscaled framebuffer can only change on even x.
2. **Our generators already antialias** (SS=4 supersample → averaged downsample). Blockiness
   is NOT missing AA. It is that textures are authored at 1× logical size and sampled
   **NEAREST**, so the canvas transform doubles each texel into a 2×2 device block. The
   medallion measured **0.5%** odd-x changes — pure 2×2 blocks — while stretched surfaces
   (parchment ~50%, the sign's wood ~35%) already sample at native and are not clean pixel art.

**Therefore "antialiased crisp pixel art" is a contradiction at a fixed resolution** — AA'ing
at 1× and upscaling NEAREST yields blurry blocks, not painted art. The reference is not pixel
art; it is a painted hi-res UI. The reachable equivalent is to author UI textures at **3×**
their logical size and draw them **LINEAR** (texels then land ~1:1 on device pixels — exactly
1:1 at 1080p). Prototyped on the ring medallion (120×120 master → a 40×40 rect): the ring
stops stair-stepping, the sword resolves a crossguard, the laurel arms separate, the bosses
turn round. Cost is negligible (a 120×120 texture; mobile included).

**Ruling (author): stay pixel art.** The prototype is REVERTED — `board_seal.png` returns to a
40×40 master drawn NEAREST. TD-046's single canonical register (hand-painted raster 2D pixel
art) and TD-042's Nearest filtering **stand unamended**; the UI is NOT carved out of the
register. The consequence is accepted deliberately: the reference's smooth painted metal is
**out of reach**, and no amount of generator work closes it. The realistic ceiling against that
reference is composition, form and type — which TD-054 delivered — not surface finish.

**Do not re-propose hi-res/LINEAR UI art as a fidelity fix.** It was measured, prototyped, and
declined on register grounds, not on cost or feasibility. Mixed registers (a smooth medallion
beside blocky wood) read as a bug, so any future revisit is all-or-nothing across every UI
surface, and amends TD-046 first.

---

## TD-056

**The medallion's device is REDRAWN at its display size; the header shrinks and hangs higher.**
Author's review of TD-054: the sigil is blurred, the placard is too large, and it should sit
higher to give the contracts room.

**The blur was not a filter problem — it was a resampling problem.** The medallion's device slot
is ~**17×22 px**. We were LANCZOS-reducing the author's **132×220** emblem into it: a
photographic reduction of a thin blade and fine laurel leaves into far fewer pixels than the
detail needs. No filter setting recovers that, and TD-055 already ruled out the hi-res escape
hatch. So the device is now **drawn** in `gen_header._device_px` — authored in a 160×210 design
space with every stroke sized in OUTPUT px first and multiplied up, then supersampled (SS=4)
down to the slot with baked AA. Same lesson as **TD-050** (the crest), which the retired
`gen_heraldry.py` applied and which was lost when it went.

**This is a redraw of the author's mark, not their raster** — it keeps the identity (point-DOWN
blade, diamond pommel, double/patriarchal guard, laurel wreath) at a size the original cannot
survive. The **banners still imprint the author's actual art** (~112 px wide, where it resolves
fine). `gen_header.py` therefore no longer consumes `collegium_logo.png`.

Two failures worth recording, both from drawing detail the slot cannot hold:
- **Leaves became a ladder.** Individual laurel leaves at 15 design px land on ~1.6 output px
  and merged with the branch into vertical rungs. Replaced by ONE elliptical band, notched by
  angle (`_wreath`), which reads as foliage at 17×22.
- **A closed wreath read as an ANCHOR.** The band's foot joining under the vertical blade forms
  flukes. The wreath is now open at BOTH the top (the hilt stands clear) and the foot (the blade
  passes through), leaving two arcs — which is what a laurel actually is.

**Geometry.** The header has a hard floor: `H >= medallion_height + title_band + bottom_rail`
(~29px), independent of how far the medallion overlaps — its full height always costs, whether
above the sign or eating the sign's field. TD-054 spent 76 where the floor was 69. Now:
medallion **40→36**, sign **248×44 → 204×46**, `placard_rect` **248×76 → 204×65** hung at
`inner.y*0.014` (was 0.02), `TOP_RESERVE_FRAC` **0.29 → 0.24**. Live writs **93×48 → 93×54**
(the original, pre-header board was 93×60), and every writ now shows its site line.

**On AI/pixel-art tooling (asked, answered):** none is available or appropriate. No image-model
runtime, API, or Aseprite exists in this environment, and adding one needs approval under
CLAUDE.md's closed list. More to the point, **image generators cannot author to a 17×22 grid** —
they emit ~1024² "pixel-art-styled" images with inconsistent grids, and downscaling their output
reproduces exactly the mush this entry removes. At this size the correct tools are procedural
drawing with supersampling (used here) or a human pixel artist in Aseprite (the sanctioned path
for author art). Aseprite is NOT installed; author-drawn art remains welcome, never required.

---

## TD-057

**Aseprite adopted for sprites; the Python generators keep the surfaces. Settled by experiment.**
The author proposed installing an Aseprite MCP server (researched via Gemini) to author assets
instead of generating them programmatically. Three findings, in order of importance:

1. **Aseprite was already installed and already drivable — the premise was wrong.** It is at
   `/mnt/d/Steam/steamapps/common/Aseprite` (Steam, 1.3.17.2). Verified end-to-end from WSL:
   `Aseprite.exe -b --script foo.lua` runs the **full Lua API** in batch, draws, and saves a PNG
   readable back in WSL. **No MCP is needed for access** — `run_lua_script` is the MCP's own
   escape hatch and we have it natively. An MCP's marginal value is its 104 *curated* tools
   (shading ramps, dithering, onion skin, tweening, 9-patch slices), not capability. Deferred:
   revisit when sustained animation work starts (the Phase 5 Seeker rig), where its 24 animation
   tools are real leverage over hand-rolled Lua.
   - On the research itself: `diivi/aseprite-mcp` is **real** (308★, Python, active) and its
     "104 tools / 17 categories" is verbatim from its README. `willibrandon/pixel-mcp` is real
     (95★, Go). The claimed "Aseprite MCP Pro by y1uda" **does not exist** (404) — a reminder to
     verify before installing.
2. **The scope "Aseprite instead of programmatic" is wrong, and would make the board worse.**
   Most board art is not sprites: wood grain, stone, parchment fibre, gradients, AO, bevels,
   normal maps, and shader inputs. `gen_header._wood()` is eight lines of sine+noise; hand-placing
   a 204x46 grained plank would be slower, worse, and would break the deterministic regeneration
   that `tools/asset_map.py`'s producer edges depend on (TD-051).
3. **Where a pixel is a design decision, hand-drawn wins decisively — measured.** The medallion's
   device slot is ~17x22. Three approaches, same slot:
   - LANCZOS-reducing the author's 132x220 emblem (TD-054) → **mush**.
   - Shape functions drawn at slot size (TD-056) → better, still poor: the pommel blobbed, the
     two crossguards merged, the laurel read as a smudge (and, closed, as an **anchor**).
   - **Hand-placed pixels in Aseprite** → the diamond pommel, both crossguards, the tapered blade
     with its lit ridge, and two laurel arcs with leaf notches ALL read.
   A shape function samples a curve; it cannot decide *which single pixel* carries the crossguard.

**Ruling: Aseprite owns sprites (sigils, icons, sprites, animation); Python owns surfaces.** This
is what CLAUDE.md's toolchain table always specified — we had simply never used it, because the
install was assumed absent. The repo had **zero** `.aseprite` files; it now has its first.

**Implementation.** `art/src/collegium_device.aseprite` (+ its `.lua` source and exported `.png`)
is the hand-drawn 17x22 device. `gen_header.py` reads the PNG as (alpha, luminance) and strikes
it into the bronze field: **Aseprite owns the sprite, the generator owns the surface.** Two
integration rules learned:
- **Sample the sprite NEAREST, on whole-pixel origins.** `seal_px` is supersampled, so bilinear
  sampling averages the artist's pixels into mud, and a half-pixel origin smears each drawn pixel
  across two output ones — reintroducing the exact blur this removes.
- **Trust the drawn values.** The derived relief (sampling the mask offset both ways for lit and
  shadowed lips) existed for a mask with no values of its own. Applied to drawn art it fights the
  artist and fragments 1px strokes. The sprite's luminance IS the relief; map it to the ramp.

The **banners keep imprinting the author's real 132x220 art** (~112px wide, where it resolves).
Only the tiny slot needed a redraw. The device is a redraw of the author's mark, not their raster.

---

## TD-058

**The crowning medallion is REMOVED; the sign hangs flush at the top of the board.** Author's
review of TD-057: the emblem on the header still isn't earning its place, and the contracts want
the room. So the decision, after three passes fighting the same 17x22 device slot (LANCZOS mush
TD-054, blobbed shape functions TD-056, hand-drawn Aseprite TD-057), is to stop fighting it and
**drop the medallion entirely**. The header is now just the carved sign — iron corner straps,
bronze bolts, an open plank field, a lit top rail and a routed bottom rail — carrying the engraved
two-line title (**THE COLLEGIUM** over **Contract Board**), hung at the very top of the board.

**Why remove rather than keep iterating.** The device slot is the header's whole problem: at
~17x22 px every pixel is a design decision, and even the hand-drawn sprite (the correct tool,
TD-057) reads as a small dim smudge on a board where nothing else asks the eye to parse detail at
that scale. The title already names the institution; the medallion was decorating a label, and
the decoration cost real estate the board's actual job (showing eight legible writs) wanted more.
The banners still carry the author's Collegium device at ~112 px, where it resolves — the emblem
is present on the board, just not squeezed into a slot that can't hold it.

**Header height is zero-sum against the writs** (`live_bounds.h = board - header - bar`, split
across two rows), so removing the medallion's seat is a direct gift to the contracts: the writs
grew **93x54 → 93x67** (the pre-header board was 93x60 — the writs are now *larger* than before the
header existed). `board_header.png` **204x46 → 204x38** (title band + two rails, its floor);
`placard_rect` **204x65 → 204x38** (no top gap for a seat), hung at `inner.y*0.014`; the sign
`NinePatchRect` `sign_top` **19 → 0** (flush); 9-slice margins **36/13 → 36/11**;
`TOP_RESERVE_FRAC` **0.24 → 0.17**. `keepout live=8 ok=true minhit=93x67 hit_ok=true`.

**Retired.** `board_seal.png` (+ `.import`) is deleted; `gen_header.py` drops `seal_px`, the
`_device`/`_load_device` reader, the PIL import, and its `@consumes` edge — it is once again a
pure **surface** generator (grain, rails, forged straps), the half of the TD-057 split that always
stayed procedural. `art/src/collegium_device.aseprite` (+ `.lua`/`.png`) is left in place as source
art (outside `client/`, so not an asset-map orphan) — the hand-drawn device may be reused, and
deleting freshly-authored source art on a composition change would be premature. Client render +
generated art only (I1/I2 hold); no `src/**` change. Verified by `--board-preview` captures.

---

## TD-059

**The header + flanking banners are re-graded to BELONG in the torch-lit scene.** Author's review of
the TD-058 board: the sign is too light, and the banners are too bright, mis-placed (spilling off the
screen edge), smooth (LINEAR, not pixel art), and — the real tell — a **flat baked sprite the
torchlight never touches** while every other surface is normal-mapped and lit by the rig. Fixed on
all axes; client render + generated art only, spec `specs/board-blend/` (R177–R182, T188–T192).

**The banner (`gen_banner.py` rewrite, 180×360 → 64×176).**
- **Crisp pixel art + heavily tattered (R177).** Authored at ~display size, shown **NEAREST 1:1**
  (deterministic at the fixed 640×360 internal res — the TD-050 lesson). The clean geometric
  swallowtail is replaced by a **heavily worn foot**: a ragged per-column hem, a few worn-through
  **holes**, and sparse **loose threads** hanging past the hem — all alpha, so the torn cloth reads
  against the dark wall.
- **Dim + blended, subdued emblem (R178).** A darker, lower-contrast crimson ramp (the shader
  supplies fold warmth now, so the diffuse no longer bakes bright crests); the Collegium imprint
  pulled dim + desaturated at low alpha — a faint printed device in the banner's shadowed upper cloth,
  never the bright white sigil it was.
- **Lit by the torch rig (R179).** The banner is now a **normal-mapped surface**: `gen_banner.py`
  emits a companion `banner_v1_n.png` from its OWN height field (fold + creases + hem bump, Sobel →
  packed normal, flat where the cloth is transparent so torn gaps don't rake light), and the banner
  `Sprite2D` gets a `board_surface.gdshader` material fed by the same `torch_rig`. `--lights-off`
  falls to flat dim cloth — proof the brightness is the shader's, not baked.
- **Fully in the gutter (R180).** Display width `0.15·vp.x → 0.10·vp.x`, centred at `GUTTER_CX`
  (0.065) — the board frame's outer edge is at 0.13·vp.x and the gutter centre is its midpoint, so the
  banner spans ~`[0.015, 0.115]·vp.x`, clear of the screen edge and the frame. Supersedes TD-052's
  "off-screen overflow OK". `GUTTER_CX`, `torch_rig`, sconce + flame untouched (P95).

**One reach knob, not a second light.** The board's torch halo is deliberately tight (radius 0.24,
TD-048 dungeon re-grade) so the wall stays dark; the banner hangs *above* its foot sconce, so at 0.24
the throw dies before it climbs the cloth and the "torch-lit banner" reads as flat. `_surface_material`
grows one optional **`radius_scale`** (default 1.0 — every existing surface unchanged); the banner
passes ≈2.4, widening only ITS per-torch reach so the ember warmth climbs into the tattered foot and
fades to ambient dark up top. Same rig positions/colours/coupling — a per-material render choice, not
a new light (P102).

**The header (`gen_header.py` tone).** `WALNUT` deepened (50,39,30 → 38,29,22) and the wood→walnut
blend raised (0.46 → 0.56), so the sign **recedes** into the near-black board — "darker but not so
much". The gilt title is drawn in Godot; a darker ground only *raises* its contrast, so legibility
improves (P105). Geometry (`placard_rect`, `TOP_RESERVE_FRAC`, the writs) is unchanged — a tone pass
only.

Containment: no `src/server`/`src/shared` change, no game logic (I1/I2). `asset-map.md` regenerated
(new `banner_v1_n.png` producer edge; the gen_normals `%s_n.png` glob also matches it — a benign
scanner false-positive, not a real double-write). Verified by `--board-preview` + `--lights-off`
captures.

**TD-059b (author review — banner placement).** The first cut placed the banner at the gutter
midpoint (`GUTTER_CX` 0.065) at `0.10·vp` wide, on the assumption the frame's outer edge sat at
0.13·vp. Measured from a capture, the carved frame texture extends ~52px proud of its inner content,
so its real outer edge is at **≈0.09·vp** — the gutter is *narrower than the banner*, and the banner's
inner edge butted right against the board (~6px). Fixed by pushing the whole assembly **outward**:
`GUTTER_CX` **0.065 → 0.036** and banner width **0.10 → 0.078·vp**. The banner's inner edge now clears
the frame with a visible gutter gap, the emblem stays fully on-screen, and the outer edge spills a few
px off-screen (viewport clips — author OK'd "overlap outside the view, just not the board"). Moving
`GUTTER_CX` slides banner + sconce + flame + the banner's own light + the wall hotspot together (what
it couples, P95) to the *outer* gutter — which matches the standing "banner at the OUTER edge of the
masonry gutter" note. Mirrored on both flanks. Measured post-fix: left banner right edge ~93px vs
frame ~114px (gap ~21px); right symmetric.

**TD-059c (author review — larger + lowered).** The banner is grown (width `0.078 → 0.095·vp`, and
proportionally taller; the height budget lifted `0.52 → 0.60·vp.y` so the taller cloth still ends its
foot above the sconce cup) and its top lowered (`banner_top` `0.012 → 0.06·vp.y`) so it no longer
lines up with the board's top edge. To grow WITHOUT re-touching the board, the centre walks further
out (`GUTTER_CX` `0.036 → 0.028`): the inner edge stays pinned clear of the frame (~97px vs frame
~114px) while the extra width + the shift spill the outer edge further off-screen (viewport clips —
"overlap outside the view, just not the board"), the emblem staying on-screen. Same coupling (P95).

**TD-059d (placard joins the lighting model).** The header sign was the last board object still drawn
as a flat baked `NinePatchRect` on a shader-lit wall, so it read as pasted-on/self-lit. It now takes
the same `board_surface.gdshader` material as the wall/frame/backing/banner: `gen_header.py` emits a
companion `board_header_n.png` from an explicit height field (raised straps + domed bolts, top rail,
routed bottom-rail channel, outer bevel → Sobel normal), and the sign is given `_surface_material`
(the shadow copy stays a flat black silhouette). The header is top-centre and the sconces are
bottom-corner (~1.0 uv away — unreachable by any sane radius), so "lit by the scene" here means
*rendered by the same cool-ambient/falloff model as the wall* (`ambient_tint ≈ 0.82,0.85,0.95`), which
is exactly the cool-dark the top of the frame beside it already sits in — not literally warmed by a
torch. `--lights-off` is ~unchanged (ambient-dominated), the honest tell that the placard is in the
lighting pipeline rather than baking a phantom highlight. The gilt title is a separate Godot Label, so
the wood tone is free to match the scene without touching legibility. R183/P106/T193; client render +
generated art only.

**TD-059e (author review — torch decoupled from the banner).** TD-059b/c walked `GUTTER_CX` to the
outer gutter for *banner placement* — but `GUTTER_CX` was also the torch coupling, so the sconce,
flame, and the one shader light rode out with it (~74px off the frame). The carved frame edge then
read as lit by a disconnected mid-side glow with the visible flame nowhere near it — the light and
its diegetic source had come apart. Fixed by splitting the constant: **`GUTTER_CX`** (0.028/0.972)
is now *banner placement only*, and a new **`TORCH_CX`** (0.072/0.928) — inboard, in the gap between
banner and frame — is what the sconce, flame, AND `torch_rig` (hence every `board_surface.gdshader`
consumer) read. P95's real invariant survives re-homed: the visible fixture and the shader light
still share ONE constant and can never desync; what changed is that the *banner* is no longer part
of that coupling. The flame now sits beside the carved frame and visibly lights it; the banner still
catches the climb of the same rig (radius_scale 2.4, measured symmetric L/R). Verified by
`--board-preview` + `--lights-off` captures (lights-off drops the wall/banner warmth to flat dim —
the rig, not baked art, is the light). Client render only; one file (`board_decor.gd`).

**TD-059f (author review — sconce centred in the wall gutter).** TD-059e's first inboard value
(`TORCH_CX` 0.072) parked the fixture against the carved frame's outer edge (≈0.09·vp). The author
wants the sconce hanging in the middle of the visible wall, not leaning on the board — so `TORCH_CX`
moves to the wall gutter's centre (screen edge → frame ≈ 0.09·vp ⇒ **0.045/0.955**). Same split as
TD-059e (banner placement stays `GUTTER_CX`; sconce + flame + `torch_rig` all read `TORCH_CX`, P95
re-homed); the glow still reaches the frame edge and the banner foot. Capture-verified. Client render
only; one constant.

## 2026-07-21 — TD-060: the writ reads creature-at-place; the Origin wax seal is archived; the leader stamps the Collegium's seal

**Context (author playtest review).** The board's compact writ read "location at <location>" ("The
Hollow Hamlet / at Ashen Hollow") — because the `--board-preview` fixture's `targetName`s were
PLACES, misrepresenting the real wire format (the server's pool is Incarnate epithets: "The Ashen
Warden at The Salt Marsh"). And the asserted-Origin wax seal earned no keep on the contract: the
petition-type badge already carries the glanceable read, and wax pressed over "Sin" asserted a
certainty the Collegium doesn't have — the Origin is a falsifiable claim, prose, not a stamp.

**Decision (`specs/writ-format/`, R184–R188, T195–T199).**
- **Format:** the canonical writ is **Incarnate at Site**. The fixture's eight targets re-authored
  as epithets; the server's authored `TARGET_NAMES`/`SITE_NAMES` pools grew 4 → 10 each so the
  8-writ board isn't forced into duplicates (content tables only; `rng.pick` unchanged, I3 holds;
  test mirrors updated — server 362 green).
- **Origin seal retired:** the writ's corner seal and the reader's seal are gone (writ corner =
  tack + petition-type badge; reader Origin row = text-only "Asserted <Origin>: <gloss>"). The
  painter + PNGs are **archived** at `art/archive/` (gen_origin_seals.py + seal_belief/sin/relic
  .png); `gen_emblems.py` no longer emits them.
- **The leader's stamp is generic:** `wax_seal.gd` is now the ONE Collegium seal — oxblood wax,
  the order's device debossed (`seal_collegium.png`, PIL-read from `collegium_logo.png`, the
  gen_banner producer-edge pattern). The R124/TD-041 mechanic is untouched: faint until stamped,
  firm once sealed, leader-only, `SELECT_CONTRACT`/`DESELECT_CONTRACT`, affordance ≠ authority.
- **Capture hardening (debug-only):** `--reader` suppresses the reader's click-off dismiss (the
  stray-click gotcha kept toggling it closed mid-capture), `--reader-foot` pins the reader scroll
  to the foot, `--sealed` sets the fixture contract — so unattended captures can verify the seal
  block in both states without input injection.

Verified by captures: 8 writs each "<epithet> / at <place>", no Origin seal anywhere; reader shows
the faint Collegium seal ("Awaiting the leader's seal.") and firm under `--sealed` ("Sealed. The
charge is taken up."). Diff scope: client/art/specs/docs/CLAUDE.md + the two server content tables
(+mirrors). Server 362 + shared 65 green; asset-map regenerated (`seal_collegium.png` edge in, the
three retired edges out).

**TD-060a (author playtest — reader containment + over-scroll dismiss).** Two reader defects from
live play: (1) scrolled writ text rode up over the torn parchment edge and past the sheet — the
`ScrollContainer` spanned the reader's full rect with the padding INSIDE the scrolled content, so
the clip boundary was the sheet's outermost edge; the scroll is now inset to the intact parchment
centre (offsets 34/30, explicit `clip_contents`, pad reduced so the at-rest position is unchanged).
(2) Scrolling at/past the scroll limit closed the reader — wheel ticks are `InputEventMouseButton`
(WHEEL_UP/DOWN, pressed), and both click-off dismiss handlers (`_popup_dim` + the reader's dim)
fired on ANY pressed mouse-button event; both now require `MOUSE_BUTTON_LEFT`. R189/T200;
capture-verified (foot-pinned title clips cleanly inside the sheet; live wheel during capture
scrolled the writ without closing it). Client render only.

## 2026-07-21 — TD-061: pips retired for the petitioner's dread; fitted non-uniform writs; the quill-line scrollbar

**Context (author playtest review).** Three asks: the threat pips contradicted "no knowledge as a
number" on the Collegium's own paperwork; long site names ("at Hollowmere Crossing") overflowed the
compact writ; and the reader wanted its text to consume the sheet, with the scrollbar moved OUTSIDE
the parchment and restyled to the author's ornament reference (thin line, dot finials, diamond
thumb). Author rulings: threat survives only as prose; the ornament is interactive; writs are
deliberately NON-uniform ("the variability and uniqueness of each contract"), spacing still solved.

**Decision (`specs/contract-reader/`, R190–R195, T201–T206).**
- **Pips out, dread in:** `threat_pips.gd` deleted (git history is the archive); the reader's
  threat row is replaced by `Notice.plea(intel)` — one seeded sentence in the petitioner's voice,
  banded by tier (APPRENTICE routine → MASTER frightened). Chosen for immersion: the player weighs
  the fear in a person's words, never a meter; high charges need no label because the dread does
  the work (P110). `tier` stays wire intel for generation only.
- **Content-fitted writs (P111 — measure == render):** the grid cell is now only the disjoint
  CEILING; each writ takes a seeded width and a height measured from its own text with the same
  font/sizes/wrap the labels render (`ThemeDB.fallback_font` — no custom default font), plus
  furniture headroom and seeded slack; fonts step down one size (9/7 → 8/6) if a cell can't hold
  the block. Non-uniform on purpose; `keepout ok=true minhit=80x51 hit_ok=true`.
- **The sheet consumed + the quill-line scrollbar:** reader insets 34/30 → 26/22 (pad 8), internal
  scrollbar retired (`SHOW_NEVER`; `_style_scrollbar` deleted), prose column widened 394 → 418. New
  `ornament_scrollbar.gd` — the author's reference drawn in aged brass/gilt: a thin line with dot
  finials and a chevroned diamond lozenge thumb, riding OUTSIDE the sheet in an HBox beside the
  reader; interactive (drag + track-jump), both-ways sync via the scroll's VScrollBar signals,
  auto-hidden when the writ fits (P112). Gotcha for posterity: `attach()` first assigned
  `custom_minimum_size` whole, clobbering the caller's height and collapsing the line to zero span
  — set only the width floor in a control the caller sizes.

Client render only; no `src/**` change (server 362 + shared 65 green untouched this session).
Capture-verified: varied writs all fitting, plea in place of pips, wider reader text cleanly
clipped (R189 holds), ornament tracking top/foot — live wheel input during captures mirrored into
the ornament, confirming the sync from the author's own hand.

## 2026-07-21 — TD-062: the seal rite — exact writ fit, the round seal, the leader's oath, the stamp ceremony

**Context (author playtest review of TD-061).** Long texts STILL clipped the writ foot ("at The
Gall Road Ossuary" lost "Ossuary"); the wax seal stretched into an oval; the seal captions were dry
UI instructions; stamping reset the reader's scroll to the top; and the stamp deserved ceremony.
Author rulings: the **named-target oath**; instructions demoted to hover tooltips; **press + wax
flash** animation.

**Decision (`specs/seal-rite/`, R196–R201, T207–T212).**
- **The missing 3px (P113):** Godot Labels insert the theme `line_spacing` (3px) BETWEEN wrapped
  lines; `Font.get_multiline_string_size` doesn't count it, so two 2-line blocks under-measured by
  ~6px — exactly the clipped "Ossuary". `_fit_writ` now adds it per wrapped line (+2 safety), and
  the preview fixture adopts the longest authored server sites so the failure stays capturable.
- **Round seal (R197):** `wax_seal.gd` draws a centred SQUARE (min dimension) whatever rect the
  container hands it — the oval came from filling a taller-than-wide control.
- **The oath (R198):** leader unsealed — "I, <name>, take up the charge against <target>. Let it
  be witnessed."; sealed — "It is witnessed. <target> is ours to answer."; non-leaders keep the
  party forms. How-to lives in `tooltip_text` (themed TooltipPanel/TooltipLabel — near-black warm
  panel, brass hairline, parchment text). `_board_preview` seeds a fixture leader ("Aldric",
  `_self_id = "pv-self"`) so the oath is capturable.
- **Scroll continuity (R199/P114):** `_reader_open_cid` + `_reader_scroll_mem`; a same-notice
  snapshot rebuild (stamp/lift) restores the offset, a fresh open pins the headline, close clears;
  `_reset_reader_scroll` generalised to a target (the `--reader-foot` debug pin rides it); the
  scrollbar feeds the memory only after the settle frames.
- **The ceremony (R200/P115):** `_seal_prev` detects the faint↔firm flip across rebuilds;
  `_animate_seal` plays the press (drop 1.8→1.0 ease-in, squash 1.18/0.85, an additive
  `backlight_gradient` flash blooming on impact, the sheet thumping 2px) or the peel (firm wax
  rises + fades, settles faint). Reduced-motion renders end states only. Pure theatre: no state,
  no message (P66 untouched).

Client render only; suites untouched-green; capture-verified (long sites whole at
`keepout ok=true minhit=80x53`; round seal both states; oath unsealed/sealed); scroll + animation
verified by author playtest.

## 2026-07-21 — TD-063: the seal ceremony — pressed pixel wax, the empty socket, the slow press, CONTRACT SEALED

**Context (author playtest review of TD-062).** The press was too fast; the animation displaced the
caption (the wax flash was childed to the HBOX ROW, so layout shoved the seal + caption sideways —
and the sheet-thump moved the prose vertically); the faint ring sat off-centre (the disc was
off-centre in its texture), too opaque, and wanted broken lines with the ghost wax gone; the
stamped wax wanted pressure-deformed edges and crisper pixels; and the stamp wanted a souls-like
banner. Author rulings: dashed-socket-only unsealed state; deformed pixel wax; banner reads
**CONTRACT SEALED** + target subline, **party-wide**, **replacing** the stamp toast (lift keeps the
quiet toast).

**Decision (`specs/seal-ceremony/`, R202–R206, T213–T217).**
- **Pressed pixel wax (R202):** `make_collegium_seal` re-authored at SS=1 (hard pixels): an
  irregular rim from 3 seeded squeeze-out lobes + per-angle jitter + a pressed-ellipse bias (a
  stamp never leaves a perfect circle), a raised bulge band of displaced wax around a flattened
  pressed field, the device debossed with a lit lip, 4-band POSTERIZED shading, a hard-stepped
  contact shadow; disc centred so overlays align.
- **The empty socket (R203):** `wax_seal.gd` faint = a centred dashed circle (12 arcs, alpha 0.30)
  and nothing else — ghost wax + solid ring retired; firm = the full texture. The off-centre-ring
  bug died with the ghost.
- **The slow heavy press (R204/P116):** hover 0.10s → cubic fall 0.30s → squash (1.22, 0.80) →
  BACK settle 0.28s (~0.82s total; lift 0.28s). The flash now lives under the SEAL's own subtree
  (`show_behind_parent`) and the sheet-thump is REMOVED — nothing outside the seal moves; captions
  render at identical geometry in both end states (capture-checked).
- **CONTRACT SEALED (R205/P117):** `_show_rite_banner` — a wide dark gradient band at 0.38·vp,
  gilt letter-spaced Cinzel "CONTRACT SEALED" (outlined) over the target subline; fade 0.30 / hold
  1.30 / fade 0.60, freeing itself; reduced-motion shows it statically. `CONTRACT_SELECTION
  accepted=true` now raises the banner for every room member from the one broadcast and the stamp
  toast is gone; `accepted=false` keeps the lift toast; errors untouched. Debug `--rite-banner`
  previews it for captures.

Client render + generated art only; suites untouched-green; capture-verified (pressed wax, dashed
socket, identical caption geometry, banner at hold); press weight + party-wide banner for author
playtest.

## 2026-07-21 — TD-064: seal polish — unclipped flash, hitch-free rebuild, stamp cooldown

**Context (author playtest review of TD-063).** Three defects: (1) the wax flash was clipped to the
sheet — it was a child of the seal, which lives inside the reader's `ScrollContainer`
(`clip_contents`), so its radius was trapped and it read as an awkward glow pinned to the writ's
lower-left; (2) a brief stutter on stamp/lift — the whole popup rebuilt and regenerated its board
textures synchronously as the animation began; (3) stamping/lifting could be spam-clicked.

**Decision (`specs/seal-polish/`, R207–R210, T218–T221).**
- **Flash on an overlay (R207):** `_spawn_seal_flash` draws the impact bloom on a dedicated
  `CanvasLayer` (layer 95, above the popup/reader), centred on the seal's on-screen position via
  `get_global_transform_with_canvas() * (seal.size*0.5)` (correct in the `canvas_items`/PixelScale
  logical space). It is independent of the seal's lifecycle (a rebuild that frees the seal leaves
  the bloom to finish and free its own layer). The core is overdriven warm (>1) so the additive
  burst reads even over the bright parchment, sized to bloom past the sheet edge without flooding.
  The seal's own drop/squash/settle is unchanged (P116 preserved). Debug `--flash-preview`.
- **Hitch-free rebuild (R208/P118):** `BoardGeo`'s five deterministic generators
  (`wood_grain_texture` — a 96×96 GDScript pixel loop — plus `vignette`/`curl`/`backlight`
  gradients and `additive_material`) are memoized in static caches, built once per process and
  reused by reference. Immutable, render-only, identical to the freshly-built result; the
  per-rebuild regeneration that caused the hitch is gone.
- **Stamp cooldown (R209/P119):** `SEAL_COOLDOWN_MS = 900` (≈ the 0.82 s press). On stamp/lift the
  seal is disabled and `_seal_cooldown_until` is set; a block rebuilt during the window stays
  disabled and schedules its own re-enable timer. Affordance only — the server still authorises; a
  raced `NOT_*`/`WRONG_PHASE` still surfaces; non-leaders unaffected.

Client render only; no `src/**` change; suites untouched-green; capture-verified (unclipped
contained flash, board visually identical under the cache); press-smoothness + cooldown for author
playtest.

## 2026-07-21 — TD-065: seal refresh — targeted reader update + robust cooldown

**Context (author playtest of TD-064).** Two defects survived: the seal couldn't be re-stamped/lifted
after the first stamp until the contract was closed and reopened, and the stutter persisted.

**Root causes (verified in code).**
- *Stuck cooldown:* the re-enable timer ran for `cool_left/1000 s` measured AFTER the ~round-trip, so
  it fired a few ms BEFORE `_seal_cooldown_until`; the strict `now >= _seal_cooldown_until` recheck
  then failed and never retried — disabled until a fresh open.
- *Stutter:* every stamp/lift ran a full `_build_contract_board` — which calls `BoardDecor.add_torches`
  (frees + recreates 2 sconces, 2 CPUParticles flames, 2 glows, 2 banner sprites) and rebuilds all 8
  notices + the reader. The TD-064 texture memoization didn't touch that node churn.

**Decision (`specs/seal-refresh/`, R211–R213, T222–T224).**
- **Targeted reader refresh (R211/P120):** the reader's dim + row are wrapped in one named
  `ReaderOverlay`; `_build_contract_board` remembers `_board_canvas`. On `LOBBY_UPDATED` while a notice
  is OPEN (the only state a stamp happens in), `_refresh_open_reader()` frees just the overlay and
  re-shows the reader — the board notices, backing, decay, and **torches are untouched** (`add_torches`
  is never called), so there is no hitch. Seal state, the stamp/lift animation, the CONTRACT SEALED
  banner, and scroll continuity all ride the refresh. Grid view (a ready-toggle/join) keeps the full
  rebuild.
- **Robust cooldown (R212/P121):** the real spam guard is a hard time-check in the click handler
  (`if now < _seal_cooldown_until: return`) — independent of the button's disabled state, so it can
  neither be defeated nor stick. The visual disable in `_seal_block` now always re-enables via an
  unconditional buffered timer (`cool_left/1000 + 0.08 s`, `is_instance_valid` only — the strict
  deadline recheck that missed by a frame is gone). The server remains the authority (P66).

Client render only; no `src/**` change; suites untouched-green; both reader states render correctly
through the wrapper; smoothness + re-stampability by author playtest.

## 2026-07-21 — TD-066: code-structure canon (`.claude/rules/code-structure.md`)

Established a structure canon so the project stays readable, maintainable, and scalable as it grows.
Author rulings (this session): write the **canon doc only** now (decompose incrementally later),
target the **full** `main.gd` decomposition (a thin router + feature files), and prefer
**scene-per-feature** on the client (a module that owns a node subtree becomes its own `.tscn`+`.gd`,
instanced + driven via methods, decoupled upward via signals; pure logic stays a preloaded
`RefCounted` namespace; cross-cutting services are autoloads; never a global `class_name`, TD-029/30).

Grounding (surveyed, not assumed): `src/server/` (49 files, one responsibility each, 51 colocated
test files) and `src/shared/` (13 files, types-only, honoring I4) are already exemplary and are named
as THE reference — do not restructure them. The one real violation is `client/scripts/main.gd`
(**2,684 lines, 98 funcs, 78 vars — 67% of all client GDScript**), a god-object spanning networking,
all six screens, the Contract Board, the reader, the seal, animations, theme, and helpers. The canon
codifies the proven patterns (S1 layers = the trust boundary; S2 one-responsibility-per-file, group
by domain; S3 scene-per-feature GDScript; S4 within-file order; S7 spec-workflow tie-in) and sets the
`main.gd` target + paydown rules (S5: new client features never enter `main.gd`; each extraction is
its own spec + commit + capture, behavior-preserving). Explicitly recorded honest framing: **file
structure is not a performance lever** (S6) — performance is architecture (the smallest-subtree-update
lesson of TD-065, the memoization of TD-064); and **security is the layer boundary**, reinforced by
keeping it a directory boundary. Wired into CLAUDE.md's rule includes. Docs/rules only; no code change.

## 2026-07-21 — TD-067: main.gd decomposition, tranche 1 (shared UI builders + rite banner)

The first extraction under the code-structure canon (TD-066). `client/scripts/main.gd` (2,684-line
god-object) begins paydown toward the S5 target (a thin router + feature files), incrementally, each
tranche behavior-preserving (a refactor, not a redesign — I1/I2 hold).

**Tranche 1 (`specs/main-decompose/`, R214–R220, T225–T228):** three stateless/transient builders
left `main.gd` for `client/scripts/ui/`, moved verbatim, call sites rewired, following the canon's
GDScript rules (preloaded `RefCounted` namespaces, never a global `class_name`, TD-029/30):
- `fonts.gd` — `Fonts.cinzel(weight)` (was `_cinzel`; consumers: `_engraved_line`, the banner).
- `popup_theme.gd` — `PopupTheme.build()` (was `_build_popup_theme` + private `_btn_box`).
- `rite_banner.gd` — `RiteBanner.show(host, title, sub, reduced_motion)` + `_band_gradient` (was
  `_show_rite_banner`/`_rite_band_gradient`); it owns a transient CanvasLayer overlay, so it follows
  the `BoardDecor.add_torches(host, …)` builds-on-a-passed-host idiom, not a persistent scene.

`main.gd` 2,684 → 2,538 lines (−146). Verified: headless parse clean; a `--board-preview` capture is
identical to the pre-change baseline by eye (Cinzel header, gothic popup frame + gold controls, scene
tooltip); a `--rite-banner` capture shows CONTRACT SEALED unchanged. (A pixel-diff is not a valid
equivalence test here — the board's live torch CPUParticles + glow flicker differ frame to frame
regardless of code; eyeball is the client-spec convention.) Asset-map regenerated (new `preload`
edges); diff scoped `client/ docs/ specs/`; server + shared suites untouched-green. Queued tranches
(their own commits): `ui/widgets.gd` (R217), `board/notice_reader.gd` (R218), `board/contract_board.gd`
(R219). Client render only; no `src/**` change.

## 2026-07-23 — TD-067: main.gd decomposition, tranche 2 (shared widget builders)

**Tranche 2 (`specs/main-decompose/`, R217, T229):** the shared render-only Control factories left
`main.gd` for `client/scripts/ui/widgets.gd`, moved verbatim, ~30 call sites rewired mechanically:
- `Widgets.card_label(text, size, color, wrap, center)` — the workhorse (20 refs across the notices,
  the reader, the seal caption, the legend bar, the empty-board state).
- `Widgets.hrule(color)`, `Widgets.focus_ring()` — the scribe's rule and the gilt Tab-focus stylebox.
- `Widgets.engraved_line(text, size, face_color, weight)` — the carved two-pass header lettering; it
  carries its own `const Fonts = preload(...)` rather than reaching back into `main.gd`.
- `Widgets.h1(host, text)` — the placeholder-screen heading. It appended to `_root`, so like
  `RiteBanner` it takes the **host** as its first argument (the builds-on-a-passed-host idiom) rather
  than becoming a node-owner; the five call sites pass `_root`.

`main.gd` 2,538 → 2,475 lines (−63); `widgets.gd` is 70. Verified: headless parse clean; a
`--board-preview` capture is composition-identical to a worktree build of HEAD (1c2204f) — same
engraved header, eight writs, hrules, seal caption, legend bar. Two deltas are visible and are
**nondeterministic run-to-run, not regressions**: the torch CPUParticles, and which live notice holds
hover-focus (a same-build control run moved the focus ring to a third card). A default `--capture`
confirms the menu `h1`. Asset-map regenerated + `--check` green; diff scoped `client/ docs/ specs/`;
server 362 + shared 65 green (untouched). Tranche 1's three `.uid` files (`fonts`/`popup_theme`/
`rite_banner`), missed in 1c2204f, are committed here — `.uid` is tracked for every other
`scripts/ui/*.gd`. Queued: `board/notice_reader.gd` (R218), `board/contract_board.gd` (R219).
Client render only; no `src/**` change.

## 2026-07-23 — TD-068: taking a writ down no longer rebuilds the Contract Board

Author playtest: opening a writ to read it, and putting it back, visibly re-renders the whole board.
This is the **same defect TD-065 fixed for the seal stamp**, still living on the open/close path —
TD-065 carved out the stamp (`_refresh_open_reader`, P120) and explicitly left this ("Grid-view
updates keep the full rebuild").

`_select_board_card` cross-faded into a full `_rebuild_popup_body`, so every take-down and every
return re-ran: a fresh canvas + plank NinePatch with a new ShaderMaterial, `BoardGeo.layout_live`
plus **`_fit_writ` per writ** (font metrics + wrap measuring + the step-down search), 8 ×
(backlight + cast shadow + notice subtree), the decay, vignette, legend bar, placard, and
**`add_torches`' CPUParticles**.

**The insight (`specs/reader-swap/`, R221–R223, T232–T235):** `_board_selection` reaches the board in
only two places — the reader overlay itself, and `_make_live_notice`'s `sel`. The second is **inert**:
"the taken-down writ hangs straight" is overwritten two lines later by the placement
`rotation_degrees = tilt`, and the 1.03 rest scale cannot fire while the reader's dim owns the mouse.
So a rebuild always yields *seeded lean, scale 1.0*, and everything else it produces is a pure
function of the snapshot + viewport, which a selection does not change. The board was pure waste.

Open/close now swaps only the `ReaderOverlay` (which TD-065 had already made self-contained):
- `_reset_notice_transforms()` puts the surviving writs back exactly as a rebuild left them, from a
  new `tilt` meta — needed because a card is hover-lifted (1.05) at the instant it is clicked and the
  old path discarded that node. `_hover_card` now tracks its tween in a meta and kills the previous
  one, so an in-flight lift cannot animate over the direct scale write.
- `_retire_reader_overlay` renames a closing overlay and makes it click-through before fading it, so
  a dying overlay is never returned by the next `find_child("ReaderOverlay")` and its dim never
  swallows a board click mid-fade.
- The 0.12s/0.07s fades move onto the **overlay alone**, so the board behind no longer blinks out.
- A non-board popup or a missing `_board_canvas` still falls back to the full rebuild — a fast path,
  never the only path.

Measured (P123): `--board-preview --reader` logs `board live=` **once**, where HEAD logged it twice;
a new `--reader-cycle` (take down *and* return in one unattended run) also logs it once. The reader
capture is identical to a stashed pre-change build **inside the sheet** — 0 differing px; all 14,073
differing px sit in the two torch gutters (x<160 / x>1120), where the flame particles vary run to
run regardless of code. The post-return capture shows the wall intact: eight writs at their leans,
none swollen, focus reticle back on the first writ.

Left alone on purpose: the inert `if sel: rotation_degrees = 0.0`. Making the straighten actually
work is a *visible* change, not this spec's business — flagged for a deliberate decision. When
`board/notice_reader.gd` is extracted (T230/R218) it must inherit this fast path, not re-introduce
the rebuild. Client render only; no `src/**` change; server 362 + shared 65 green (untouched).

## 2026-07-23 — TD-069: client scripts and assets grouped by feature

Author request: make the client tree scalable — a Contract Board should own a folder, not scatter
across a flat pile, "for other features as well." This is the code-structure canon's S2.2
("group by feature/domain, not by mechanical type") applied to the two places that still read as
type-piles. Pure relocation: no behavior change, no code logic touched.

**Scripts** — to the S5 target tree. `scripts/` was flat, and `scripts/ui/` had quietly become
"everything the board needs":

```
scripts/core/    pixel_scale.gd, debug_capture.gd (autoloads), catalog.gd
scripts/world/   player.gd, space_view.gd
scripts/board/   board_bar, board_decor, board_geometry, notice, ornament_scrollbar,
                 verb_badge, wax_seal
scripts/ui/      fonts, popup_theme, rite_banner, widgets   ← genuinely shared, now honestly so
scripts/         main.gd, net.gd
```

File names kept as-is (`board/board_geometry.gd`, not `board/geometry.gd`): S5 lists them that way,
and renaming while moving would double the diff for no gain.

**Assets** — `client/assets/ui/` was 58 files deep in one directory:

```
assets/ui/board/    all Contract Board art (frame, backing, banner, header, parchment,
                    tacks, badges, torches, seal, decay, board_surface.gdshader)
assets/ui/shared/   panel.png (the popup 9-slice every station wears)
assets/ui/_src/     reference/source art (_proto_board, _frame_v1_src, _slices/)
assets/ui/          the generators only — ashember.py, pngio.py, gen_*.py
```

Generators keep **literal** relative output paths (`A.write_png("board/banner_v1.png", …)`) rather
than a computed root, because `tools/asset_map.py` derives producer edges from those literals — a
clever path helper would have silently deleted half the map's edges. Where a generator already
centralised its output (`_out(name)`, `os.path.join(HERE, name)`, `OUT`), only that one line moved.

Two gotchas worth remembering, both now in `dev-environment.md` §7:
- Moving a `class_name` script invalidates `.godot/global_script_class_cache.cfg` (keyed by path):
  first `Class "Player" hides a global script class`, then after a naive cache delete,
  `Identifier "Catalog" not declared`. Delete the cache and run `--import` (twice, for autoloads).
- Moved PNGs need their `.import` regenerated; `dest_files` embeds a path hash.

**Found along the way:** `tools/asset_map.py --selftest` had been **red since TD-058** — it still
asserted `board_seal.png` is produced/consumed, an asset TD-058 deleted. The named test of TD-051
was failing and nothing caught it. Re-pinned to current wiring (`board/board_header.png`) and the
moved paths; green now. This is the argument for running `--selftest`, not just `--check`, since
`--check` only compares the map to itself.

Verified: headless parse clean; `--board-preview` renders the board identically across `--reader`,
`--reader-cycle`, `--sealed`, `--rite-banner`, `--board-empty` with **no errors or warnings**
(case-insensitively grepped this time) and `board live=` once per run, so TD-068 still holds; five
generators re-run and reproduced **byte-identical** art from the new paths; `--selftest` and
`--check` green; no dangling references. Client only; no `src/**` change.

## 2026-07-23 — TD-070: dead generated art deleted; the orphan signal made trustworthy

Author request: delete unused generated assets so the Godot FileSystem dock is clean.

**Deleted (10 files + their `.import`), all generated and genuinely unreferenced:**
- `board/parch_live_{0,1}.png` + the four baked ±5° tilts `parch_live_{0,1}_{l,r}.png` — superseded
  by `parch_v1_*` (which `main.gd` loads) and by runtime rotation in `_place`. Note the trap: the
  `_parch_live` **variable** in `main.gd` holds `parch_v1_*`, not these files.
- `board/foxing.png` — the foxing look lives in `ramp_shade("foxing", …)` passes, not an overlay.
- `board/board_placard.png` — superseded by `board_header` (TD-053/TD-058).
- `board/wall_v1.png` + `board/wall_v1_n.png` — a fully dead chain: the only reader of `wall_v1.png`
  was `gen_normals`, deriving a normal map nothing renders.

The emitting generators were edited too (`gen_detail`, `gen_structure`, `gen_normals`), otherwise the
next run resurrects everything. `gen_structure` was additionally emitting `board_frame.png` and
`board_backing.png`, superseded by `frame_v1`/`backing_v1` — it had been re-littering dead art on
every run. All seven generators were re-run afterwards: nothing reappeared and **no live art byte
changed**.

**Kept, despite being listed as orphans** — the list was wrong, which is the more important finding:
- `assets/tiles/tiles.png` — referenced by `tiles.tres`, which `space_view.tscn` loads. Deleting it
  on the map's advice would have broken the field tilemap.
- `_src/_frame_v1_src.png` — the preserved **painted** frame source `gen_normals` re-derives from.
  Deleting it makes the generator copy its own regenerated output as "source", losing the original.
- `_src/_slices/paper_band1.png` — the paper band `gen_parch_v1` samples for every live writ.
- `board/collegium_logo.png` — the canonical emblem, read by `gen_banner` + `gen_emblems` via PIL.
- `_src/_proto_board.png` — the Prototype v1 reference the paper band was sliced from.

**So `tools/asset_map.py` was fixed, not just consulted.** Its Orphans section only knew about
`load`/`preload`/`ext_resource`/`write_png`, so it was blind to two whole edge kinds and listed five
load-bearing files as dead art:
- `.tres` resources are now scanned for `ext_resource` (previously only `.tscn`, and only under
  `scenes/` — `tiles.tres` sits beside its atlas in `assets/tiles/`).
- Generator **reads** are now edges: `.png` literals at real read call-sites (`read_png`,
  `_load_luma`, `copyfile`, `Image.open`) plus module constants like `EMB_SRC`. Anchored to call
  sites rather than any literal so a docstring listing a generator's *outputs* is not mistaken for a
  dependency; a generator reading back its own output is excluded. Templated reads glob the same way
  templated writes always have, so `_load_luma("board/%s.png" % name)` over-reports its readers —
  the same known looseness the write side has, not a new one.

Result: **orphans: none, dangling: none** — the section now means something. Verified: `--selftest`
and `--check` green; headless parse clean; board renders identically across `--reader-cycle`,
`--reader` and `--board-empty` with no errors. Client + tooling only; no `src/**` change.

## 2026-07-23 — TD-071 Phase D: the title screen is a held image, outside the Hall of Petitions

Author redesign, mid-spec: the title screen becomes **minimalist and contemplative** — no
characters, no combat, no monsters, no explosions. A solemn, sacred space. Choosing an option then
takes the player into the **Hall of Petitions**, where they take control of their Seeker. The rhythm
the game gains: **contemplation → preparation → expedition → the unknown.**

This is not only taste, and the strongest argument is canonical: a title screen showing an Incarnate
would **leak the mystery the game is built on** (Pillar 3 — understood through interpretation, never
memorization), teaching a player what a Manifestation looks like before they read a single sign. And
combat imagery would advertise the *failure* state, since the order's aims are witness, contain,
redeem and killing is "a failure of understanding, not a trophy". The quiet screen is the canonical
one, not merely the pretty one.

**Rulings.** The image is **the empty nave**. There is **no "Continue"** — the ways in are **New
Expedition** and **Join Expedition**, with **Return to your expedition** listed first and only when
a reconnect token exists. "Continue" was rejected on the author's call, which also removed a lie the
first draft would have shipped: canon I7 keeps expedition state ephemeral, so there is no save to
load — only a still-live expedition to rejoin. This supersedes the earlier "keep functional terms"
ruling **on the title screen**; `Room code` stays the field's name where a code is actually typed,
and Create Room / Join Room stay on the room-setup plate one screen deeper.

**Built (R231–R234, P126, T244–T248):**
- `gen_nave.py` → `assets/ui/title/nave.png`, 640×360. A **real one-point corridor projection** —
  every pixel ray-cast from the vanishing point to floor / vault / arcade / far wall with a depth
  `t` driving perspective spacing. Two drafts were thrown away first and are worth recording: a
  *vertical* shaft read as a flame or a laser rather than as light through a window, and flat
  vertical piers read as a fence, because the first attempt faked perspective instead of projecting
  it. Ordered 4×4 dithering was needed because a 5-step stone ramp turns a smooth falloff into
  visible contour rings.
- `Screen.TITLE`, booted into. Gilt Cinzel options with no button chrome; no name field, no code
  field, **no status line** — it is an image and a short list of ways in (P126: the title emits only
  `RECONNECT`, and only from Return; New/Join are pure navigation).
- `_fit_nave()` draws the plate at the largest **integer** multiple that fits, centred, with a
  ColorRect filling the remainder in the plate's own black. The first version used
  `STRETCH_KEEP_ASPECT_CENTERED` and scaled 1.44× at 1920×1080, softening the pixel grid the whole
  project rests on (TD-042).
- `_show_room_setup(mode)` one screen deeper: **New Expedition** asks only for a name, **Join
  Expedition** for name + Room code, both on the Phase B plate with **Back**. Phase B is reused, not
  discarded.
- **Hall of Petitions** enters `docs/GLOSSARY.md`. Not an invention: the fiction had already
  converged on it — `PETITION TYPES` on the board bar, *"No petitions stand before the Collegium"*,
  the signing **petitioner**, and "the hall" in `specs/collegium/`.

Debug: `--title-preview` (+ `--no-token`), `--setup-create`, `--setup-join`. `--no-token` **clears**
a real saved token rather than merely skipping the seeded one — the first version still showed
Return because a live `reconnect-token.txt` was on disk. Verified: parse clean; title captured at
1280×720 and 1920×1080; both setup plates captured; lobby + board unchanged and error-free;
asset-map `--selftest`/`--check` green (the generator writes a **literal** relative path, per canon
S5b, or the scanner drops nave.png's producer edge). Client + generated art only; no `src/**` change.

## 2026-07-23 — TD-073: the title screen is a layered scene; the concept art is reference only

Three approaches were tried for this screen. Recording all three, because the failures are the
useful part.

1. **A single procedurally generated plate** (TD-072). Four passes. It hit a structural ceiling: a
   per-pixel classifier with analytic shapes yields perfect symmetry, uniform repetition, hard
   edges and banded falloff, while the target is a painting whose quality comes from thousands of
   individually judged decisions. The clearest symptom was a drawn flame failing four times (box →
   cone → ball → box): at a few pixels a shape function cannot decide *which* pixel is the flame —
   exactly the finding TD-057 already recorded for the 17×22 medallion device.
2. **The concept art as a matte background.** Shipped three times on a misreading: the author's
   direction said "matte-painted background" and it was read as *the reference image itself*. It
   also forced inpainting the baked-in UI, which smeared (80 rows of vertical interpolation reads
   as vertical streaks at full resolution), and doubled the emblem where the painted device and the
   UI-rendered one overlapped. The author's verdict was "uncanny", and then explicitly: do not use
   the PNG as the main menu.
3. **A layered scene, blocked out** — the direction taken. `art/src/collegium_hall_src.png` is kept
   as a **composition reference only**: never shipped, never displayed.

**What shipped.** `ui/title_scene.gd` builds every layer as an independent node in its real
position, at its real size, with its real animation, rendering a **labelled blockout** until its art
exists. Art is loaded by exact filename and a missing file degrades to a placeholder rather than
erroring, so composition, lighting, motion and menu flow are reviewable now and real art drops in
with **no code change**. That is the load-bearing property: it decouples the engineering from art
delivery, whoever ends up authoring it.

Layers: architecture (static); cloth (slow sway); hanging props (pendulum, randomized phase);
vessels; overlays (drift/breathe); seven fires each with a warm additive pool flickering out of
step (`Light2D` cannot reach Control nodes — TD-047, the ruling that produced
`board_surface.gdshader`); real `CPUParticles2D` dust, embers and incense; and a camera life of 2px
idle drift with a 1.004 breathing zoom. Every animation is a looping tween, so nothing needs
`_process` and the rig frees with its node. F9 reduced-motion skips all of it and leaves a
**fully lit** still frame — verified by capture, not asserted.

`specs/title-scene/asset-manifest.md` carries the asset list with per-item prompts and the
constraints that make pieces composite first time: one shared camera, true alpha, no baked UI, and
**no baked flames** (fire is generated in-engine so each flickers independently).

Bugs worth remembering: a canvas_item shader's `COLOR` already holds `texture(TEXTURE,UV) ×
modulate` on entry to `fragment()`, so a trailing `* COLOR` squares the image (measured: 4× too
dark, isolated by capturing with the shader off and diffing pixels); and `CPUParticles2D`'s
`scale_amount` multiplies the source texture, so 1.0 on a 128px radial is a 128px blob — dust motes
want hundredths.

Ambient audio (Layer 5) is specified but **blocked**: no audio assets, no audio pipeline, and no
sanctioned audio tool. The toolchain is a closed list and adding one needs explicit approval.
Client render only; no board asset; no `src/**` change.

---

## 2026-07-24 — TD-067 T231: the Contract Board leaves `main.gd`; the last tranche lands as three modules

**Context.** T231 was the final tranche of the `main.gd` decomposition (TD-067) and the largest:
the Contract Board — the wall the writs hang on. It was specified in `specs/main-decompose/` as one
new file, `board/contract_board.gd`.

**What changed against the spec.** The verbatim block came to ~850 lines: more than twice the S2.3
soft ceiling, and holding three responsibilities that a reader has to hold apart anyway. It shipped
as **three** modules instead:

- `board/contract_board.gd` (~470) — the wall: `build()`, the keep-out layout, decay, vignette,
  bottom bar, keybind strip, focus traversal, transform reset.
- `board/notice_card.gd` (~346) — **one** writ: the content fit, the live card, the inert flavor
  scrap, tack, verb badge, focus reticle, hover lift, and the live-tone contrast floor.
- `board/board_header.gd` (~109) — the hanging carved sign and its placement.

Dependencies run **one way** (wall → card, wall → header), which is what makes the split safe:
GDScript cannot resolve a cyclic `preload`, so the card owns its own art and focus memory as static
state and the wall reads them through `parch_live()` / `focus_cid()` rather than the card reaching
back for a `Ctx` the wall defines.

**The socket stays in the shell.** Same idiom as T230: a `Ctx` carries snapshot/selection/viewport
in, and `on_select` / `show_reader` carry intent out, so no board module touches `_net` (S3.5) and
none of them decides anything (I1). `main.gd` went **2,553 → 1,679 lines (−874)**, and the Contract
Board — the thing that made it a god-object — is no longer in it.

**One thing moved that the spec did not name.** `_surface_material` was a `main.gd` private, but it
exists to pack `BoardDecor.torch_rig` into `board_surface.gdshader`'s uniforms, and it was being
called from the board, the popup frame, the lobby masonry and the menu. It is now
`BoardDecor.surface_material(vp, …)`, beside the rig it reads. Every lit surface in the game takes
its light from one function again — which is the P72 invariant the comment already claimed.

**How "unchanged" was proven.** A capture is not evidence on its own here: the board's torch
particles are nondeterministic, and *which writ holds hover-focus* depends on where the OS cursor
happens to sit when the window pops. So the check was a **same-build control**: HEAD captured twice
differs by 0.466% of pixels; HEAD vs this build differs by 0.419%, in the **same x-bands**. The
deterministic readouts match exactly (`keepout live=8 ok=true minhit=80x53 hit_ok=true`,
`inner=(473.6, 288)`, `board live=8`). Reader paths verified across unsealed, sealed, flash
(unclipped per TD-064), reader-cycle (`board live=` logged once — TD-068's fast path intact), empty
board, and `--lights-off` (wall, banner and sign go flat, proving the moved `surface_material` still
lights them). Lobby and room-setup captured too, since `_menu_stone` rides the same call.

`tools/asset_map.py --selftest` caught the move immediately: `board_header.png`'s consumer pin still
named `main.gd`. Re-pinned to `board_header.gd` — the selftest doing exactly the job it exists for,
after sitting red unnoticed from TD-058 to TD-069.

Client render only. No `src/**` change; server 362 + shared 65 suites green and untouched.

---

## 2026-07-24 — TD-074: the notice-board spec is closed; a stale task list is worse than no task list

**Context.** `specs/notice-board/` still carried unchecked boxes — T133–T137 and T145–T147 — and
CLAUDE.md described them as "deferred, not abandoned". Picking the tail up to finish it revealed
the problem: the tasks describe a board that no longer exists.

**What had drifted.** Between the spec being written and today, the Contract Board was redesigned
three times:

- T134's **full-board scatter** was replaced by the framed grid (TD-040), its `_notice_placard` by
  the carved sign (TD-053/058), and its flavor scraps put behind `--flavor`.
- **Threat pips**, named in T134 and measured by Pass-2 **L2**, were **deleted** in TD-061: "no
  knowledge as a number" applies to the Collegium's paperwork too.
- Pass-2 **L7** checks the **15-colour palette lock**, **retired** in TD-046 — the check it
  describes would now fail by design.

So the remaining items could not be *run*, only reinterpreted. An unchecked box that cannot be
executed is not a backlog item; it is a lie about the state of the work, and it costs a session
every time someone tries to honour it.

**What was actually still true.** Auditing the live code rather than the checkboxes: T133 shipped
as `board/notice.gd`, T135 as `board/notice_reader.gd`, T136 grew far past its own description
(TD-062/063/064/065/068), and **T146 was fully implemented** — Tab traversal in geometric reading
order, the corner-bracket reticle (which replaced the specced gold ring because it fought the flat
card states), the empty-board line, seal disabled/pressed/focus states with role-bound captions,
and raced `LOBBY_ERROR`s surfacing on the board's own toast where the leader is looking. It had
simply never been ticked.

**One thing was worth finishing rather than closing.** Pass-2 **L1** (the contrast floor) had only
ever been verified *analytically* — T145 argued that because `_floor_tone` clamps every live paper
to `#CBB583`, ink must clear 4.5:1. True, but it is an argument, not a measurement. It is now
**measured off a real composited capture**: sampling each of the 8 writs' text band (darkest ~1.2%
of pixels = glyph cores, brightest 20% = lit paper, WCAG relative luminance) gives **6.76:1 worst**
(The Weeping Reliquary), 9.28:1 best, all eight passing. L3/L4/L5/L6/L8 verified by capture at the
same time.

**Decision.** Close the spec. Superseded items are marked **in place** with what replaced them
rather than deleted, so the trail from requirement to shipped code stays walkable;
`requirements.md` and `design.md` remain, because R118–R128 are cited from shipped client code
(`notice.gd`, `wax_seal.gd`, `main.gd`) and from live, tested server handlers. `playtest.md` is
banner-marked **do not run as written**.

**What survives as real work:** a **two-client manual playtest** — the leader/non-leader seal
split, the `CONTRACT_SELECTION` broadcast, and the staged deploy. The capture harness has no second
client, so this needs a human and is recorded as a standing playtest rather than a task.

**The lesson worth keeping:** a spec that outlives three redesigns of its own subject should be
closed, not carried. Marking items superseded *in place* costs nothing and preserves the trail;
leaving them unchecked implies work that no longer exists.

Docs + spec only. No code change; no `src/**` change.

---

## 2026-07-24 — TD-074 addendum: spec status is derived, and two specs were audited against the tree

**Why.** TD-074 closed one rotted spec. The author's response was the right one: *"make a UI for
spec status so I can visualize what's going on to prevent scenarios like this, due to different
sessions."* Spec rot is a multi-session problem, and it is invisible from inside any one session.

**The audit that prompted the tooling.** Two specs were checked line-by-line against live code, and
they had rotted in **opposite directions**:

- **`specs/collegium-client/`** — T115–T120 sat unchecked while the code ran fine every day.
  Verified against `world/space_view.gd` (`SpaceView`, `set_space`, `grid_size_px`, `_draw`),
  `_bodies`/`_apply_positions`, `_send_move_intent`'s edge-triggering, `_render_space()`,
  `STATION_RADIUS`/`_update_stations`, `EXTRACTION_RADIUS` — all present; the `--lobby-preview`
  capture shows the whole thing running. **Ticked.** Two task *descriptions* are superseded and
  were deliberately NOT re-implemented to match: T118's inline roster overlay and T119's in-range
  panels were replaced by TD-071's room scroll and the E-to-open station popup. T121 stays open —
  it needs two clients.
- **`specs/station-ui/`** — the reverse, and worse, because the error was in CLAUDE.md rather than
  in the spec. CLAUDE.md announced a **"Stipend-priced Quartermaster and Deploy Gate"** as shipped.
  It does not exist: `grep -rn "stipend\|price" src/` returns nothing, `GearItem` has no
  `price`/`description`, there is no `STARTING_STIPEND`, and `handleRequisition` checks
  `BAG_SLOTS` only. The client Quartermaster is still a `CheckBox` list; the Deploy Gate is one
  button. **T125–T128 are real, unstarted work** — and `Stipend` is a canonical GLOSSARY term
  load-bearing for the preparation pillar, so this is a gap in the game, not dead scope. CLAUDE.md
  is corrected and the spec carries an audit banner.
- **`specs/protocol-contract/`** T10 was flagged, re-run, and passed on the first try:
  `pnpm gen:protocol` produces no diff and `pnpm -r test` is green (65 + 362 + 7). **Ticked.**

**The tooling.** `tools/spec_status.py` (stdlib, read-only, same discipline as `asset_map.py`)
scans every `specs/*/tasks.md` and reports **disagreements between a spec and the tree**, not the
spec's own account of itself:

| flag | meaning |
|---|---|
| `CLAIM` | CLAUDE.md calls a spec complete while unblocked tasks are open |
| `MISSING` | an **open** task names a file absent from the tree — the design may have been replaced |
| `LIKELY-SHIPPED` | an open task names only files that exist — probably shipped, never ticked |
| `STALE` | open tasks, untouched for 45+ days |

`tools/spec_status_html.py` renders the same data as a self-contained page, fed from `collect()` so
the page can never disagree with the report.

**Three refinements that mattered**, each from a false positive the first version produced:

1. `MISSING` fires **only while work is open**. Flagging finished specs for naming since-retired
   assets produced 22 findings out of 36 specs and buried the two real ones.
2. `.md` is excluded from path evidence. Every "full playtest pass" task names its own
   `playtest.md`, which resolved and made the task look shipped.
3. `*.test.ts` is excluded from `LIKELY-SHIPPED` evidence. `gear.test.ts` exists and always did —
   it proved nothing about whether the Stipend inside it was ever built, and it made station-ui's
   T125/T126 read as shipped when they are the largest real gap in the repo.

**And the selftest is pinned to the rules, not to findings.** The first version asserted "station-ui
raises CLAIM" — then CLAIM was resolved by correcting CLAUDE.md and the selftest went red for doing
its job. It now exercises `classify()` on synthetic rows (CLAIM fires on *completed*, not on
*partly shipped*; `MISSING` never fires on a finished spec; `STALE` respects its threshold) plus a
few structural live invariants. `asset_map.py` made exactly this mistake and sat red from TD-058 to
TD-069; the same trap was not worth walking into twice.

Result: **36 specs, 2 flagged** — `station-ui` (the real Stipend gap) and `mobile-input` (genuinely
unstarted, its files are the deliverable). Tooling + docs; no runtime code change.

## 2026-07-25 — TD-073 addendum: the title rig takes a plate, and the asset contract is refereed

**Why.** T260 is "drop in the authored assets per `asset-manifest.md`" — and the manifest and the
rig had drifted apart, so following the manifest literally would have produced art that never
appeared. `title_scene.gd` loaded seven per-piece architecture slots (`pier_left.png`, `vault.png`,
`floor.png`, …) that the manifest never mentions; the manifest asked for one `hall_plate.png` the
rig had no slot for, plus a `chain.png` nothing loads. The rig loads **by exact filename and skips
what is absent** — the property that lets art arrive one piece at a time — so none of that errors.
It renders a blockout and says nothing. The author would have generated a plate, dropped it in, seen
no change, and had nothing to debug from.

**Decided.**

1. **The rig takes the plate.** `hall_plate.png` is a full-frame architecture layer at `z=-64`,
   `STRETCH_KEEP_ASPECT_COVERED` (a 16:9 plate in a non-16:9 viewport overflows rather than
   distorting the composition, R241), drawn at a **1.2% overscan** so `_camera_life`'s 2px drift
   cannot walk an edge into view, and never animated (P128). One painted plate holds a single
   coherent camera; seven separately generated cutouts have to be re-aligned to each other by hand.
2. **The seven pieces become overrides, not rivals.** With a plate present, a per-piece slot renders
   only if its own file exists — a missing piece is not a hole, so it draws no blockout over the
   plate. Without a plate, nothing changes: the seven blockouts are the architecture, as before.
   Both paths, and the mixture, work.
3. **The contract is refereed, not asserted.** `tools/title_assets.py` derives the slot list from
   `title_scene.gd` — the only thing that actually loads anything — and the expected sizes from the
   manifest's table rows, then fails if the two disagree. It also installs staged art from
   `art/src/title/` and checks each file's IHDR: a prop exported as RGB instead of RGBA is a **hard
   error**, because it arrives with its background baked in and renders as a rectangle over the
   scene. `--selftest` asserts the rules; `--check` exits 1 on a violation.

**Not decided.** No `gen_title_assets.py`. Painted source art is copied **byte-for-byte**; re-encoding
a painted matte through a pixel-art generator is the register mistake TD-055 warns about. The plate
remains the one deliberate painted-register exception (R242) and no board or HUD asset changes (P127).

**Verified.** A throwaway synthetic plate (never `collegium_hall_src.png`, which stays reference-only)
installed, imported and captured: the seven architecture blockouts vanish, the plate fills the frame
undistorted with no edge seam, and the cloth/prop/vessel/overlay blockouts still animate over it.
The validator raised both intended warnings on it (wrong size, carries alpha). The test plate was
then deleted; `--check` is green at 0 of 18 slots filled, which is the correct state until art lands.
Client render + tooling + docs; no `src/**` change.

## 2026-07-25 — TD-073: the plate is generated after all — `gen_title_plate.py`, on the author's call

**Why.** T260 was blocked waiting on painted art, and the author's instruction was to generate the
plate with the generators instead. That is, plainly, a **retry of what TD-072 recorded as a
failure** — a single procedurally generated plate, four passes, a structural ceiling. Recording it
here so the retry is not mistaken for someone forgetting the entry.

**Why it can work now, when it could not then.** The retry is narrower in exactly the two places
TD-072 failed:

* *"Small props at small scale."* TD-072's flame failed four times (box → cone → ball → box), the
  same finding TD-057 recorded for the 17×22 medallion device. This plate carries **no props at
  all** — no flame, no candle, no censer, no banner. Every one of them is a separate animated layer
  over the plate in `title_scene.gd`, which is what the asset manifest already asked for. The
  failure mode is absent because the content is absent.
* *"Light as arithmetic."* TD-072 baked falloff over a **stepped, palette-locked ramp** and it
  banded. Here the plate is lit by ambient and the distant apse only; all seven fires are in-engine
  additive pools that flicker (TD-043). Nothing baked has to impersonate a light, the surface stays
  in the painted register (R242 — no `quantize`, palette-lock retired in TD-046), and an ordered
  dither keeps the long gradients smooth.

TD-072's third finding — *symmetry and uniformity* — is the one that had to be answered by work
rather than by scope. Every bay is seeded: opening widths vary ±6% and **differ between the two
walls**, so the arcade is not a mirror; the clerestory's panels vary in brightness and colour with
some lights boarded; ashlar course height drifts per bay; soot and salt weathering are per bay, and
the left wall is grimier than the right. An analytic wall that repeats exactly is the tell.

**Decided.** `client/assets/ui/gen_title_plate.py` **imports the camera from `gen_nave.py`** rather
than re-deriving it (hfov 105°, pitch 15°, Chartres' 16m × 37m) — design.md always intended that,
and it was the one part of the single-plate attempt that measured correct. One inversion matters:
TD-072 lit the near brightly because its braziers were in the image. Here **the near falls to
silhouette**, because in the finished scene the foreground is lit by real fires that are *not* in
the plate. A plate that pre-lights its own foreground would be lit twice.

**Not closed.** This does not retire the author-art path: dropping a painted `hall_plate.png` into
`art/src/title/` still replaces the generated one, and the rig neither knows nor cares which
produced it. The per-piece architecture overrides and every prop layer remain unauthored (T260).

## 2026-07-25 — TD-075: the title screen is PIXEL ART; the Contract Board is the visual authority

**Why.** The author supplied two references with an explicit precedence rule: Reference A (a concept
painting of the Collegium's great hall) governs **composition, camera, scale, mood and lighting**;
Reference B (the shipped Contract Board) governs **pixel density, palette, shading, readability and
craftsmanship** — *"if there is ever a conflict between the two references, follow the Contract
Board."* The brief also rules out, by name: anti-aliasing, painterly textures, procedural texture
noise, more than minimal dithering, and anything resembling AI-generated pixel art.

Everything shipped for the title screen since TD-073 fails that on all five counts. The plate was a
1920×1080 painterly render with per-pixel noise and dithered falloff; the props and banners were
smooth-shaded objects authored at 340–660px. **The register was decided by the pipeline, not by the
shading:** art authored at 1920×1080 and drawn into a 640×360 viewport through a LINEAR filter is
resampled 3:1 and can never be crisp, however carefully it is painted.

**Decided — the pipeline first.**

1. **Author at the size it is displayed.** Everything is now authored at the canonical 640×360
   internal resolution (TD-042) or, for props, at their exact on-screen size (20–96px), and drawn
   **1:1 through NEAREST**. `_rect_of` rounds every layer to whole pixels; the plate's 1.2% overscan
   is gone, and with it the camera drift — which the brief kills anyway (*"the architecture itself
   remains static"*) and which would have resampled the plate every frame.
2. **Every colour is a ramp entry.** Shading picks an INDEX into an Ash & Ember ramp; there are no
   lerps between arbitrary colours. Each generator ends in `A.assert_on_palette` — the same check the
   board's own art passes, and the operational definition of "matches the Contract Board".
3. **Light in flat steps, not gradients.** A candle's pool is two or three flat rings. The moment a
   light term is a float the image needs dithering to survive, which the brief forbids; making the
   term an integer makes the whole class of failure impossible.
4. **Depth bands per BAY, not per pixel.** Banding on raw distance drew a straight diagonal across
   the frame wherever the band changed — a huge flat slab whose edge belonged to no architecture,
   which ghosted on the piers through four passes. A bay is a real unit, so its boundaries are pier
   faces and a change of tone there reads as construction.
5. **Detail gated by distance.** Masonry joints stop once a course projects under ~2px; vault ribs
   stop once a bay is small. Large stone surfaces stay quiet, which is what makes the hall read as
   immense rather than as static.

**Composition.** The camera is pitched from 15° to **21°** and the nave shortened from 115m to 58m:
Reference A puts the vault across the top of the frame and the altar low, and at 15°/115m our
sanctuary landed at fy 0.37 — directly behind the title — with a far wall 35px across. The crest is
**not** hung on the far wall for the same reason: that wall occupies the exact column the title,
rule and menu sit in. The brief asks for the crest on the **banners**, and that is where it is.

**Retired.** `gen_title_plate.py`, `gen_title_arch.py` and the seven architecture slices they
produced — the brief is explicit that the cathedral is a bespoke hero environment and must not become
reusable architecture. `gen_title_props.py` and `gen_title_banners.py` are replaced by
`gen_title_furniture.py`. Slots 20 → 13.

**Withdrawn.** R242's painted-register exception for the title screen. It was granted when the plan
was a painted matte; the author has now ruled the opposite way. The board and HUD register is
unchanged — it was always the one being matched.

**Verified.** `assert_on_palette` passes on the hall and all nine furniture pieces; `title_assets
--check` is green at 13 of 13; captured in the client at 1280×720 (logical 640×360).

## 2026-07-25 — TD-076: the title hall IS the author's painting; the procedural route is closed

**Why.** Four rebuilds of a generated hall, each better than the last, and none of them close to the
reference. The author's verdict was blunt and correct — *"structurally the pillars and ceiling and
the wall looks disjointed … disregard the constraints and make the great hall almost 1:1 to the
reference image."*

The finding underneath is worth keeping, because it was earned expensively: **a ray-caster produces
ordered variation, and a painting's character is controlled irregularity.** Structure was always
reproducible — the curved-geometry work fixed a genuine defect and proved it with tests a painted
surface cannot pass (the vault's normal swings −1.00…1.00; a pier's sweeps a full turn). Likeness
never was. The only thing 1:1 with a painting is that painting.

**Decided.** `gen_title_matte.py` processes `art/src/title/hall_plate_src.jpeg` into the client. The
prop layers stand down (`PROPS_IN_PLATE`) because the image already contains banners, censers, candle
stands and braziers; the fire pools, dust and smoke move onto the lights the painting actually has,
since a glow sitting where we used to invent one lights empty stone.

**Both treatments were built and captured rather than argued about.**

| | result |
|---|---|
| `--register` | 640×360, on-palette, median + two mode passes: **31 colours, 523 single-pixel islands** against a naive downscale's 5876. Technically a success — and an artistic failure. The architecture dissolves; the painting's structure lives at a frequency 640×360 cannot hold |
| `--fidelity` | 1280×720, LANCZOS, drawn **1:1 on device pixels** at a 720p window with NEAREST and no filtering. Reads as the painting itself. **Shipped** |

**Two rulings are reversed, knowingly.** TD-073 forbade using the PNG as the main menu (the author's
verdict then was "uncanny"), and the author had ruled days earlier that the title screen must keep the
Contract Board's pixel language. Both were overridden explicitly and in writing. The board, the HUD
and every other surface keep the pixel register untouched — the title screen is now deliberately its
own thing, which is a normal choice and no longer an accidental one.

**Kept, not deleted.** `hall_geometry.py` and its self-tests stay in the tree. The flat-plane defect
was real, the curved vault and cylindrical piers work, and that geometry may still earn its place for
in-game Collegium screens where a generated environment is worth more than a painted one.

## 2026-07-25 — TD-076 addendum: a pixel-art base replaces the painting, and the props come back

**Why.** The author supplied a second image and asked two questions: can it be used, and is its
resolution workable. Both measured rather than eyeballed.

**Can it be used — yes, and it beats the painting on three counts.** It is **architecture only**: no
banners, censers, candle stands or braziers in the image, so every layer that animates is drawn
again (`PROPS_IN_PLATE` back to `false`). The painting had its furniture baked in and frozen, which
cost the sway, the pendulum and the drift. It is also **genuinely pixel art** — at 4× the arch curves
step one pixel at a time, hard-edged — so it lives in Testament's language with no down-registering,
the step that destroyed an earlier attempt. And no UI is baked in, so nothing needs inpainting out.

**Is the resolution workable — yes, with one crop and one scale.**

| | measurement | consequence |
|---|---|---|
| aspect | 1536×1024 = **3:2** | 160px of height must go. Cropped 110 off the top, 50 off the bottom: the vault has headroom, the floor and the altar's steps are load-bearing |
| native grain | **native at 1536** — the upscale test found no factor (all ratios ≈1.00) | nothing is already degraded; this is the real pixel grid |
| display fit | a 720p window wants **1280×720** | 1536 → 1280 is a **1.2× non-integer** downscale, so it is resampled ONCE at build rather than unevenly at runtime every frame |

**Also graded.** The source is greyscale and Testament is not, so luminance is mapped along the
navestone ramp with the highlights running into gold — candlelight then has somewhere to go when the
engine's pools land on it.

**Honest remainder.** At 1280×720 the hall's grain stays finer than the Contract Board's, and the
generated props (authored at the 640 grain) are consequently *chunkier* than the hall they stand in.
That mismatch is visible if looked for. Fixing it means re-authoring the props at twice the detail —
not merely scaling them — which is real work and is not done.

## 2026-07-25 — TD-076 addendum: the props lean again, to the base's own measured zenith

**Why.** The author asked why the props do not sit in the hall's perspective, and whether that was
deferred. Neither — it was a **regression**. The lean was built once (TD-073 T264, props sheared
toward the zenith their floor position implies) and then silently dropped when the props were
re-authored as pixel art in TD-075. No spec restored it, and nothing caught it, because nothing
tests it.

**The zenith is measured, not inherited.** `tools/measure_reference.py` run against the new base
solved **both** vanishing points and passed its own symmetry check for the first time — the nave VP
landed at **fx 0.500 exactly**, the zenith at **fy −6.768**. That implies a much longer lens than the
old procedural camera (pitch 12.6°, hfov 49.4° against 21° / 105°), so the leans are gentle: **2–5°**,
where the old hall wanted 13°. Reusing the previous camera's zenith would have tilted everything
roughly three times too far.

Each prop's shear falls out of where it stands rather than being chosen:

| prop | lean | degrees |
|---|---|---|
| banners | ±0.083 | ±4.7° |
| candle racks | +0.076 / −0.077 | ±4.3° |
| censers | ±0.050 | ±2.9° |
| braziers | +0.037 / −0.037 | ±2.1° |
| banner_center, chandelier | 0 | dead centre — nothing to converge |

The shear is applied as a **whole-pixel offset per row**, so the edge stair-steps: that is how pixel
art draws a near-vertical line, and it keeps every pixel hard. `Grid` pads the image to hold it and
the generator prints the widened rig fractions, so the object still renders at the size asked for.

**Also:** the candle racks were toned down (the author's report). They were authored at nearly the
value the engine's own pools add, so the two stacked into white bars in the corners. Toning them out
entirely was an over-correction on the first pass — they read as wire frames — so the taper body sits
one step back up. An unlit prop has to leave the fire somewhere to go.

## 2026-07-25 — TD-076 addendum: the title screen is the hall and the UI, and a sigil marks the choice

**Why.** The author's call, after seeing the furnished version: strip the props entirely, keep only
the Collegium device above the title, and mark the selected option with a sigil either side of it.

**Decided.** `PROPS_IN_PLATE` back to `true` — the banners, censers, chandelier, racks and braziers
are switched off. Their art, their tables and their slots in the asset contract are untouched, so
the flag reverses it; nothing was deleted for a decision that might swing back.

Two things had to follow the props out, and neither is cosmetic:

* **Six of the seven fire pools.** They existed to sit *on* the vessels. With the vessels gone they
  would light empty stone, which reads worse than no light at all. The sanctuary's pool stays,
  because the hall has an altar there.
* **The censers' incense.** Smoke rising from nothing is the same failure. `gen_title_overlays.py`
  now bakes one plume, from the sanctuary, instead of three.

**The sigil replaces the focus ring.** `gen_menu_sigil.py` emits a 20×20 gilt lozenge with a bar
running toward the word it marks — the Contract Board's ornament vocabulary (brass line, dot finials,
chevroned diamond), not a game-UI arrow. It is authored at the hall's grain and drawn NEAREST like
everything else on the screen. The old `Widgets.focus_ring()` is gone from this menu: a rectangle
drawn round gilt Cinzel turned an image back into a dialog, which is the thing R232 exists to stop.

Two details that matter more than they look: the sigils **keep their space when unlit**, so marking
an option never shifts the lettering; and hovering an option **grabs focus** rather than lighting a
second mark, so exactly one choice is ever marked. The first option takes the mark on arrival — the
recovery path when there is one — because an unmarked menu reads as art that failed to load.

## 2026-07-26 — TD-077: the title screen gains depth, a hard register, and the Collegium's laurel

**Why.** The author signed off the stripped title screen and asked for four things: parallax smoke to
sell a 3D space, a pixelised Cinzel *if it stays readable*, a larger selection marker "that reflects
the Collegium brand", and a set of scene improvements to choose from. Spec'd as `specs/title-polish/`
(R263–R268, P132–P134, T281–T286) and approved before building.

**Parallax without moving the plate.** The hall is one flat painted plate, so it has no depth to
parallax, and R246/R267 stand: moving *it* exposes the flatness (and at 1:1 device pixels a sub-pixel
move resamples every pixel while an integer move visibly jumps). But moving fog against **other fog**
cannot expose anything, because the only thing the eye can compare is one bank to another. So three
banded alpha sheets at 1440×720 drift at 90 / 55 / 32s, and that *is* the depth cue (P132).

Two findings worth keeping:

* **The strength ceiling is set by contrast, not by how much fog reads.** The first pass was ~4× too
  strong. Additive white over a hall this dark lifts the black floor across the whole frame, so it
  read as a milky film laid over the picture and the deep contrast that makes the scene work was
  simply gone. Alongside the cut, a `nave(fx)` weight keeps fog off the **near piers** — the closest
  thing in the frame, and the worst of the wash.
* **Edge safety is a test, not a comment.** Each sheet is wider than the frame by exactly the drift
  headroom, and `title_assets --selftest` now parses `FOG_OVERHANG` and every bank's drift out of the
  rig and fails if a drift exceeds the half-overhang (verified to fail by raising one 38 → 48). The
  failure is invisible in a still — it appears only as a hard seam sliding across the hall seconds
  after load — and "raise the drift so the parallax reads more" is precisely the future edit that
  causes it.

**Cinzel joins the no-AA register, project-wide.** `Cinzel.ttf.import` now sets `antialiasing=0` and
`subpixel_positioning=0`. Done in the **import**, not as a runtime property, so every load of the face
is affected and no call site can opt back in by accident. `fonts.gd` had recorded the AA as a
deliberate exception on the grounds that "its fine serifs shatter at this size"; captured before and
after at 3×, **that does not hold** — the title gains cut-stone edges and the 13px options are sharper
and fully readable.

The Contract Board was re-captured rather than assumed safe, and the verdict is reported with its one
caveat: Cinzel on the board is only the header, "THE COLLEGIUM" improves, and the subordinate
"Contract Board" line — the smallest Cinzel in the game — comes out slightly **chunkier**, its stems a
shade irregular. It stays legible and now matches the register around it, so it ships; that line is
the one place the old exception had a point. The board's small text (legend, status, keyhints) is the
default sans and is pixel-identical.

**The marker is one branch of the order's laurel, and its leaves are hand-placed.** The crest's wreath
is two branches meeting at the base and opening outward around the sword; the UI draws one and mirrors
it, giving the author's sketch `\ word /`. Five analytic passes were spent trying to draw the leaves
with a shape function and each failed differently — thin lenses read as **thorns**, fat ones as
**pods**, long ones **fused into a single gilt mass**, and spacing them until they stopped fusing left
a **fishbone**. That is TD-057's finding arriving again at 34×30: *a shape function samples a curve; it
cannot decide which pixel carries the leaf.* So the leaves are ASCII stamps and only their placement is
computed. The **rim is derived** — every empty pixel touching gold — because at four pixels across
only a dark edge separates two overlapping leaves, and a dilation cannot be forgotten on one leaf and
not another.

**Scene work, all without a new asset slot.** Depth haze is baked into `fog_far` (it *is* fog); the
altar embers are tuned up, since with the six vessel fires gone it is the only fire in frame and was
throwing sparks into the brightest part of the picture where they vanished; and there are three god
rays off **one** sheet, mirrored and rescaled per placement, each breathing on its own period —
because rays pulsing together are the same tell as synchronised flicker. The embers then needed
`damping`: the altar sits directly below the menu column, so a livelier undamped ember climbs straight
through the last option. Damping caps the climb where the widened spread has already thinned the
stream, which is also what a cooling ember does.

**Two bugs the arrival sequence uncovered, both older than it.** `--title-preview` had been deferring
a **second** `_show_title()` purely to inject its fake reconnect token, so the arrival flourish played
on a build that was immediately discarded — and every title capture had been constructing the whole
scene twice for nothing. Setting the token before the first build removed the rebuild, which then
exposed what it had been masking: `--reduced-motion` was parsed *after* `_show_title()`, so the title
only ever honoured it because that unrelated flag happened to rebuild the screen afterwards. A real
dependency on a side effect, invisible while both were present.

Also recorded because it cost time: `project.godot` is a Godot **ConfigFile**, where comments start
with `;`. A `#` comment silently breaks the section it sits in — which is why `config/version` first
read back as an empty string.

**Containment.** Client render, generated art, docs and tooling only. No `src/**` change and no wire
change (R268). Suites green: server 362, shared 65, tools 7. `asset_map` and `spec_status` selftest +
check green, `title_assets --check` at 16 of 16 slots. Captured at both integer scales.

## 2026-07-26 — TD-078: the altar goes cold, and the air becomes volumetric

**Why.** Two author notes on the finished TD-077 screen: remove the bright orange glow on the altar,
and make the fog read as **3D depth** rather than 2D layers. Also the first spec written under the
new performance canon (`.claude/rules/performance.md`), so the budget is in the requirements and is
a tool, not a comment.

**The altar is cold.** The additive glow pool, the sanctuary embers and the warm haze baked into
`fog_far` are all gone; the only light at the arch is the light the plate paints. `FIRES`, `_glow`,
`_embers`, `_flicker`, `_incense` and `_drift` are **deleted**, not switched off.

**Sheets could not get there, and it is worth saying why.** TD-077's three drifting fog sheets are
lateral parallax — planes sliding past planes. Depth in a static frame comes from motion **toward the
viewer**: things growing, accelerating, leaving the frame. That is the one cue a flat plane cannot
fake, and it is what was missing. So the sheets are retired and the air is three `CPUParticles2D`
banks whose emitters sit **at the hall's vanishing point**, with `radial_accel` pushing particles
outward from it — positive for near (rushes past and grows), **negative** for far (converges into the
distance). The banks differ in the *direction* of travel, not only its speed, and none of it costs a
frame callback: an emitter at the VP with a radial accel **is** the effect (P135).

**The vanishing point is derived, and the obvious number is wrong.** `measure_reference.py` reports
the nave VP at `fy 0.8651` — on the **uncropped** source. `gen_title_matte.py` crops the plate at
y=110 of 1024 to a height of 864, so the rig wants **0.8980**. Those are ~24 logical px apart:
plausible in a still, visibly wrong the moment anything moves along it. `title_assets --selftest`
now re-derives it from the generator's own crop box, so a future re-crop fails loudly instead of
quietly skewing the air.

**The budget is a tool.** `title_assets --budget` parses the bank table, the dust emitter and the ray
table out of the rig and enforces ≤120 particles, ≤3 full-frame additive layers and ≤2.5 screens of
additive fill (fill is a *ratio*, so it is computed in logical units and holds identically at 720p
and 1080p). It matched the design's hand-computed table exactly on its first run. A still capture
cannot show a frame cost, which is the whole reason this is a check and not a paragraph.

**Four findings this spec surfaced but did not cause:**

* The screen was running **five** full-frame additive layers against a ceiling of three.
* **Dust was being drawn twice** — `dust_overlay.png` *and* `_dust()`'s 46 particles — since T260c.
* The **god rays were invisible**: the sheet peaks at alpha 34/255 (only ~9% of it reaches that), the
  rig multiplied by 0.20/0.13/0.10, and `_breathe` took another 35% — a peak add of **6.8/255** over
  a hall whose own stone varies by more. They were simultaneously the most expensive thing in the
  frame at ~0.95 screens of fill, more than every particle combined. Resolved by deleting the two
  flanking rays and raising the dominant one to **0.55**, chosen *from the sheet's alpha* rather than
  by eye: an 18/255 peak, at half the old cost. Setting an opacity without reading the asset's alpha
  is exactly how this happened.
* `gen_title_furniture.ZENITH_FY` is `-6.768`, the **source-space** zenith used against display
  fractions — the crop-corrected value is **-8.148**, so every prop's shear leans against a zenith
  ~20% too close. Dormant only because `PROPS_IN_PLATE` switches the props off; turning them back on
  would ship a wrong lean. Recorded, not fixed here — this spec touches no prop.

**Two corrections found by looking, not by reasoning.** `direction = Vector2(0, 0)` gives the initial
velocity no direction at all, so the particles sat on the emitter and crept out on `radial_accel`
alone — a real bug, invisible in the code review, obvious in the capture. And the first visible pass
read as distinct **blobs** rather than fog: fog comes from *overlapping* soft shapes, so the banks
went bigger and fainter at the same counts. Fill rose 1.39 → 1.92 and stayed inside the ceiling —
the budget paid for the fix rather than blocking it, which is the argument for setting it generously
and early.

**Containment.** Client render + tooling only; no `src/**` or wire change. 11 asset files deleted.
Suites green (server 362, shared 65, tools 7). Asset map, manifest, registry and `title_assets`
(`--selftest`, `--check` at 11 of 11, `--budget`) all green. Pre-existing advisories left alone:
`title/title_fire.gdshader` is an orphan that predates this work, and `gen_nave.py` still declares a
write to a `title/nave.png` that is not on disk.

## 2026-07-26 — TD-079: the whole atmosphere moves onto one quad

**Why.** A polish pass on the author's brief: the Collegium is the last bastion — ancient, sacred,
solemn, immense, quiet. Reduce motion until the hall is almost frozen. Improve ambience with
**shader-driven** effects rather than props. Testament is browser-first.

**The plate was the cheapest surface in the scene and nothing was using it.** It is a `CanvasItem`
covering the frame, rasterised every frame whether or not a shader is attached. So ground haze,
atmospheric perspective, god rays, altar emphasis and the light's breath all moved into
`title_air.gdshader` on that quad, where they cost ALU and **zero additional fill** — replacing three
particle fog banks and a `light_shaft.png` overlay that were *additional* blended coverage. Measured:
**102 particles / 1.44 screens of fill → 34 / 0.00**. Taking "favor shaders" literally paid for
itself several times over.

**Depth with no depth buffer.** A painted plate has no depth information, but it has a derived
vanishing point (TD-078, crop-corrected to `fy 0.898`). Distance from it is the proxy: near the VP is
far down the nave, the frame edge is the near piers. That scalar drives the atmospheric perspective
(saturation falls, blacks lift *more than highlights* — haze raises the floor, it does not brighten
everything) and the altar's emphasis. No blur: blur needs a second sample set and reads as a lens
defect rather than as air.

**Two rules keep it from reading as active.** Nothing moves — every animated term varies in
*intensity* only, so rays never sweep and haze never rolls. And the plate is never resampled: the
shader reads its own `COLOR` and writes it back. Measured over 8 seconds, the frame's mean per-pixel
change is **1.30** against the plate's own pixel-to-pixel texture variation of **24.65** — the screen
changes **19× less than its own grain**, which is "almost frozen" in a form that can be checked.

**A Godot semantics trap, recorded so it is not hit again.** In a `canvas_item` shader, `COLOR` on
entry **already holds** `texture(TEXTURE, UV) * modulate`. Sampling again and multiplying by `COLOR`
squares the image. On a hall this dark that cost a factor of **5** in mean luminance (37.2 → 7.6) and
looked exactly like "the shader destroyed the plate". It was found by bisecting — detaching the
material put the un-shaded baseline at 35.8, which proved the shader was the cause rather than the
fog that had just been deleted. Read `COLOR`, write `COLOR`: correct, and one texture fetch cheaper.

**Then it was too bright**, which is the subtler failure. The first working pass lifted mean
luminance 27% over the un-shaded plate: the distance receded properly and the hall stopped being
dark. Dark is the brief. Halving the lift and haze settled it at +18%.

**Rays measured rather than chosen.** TD-078's lesson was three rays shipped invisible because an
opacity was set without reading what it multiplied. These were differenced with `ray_strength` at 0
and at its shipped value: **peak add 25/255 over 16.4% of the frame**, against the old sheet's 6.8.

**Dust drifts; it does not rise.** The old field pushed everything upward on a negative gravity,
which reads as heat or smoke — the two things this hall is not. Gravity is now near nil with full
spread, at two depths whose difference *is* the parallax.

**The selection mark becomes the Collegium's seal.** 175 ms transition, a 9-second 14% idle breath,
and the selected label at **+12%** luminance, measured — down from +23%, which read as a highlight
rather than as emphasis. A slide was dropped on purpose: the sprigs live in an `HBoxContainer` that
reassigns child positions on every layout pass, and the brief says "fade *or* slide".

**No camera breath, and this is a decision.** The brief asks for a sub-pixel camera breath *"if
appropriate"*. It is not: the plate is drawn 1:1 through `NEAREST`, so a sub-pixel move resamples
every pixel of a pixel-art image and shimmers, while an integer move visibly jumps. TD-075 and
TD-077 both removed camera drift for exactly this. The light breathes instead — same intent, no
cost, nothing broken.

**Also retired:** `title_fire.gdshader`, an orphan from the TD-073 matte era that found bright pixels
and treated them as flame. Confirmed unreferenced in HEAD before deleting.

**Containment.** Client render only; no `src/**` or wire change. Composition untouched — menu layout,
typography, logo placement, background and spacing all come out unchanged, and no props were added.

## 2026-07-26 — TD-079 addendum: darker, and a hint of fog

**Why.** The author, after seeing TD-079 running: make the Collegium's lighting darker, and bring
back some floating fog particles — "much more, but not too much, just to hint that it exists."

**Darker comes mostly from a vignette**, not from turning the atmosphere down. The lifts came down
too (`air_lift` 0.17→0.095, haze 0.075→0.052, altar 0.055→0.042), but the vignette is what does the
work, and it does two jobs with one term: deepening the frame's edges while leaving the sanctuary
alone makes the hall darker *and* makes the altar read more clearly as the focal point. Mean
luminance **42.23 → 33.52** — now below the un-shaded plate's own 35.83 rather than above it.

**The fog hint is a deliberate partial reversal.** R277 said "replace obvious fog particles with
cathedral air", and that still describes the architecture — the shader owns the atmosphere. But the
author wants particles hinting at volume, so a third row joins the dust depth table: 20 large,
very slow, almost-invisible motes. Kept faint enough that they read as air catching light rather
than as the fog banks TD-079 removed.

**The property from T297 was re-verified rather than assumed.** Adding particles is exactly the kind
of change that quietly breaks "almost frozen", so the measurement was re-run: motion over 8s went
**1.30 → 2.23** against the plate's own grain of 22.21. Still 10× below it, so R278 holds — but it
is 70% more motion than before, and that is the budget being spent, not free.

Budget: 34 → **60 particles / 0.18 screens of fill**, both far inside their ceilings.
