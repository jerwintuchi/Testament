# Design — Writ format & the Collegium seal

> Satisfies R184–R188. Client render + generated art + server content tables; no protocol/logic
> change (I1–I5). Logged TD-060. Verified by Vitest (server) + `--board-preview` captures (client).

---

## The shape of the change

The writ's two-line format ("<target> / at <site>") was never wrong — the *data* shown in preview
was: `_PREVIEW_BOARD` used place names as targets, so the wall read "location at location". The fix
is content, not layout: fixture targets become Incarnate epithets matching the server's register,
and the server's 4-entry pools grow so a real 8-writ board isn't forced into duplicates.

The Origin wax seal goes. It asserted a genus with the confidence of a stamped certainty — but the
petition-type badge already carries the writ's glanceable read, and Origin is a falsifiable *claim*
that belongs in the reader's prose, not pressed in wax. The seal **mechanic** (R124's reversible
leader stamp) survives with a better referent: one generic **Collegium seal** — the order taking up
a charge, not the contract asserting a truth.

## R184/R185 — the format (fixture + pools)

- `_PREVIEW_BOARD` (`main.gd`): the eight `targetName`s re-authored as epithets in the server's
  idiom — e.g. "The Hollow Vicar", "The Drowned Choir", "The Unquiet Pilgrim", "The Grey Shepherd",
  "The Sunken Congregant", "The Gallows Warden", "The Ember Cantor", "The Weeping Reliquary".
  Sites/requesters stay. (The fixture mirrors `toContractIntel` shape exactly, as before.)
- `generateContract.ts`: `TARGET_NAMES` and `SITE_NAMES` grow 4 → 8+ authored entries (epithets /
  sites in-register). Pure table growth: `rng.pick` is unchanged, so determinism (same seed → same
  contract) holds by construction (I3). `generateContract.test.ts` mirrors the pools verbatim —
  update the mirrors; every other assertion (determinism, key set, trait containment) is untouched.

## R186 — retire the Origin seal

- **Writ** (`_make_notice` block, `main.gd` ~1510): drop `card.add_child(_wax_seal(origin, true))`;
  the corner furniture is tack + verb badge only. The now-unused `_wax_seal` helper is removed.
- **Reader** (`_build_notice_reader`): the `org_row` loses its `WaxSeal` child; the row becomes the
  plain text label "Asserted <Origin>: <gloss>" (same position, same ink).
- **Art**: `seal_belief/sin/relic.png` (+ their `.png.import` files) move to `art/archive/`;
  `gen_emblems.py` stops emitting them (the `make_seal`/`_sig_*` painting code moves out with a
  pointer comment — the archive holds both the PNGs and their provenance).

## R187 — the generic Collegium seal

- `gen_emblems.py` gains `make_collegium_seal()`: a 48×48 painted wax disc (the SIN-red wax ramp is
  retired with the origins; the Collegium seal takes a neutral **bone/ivory-on-oxblood** wax so it
  reads as the order's, not a genus hue) with the **Collegium device debossed** — the emblem
  luminance is PIL-read from `collegium_logo.png` (the gen_banner.py producer-edge pattern: PIL to
  read, `ashember.write_png` to emit) and pressed as a darkened relief into the wax under the
  standing upper-left key light. Emits `seal_collegium.png`; provenance header updated
  (`@consumes collegium_logo.png`).
- `wax_seal.gd` becomes the generic control: the `SEAL_TEX` origin dict and `set_origin` are
  retired; the texture is the one `seal_collegium.png`, loaded on first draw; `set_faint` (fill
  fades, rim ring stays) is kept verbatim — the R124 faint/firm semantics are behavior, not skin.
- `_seal_block` (`main.gd`): drops its `origin` read; `WaxSeal.new()` + `set_faint` as today. The
  captions, focus/keyboard handling, in-flight disable, and SELECT/DESELECT wiring are untouched.

## Correctness Properties

- **P107 (format is creature-at-place, R184/R185):** every rendered writ's lead line is an
  Incarnate epithet drawn from intel `targetName`; no fixture or authored pool entry names a
  settlement as a target.
- **P108 (seal mechanic unchanged, R186/R187):** retiring the Origin skin changes zero behavior —
  the seal block still derives sealed-state from the snapshot's `contract`, still sends only
  `SELECT_CONTRACT`/`DESELECT_CONTRACT`, still renders read-only for non-leaders (P66 heritage).
- **P109 (containment, R188):** `src/shared` untouched; the `src/server` diff is content tables +
  test mirrors only; no new wire data; determinism (I3) and trait containment (I5) hold.

## Files touched

Edited: `client/scripts/main.gd` (fixture epithets; writ + reader seal removal; `_seal_block`
generic), `client/scripts/ui/wax_seal.gd` (generic Collegium control),
`client/assets/ui/gen_emblems.py` (emit `seal_collegium.png`; retire seal emission),
`src/server/src/incarnate/generateContract.ts` (+`.test.ts`) (pool growth),
`docs/technical/asset-map.md` (regenerated), `docs/DECISION_LOG.md` (TD-060), `CLAUDE.md` (active
spec). New: `client/assets/ui/seal_collegium.png`, `specs/writ-format/*`, `art/archive/seal_*.png`
(moved). Deleted from client tree: `seal_belief/sin/relic.png` (+imports).
