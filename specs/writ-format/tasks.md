# Tasks — Writ format & the Collegium seal

> T# continues global from T194 (board-blend). Server tasks name Vitest; client tasks name a
> `--board-preview` capture check (client-spec convention). Order: server tables first (cheap,
> unblocks a real playtest), then the client format fix, then the seal retirement + generic seal,
> then verify. Containment: no protocol/logic change (P109).

- [x] T195 [R185 / P107, P109] — **Grow the authored pools.** `generateContract.ts`:
      `TARGET_NAMES` + `SITE_NAMES` 4 → 8+ in-register entries; update the pool mirrors in
      `generateContract.test.ts`.
      Test: `pnpm --filter @testament/server test` — pool-membership, determinism, intel key-set,
      and trait-containment tests green.

- [x] T196 [R184 / P107] — **Fixture epithets.** Re-author the eight `_PREVIEW_BOARD` `targetName`s
      as Incarnate epithets (server idiom); sites/requesters unchanged.
      Test: **V1** — a `--board-preview` capture shows every writ as "<epithet> / at <place>";
      nothing reads location-at-location.

- [x] T197 [R186 / P108] — **Retire the Origin seal.** Drop the writ's corner `_wax_seal` (and the
      helper); make the reader's origin row text-only. Move `seal_belief/sin/relic.png` (+imports)
      to `art/archive/`; stop emitting them from `gen_emblems.py`.
      Test: **V2** — board + reader captures show no Origin seal anywhere; asset-map regenerated
      with the three edges gone (no orphans).

- [x] T198 [R187 / P108] — **The generic Collegium seal.** `gen_emblems.py make_collegium_seal()`
      (bone-on-oxblood wax, Collegium device debossed, PIL-read from `collegium_logo.png`) emits
      `seal_collegium.png`; headless-import. `wax_seal.gd` → generic control (drop `SEAL_TEX`/
      `set_origin`, keep `set_faint`). `_seal_block` drops its origin read.
      Test: **V3** — `--board-preview --reader` capture shows the Collegium seal faint on an
      unsealed charge; sealed state (fixture `contract` set) shows it firm; captions unchanged.

- [x] T199 [R184–R188 / P107–P109] — **Verification pass.** V1–V4 by capture; asset-map `--check`;
      server + shared suites green; diff scope `client/ art/ specs/ docs/ CLAUDE.md src/server/`;
      refresh the board preview artifact; append DECISION_LOG TD-060; swap the active spec in
      CLAUDE.md.

## Notes

- The seal **mechanic** (R124 faint/firm, leader-only stamp, `SELECT_CONTRACT`/`DESELECT_CONTRACT`)
  is behavior under test elsewhere and does not change here — this is a skin + content pass.
- The Origin stays **intel**: the reader still says "Asserted <Origin>: <gloss>" in text. Only the
  wax assertion is retired.
