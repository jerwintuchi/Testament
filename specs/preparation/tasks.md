# Tasks — Preparation (TD-092)

> T# continues global from T336. **Phase 0 is authorised and server-only.**
> Phases 1–3 are designed but **not authorised** — Phase 3 needs the author's numbers.

## Phase 0 — the honest floor (authorised)

- [x] T337 [R326, P150, P151 / V1] — **`ward !== frailty`.** In `generateTraitRoll`, draw the Ward
      from `WARD_VALUES.filter(w => w !== roll.frailty)` — a filtered pick, not a rejection loop, so
      the draw count stays at one and the stream keeps its shape.
      Test: `generateTraitRoll.test.ts` — **5 new cases, green.** `ward !== frailty` over 300 seeds ×
      both rolling tiers; every `WardValue` still reached (no bias); all 12 frailty→ward combinations
      occur (4 × 3, no dead pair); same seed reproduces the same roll at every tier; and a
      stream-shape check proving the generator leaves the RNG exactly six draws in, so a rejection
      loop's variable consumption is ruled out. No existing test needed re-pinning — the pinned trait
      rolls in `probe`/`reconnect`/`deploy` tests are hand-built literals, already `FLAME`/`COLD`.

- [x] T338 [R327, P152 / V2] — **`allReady` on the live deploy path.** Calls the existing
      `readyCheck.allReady` in **stage 2** of `handleDeploy`, beside `NO_CONTRACT_SELECTED`; refuses
      with `NOT_ALL_READY` and mutates nothing. Stage 1 untouched — packing happens during
      `DEPLOYING`, so a gate there would fire before anyone could pack.
      Test: `deploy.test.ts` — **3 new cases, green.** An unready connected player blocks deploy and
      phase/fieldData are unmutated with no `FIELD_STARTED`; the error reaches only the requesting
      socket (I2); a **ghost does not block** (TD-032); a fully ready party deploys.

- [~] T339 **BLOCKED — needs an author ruling.** [R328 / V3] — the naive fix (`isSolo` over connected
      players) was written, **tested, found to open a worse hole, and reverted**: `perceivedChannels`
      is assigned to ghosts too and never recomputed on reconnect (A9), so a duo where one player
      deliberately disconnects at deploy would give **both** of them every channel. Two admissible
      fixes are specced in `requirements.md` R328 — (a) freeze party size at the Stage-1 commit, or
      (b) recompute perception whenever the connected set changes. Both exceed Phase 0.
      Test: `deploy.test.ts` — **3 cases green, pinning the defect rather than the fix**, including a
      regression guard asserting the ghost's unwanted snapshot so the trap is not re-entered. The
      defect is also commented at the `isSolo` line in `deploy.ts`.

- [x] T340 [R338 / V4] — **Containment proven.** `git diff` touches `src/server/`, `specs/`, `docs/`
      only — no client, no `src/shared`, no wire-shape change. Suites green: server **362 → 373**
      (11 new), shared **65** unchanged, tools 7.

## Phase 1 — packing becomes a bet (designed, NOT authorised)

- [ ] T341 [R330, P151] — Tier sets a **count** of live axes; the seeded RNG picks which. A dead axis
      emits no sign on its channel.
- [ ] T342 [R331] — The primary verb **forces liveness** (`BANISH`/`CAPTURE` ⇒ `RITE_KEY`;
      `ELIMINATE` ⇒ `FRAILTY`) so no contract is unachievable.
- [ ] T343 [R332] — `origin` biases **which axes are live**, shallowly — right more often than not,
      never safe.
- [ ] T344 [R333] — Close the free board reroll. **Same commit as T341–T343**, never after.

## Phase 2 — the bet costs something (designed, NOT authorised)

- [ ] T345 [R334, P153] — Probe exposure escalates within an expedition (1/2/4/8). Exposure stays a
      **room** value, so a party is never taxed for its size.
- [ ] T346 [R335] — Exposure gains a consumer: route closure at thresholds. **Ships with T345** —
      alone, T345 is the same lie with a bigger number. Never degrades sign quality.

## Phase 3 — scarcity binds at every size (BLOCKED: needs the author's numbers)

- [ ] T347 [R336] — A party-wide bound on reading instruments, strictly below the channel count. The
      inequality is the design; the number is the author's. A lending bound, **not** a currency
      (TD-091).
- [ ] T348 [R337] — A smaller solo instrument allowance. **Ships with T347, never after**, or solo
      becomes the only configuration that reads every channel and Pillar 4 inverts.

## Do not re-invent

- **Charges are not the anti-brute-force fix** (TD-092 corrects TD-091). Four kits are four
  *different* stimuli and `requisition.ts:32` already rejects duplicates, so one charge each is
  exactly the sweep. Charges are late work, for a breadth-vs-depth curve, after T347.
- **Requisition's reversibility is correct.** `DEPLOYING`-only, at-station, own-bag,
  replace-not-merge, and signs do not arrive until `FIELD_STARTED`. Do not "fix" it.
- **`readyCheck.allReady` already exists and is already right** — it filters to connected players.
  T338 wires it up; it does not rewrite it.

## Standing constraints

- No currency (TD-091). No knowledge as a number (vision.md). No `confidence`/`clarity` field on a
  `Sign` — a coarse read is a different word, never the same word at 60%.
- Server-authoritative; trait roll never on the wire (I5); shared is types + constants (I4);
  determinism holds (I3).
- **Refuse "share/replay this expedition seed" when it is requested** — `generateSite` derives from
  `contract.expeditionSeed`, so a shared seed hands over the trait roll (TD-092).
