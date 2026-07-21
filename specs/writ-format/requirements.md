# Requirements — Writ format & the Collegium seal (contract read + seal retirement)

> Phase 5, Contract Board content pass on the user's playtest review (TD-060): the compact writ
> read "location at <location>" — because the `--board-preview` fixture's target names are PLACES
> ("The Hollow Hamlet", "Greymarsh"), not Incarnate epithets, misrepresenting the real wire format
> (the server generates "The Ashen Warden at The Salt Marsh"). And the asserted-Origin **wax seal**
> earns no keep on the contract: the petition-type badge already carries the glanceable read, and a
> sealed assertion of Sin implies a certainty the Collegium doesn't have.
>
> **User rulings (do not re-litigate):** the petition-type (verb) badge is enough corner furniture
> for the writ; the Origin wax seal is **archived and removed from the contract** (writ + reader);
> the wax-seal *stamping* survives as a **generic seal for the expedition leader** (the reversible
> SELECT_CONTRACT stamp of R124/TD-041 — one Collegium seal, not Origin-keyed).
>
> Scope: client render + generated art + server **content tables only** (authored name pools — no
> protocol, phase, or logic change; I1–I5 hold). Numbering continues global: **R184+**, correctness
> **P107+**, tasks **T195+**. Logged **TD-060**. Client verified by `--board-preview` captures;
> server by Vitest.

---

## The format

**R184** (client): the compact writ's canonical format is **Incarnate at Site** — the lead line is
the target's *epithet* (a Manifestation, never a settlement), the second line locates it.
- AC: the `_PREVIEW_BOARD` fixture's `targetName`s are re-authored as Incarnate epithets in the
  server's register ("The Ashen Warden" idiom) — no fixture target reads as a place; a board
  capture shows every writ as "<epithet> / at <place>", never "location at location".
- AC: the writ's layout is unchanged otherwise: tack + petition-type badge (upper-left corner) +
  centred target/site block; threat/reward still withheld from the wall (knowledge is not a number).

**R185** (server): the authored `TARGET_NAMES` / `SITE_NAMES` pools grow to **≥ 8 entries each** so
the canonical 8-writ board (BOARD_SIZE=8, TD-045) is not forced into duplicate targets.
- AC: pools are content-table edits only inside `generateContract.ts` — same seeded picks, same
  intel shape, determinism intact (I3); the Vitest pool mirrors are updated with the tables.
- AC: new names stay in-register (gothic-ecclesiastical epithets/sites; GLOSSARY terms respected).

## The seal

**R186** (client): the asserted-Origin wax seal is **retired from every contract surface**.
- AC: the compact writ carries **no** Origin seal — the petition-type badge is the only corner mark
  (plus the tack); the reader's asserted-Origin row is **text-only** ("Asserted <Origin>: <gloss>"),
  with the origin still intel (falsifiable claim), just no longer sealed.
- AC: the Origin seal art (`seal_belief/sin/relic.png`) is **archived** — moved to `art/archive/`
  (kept as source history, out of the client tree so the asset map carries no orphans);
  `gen_emblems.py` stops emitting it.

**R187** (client): the leader's stamp is **one generic Collegium seal**.
- AC: a new `seal_collegium.png` (painted wax disc + the Collegium device pressed/debossed, derived
  from the canonical `collegium_logo.png`) is emitted by `gen_emblems.py`; `wax_seal.gd` becomes the
  generic Collegium seal control (Origin keying retired; the faint-until-stamped / firm-once-sealed
  behavior of R124 is kept verbatim).
- AC: the reader's seal block renders this one seal for every contract; stamping still sends the
  same `SELECT_CONTRACT` / `DESELECT_CONTRACT` intents — zero wire/behavior change (P66 heritage:
  affordance is not authority).

## Cross-cutting

**R188** (containment): no protocol, phase, or game-logic change.
- AC: `src/shared` untouched; `src/server` diff is the two content tables (+ their test mirrors)
  only; no message shape changes; no trait axis appears anywhere new (P64 heritage).
- AC: dependency map regenerated (`seal_collegium.png` producer edge added; the three retired seal
  edges gone); server + shared suites green.

---

## Verification

Server (R185, R188): Vitest — `generateContract.test.ts` pool mirrors updated; determinism + intel
key-set tests still green; full server + shared suites green.

Client (R184, R186, R187): `--board-preview` captures (client-spec convention) —
- **V1 (R184):** a board capture shows 8 writs each reading "<Incarnate epithet> / at <place>".
- **V2 (R186):** no writ carries an Origin seal; the reader's origin row is text-only.
- **V3 (R187):** the reader's seal block shows the generic Collegium seal — faint for an unsealed
  charge, firm when the snapshot's contract matches (capture with `--reader`).
- **V4 (R188):** `git diff --name-only` touches only `client/ art/ specs/ docs/ CLAUDE.md
  src/server/` (tables + tests); asset-map `--check` passes.
