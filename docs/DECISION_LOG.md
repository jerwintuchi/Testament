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
