# Tasks — The Notice Board (procedural notices, sacred register)

> T# continues from T130 (station-ui). Order is dependency + phase order (A→D);
> each phase is shippable. Server/shared tasks name a Vitest file; client tasks name
> a `playtest.md` item (no GDScript unit harness — prior client-spec convention).
> Nothing is done without its named test passing.

## Phase A — Requester intel (server/shared)

- [x] T131 [R118 / P64] — Add `Requester` type and `requester: Requester` to
      `ContractIntel` (`src/shared/src/contract.ts`). Update the existing
      contract-shape tests to the new key set (now incl. `requester`).
      Test: `contract.test.ts` — `ContractIntel` has the expected keys incl.
      `requester`; still no `expeditionSeed`/`traitRoll`.

- [x] T132 [R119 / P67] — Add authored name/role/place tables + pure
      `pickRequester(rng)` to `generateContract.ts`; call it in `generateContract`
      (after `primaryVerb`, before `traitRoll`). Update `toContractIntel` key-count
      tests + the `snapshot.test.ts` board fixture/assertion to include `requester`.
      Test: `generateContract.test.ts` — determinism (same seed → same requester);
      requester fields non-empty (role/place) and anonymous case has `name === ""`;
      `toContractIntel` returns the intel keys incl. `requester`, none of
      `expeditionSeed`/`traitRoll` (P64). Fix any other `ContractIntel`/`ContractRecord`
      fixtures across the server/shared suites to add `requester`.

## Phase B — Procedural notice content (client)

- [ ] T133 [R120, R121 / P68] — New `client/scripts/ui/notice.gd` (preloaded):
      `headline(verb)` (sacred register), `charge(intel)` (verb synonym + locale +
      qualifier, moved/expanded from `main.gd`), `preamble(intel)`, `signature(req)`.
      All pure functions of intel + `contractId`.
      Verify: playtest item 1 — for each of the 4 verbs the correct headline logs;
      a notice's charge names the site and is verb-faithful; the signature renders
      `"<name>, <role> of <place>"` and the anonymous form; same contract → identical
      text across reopens.

## Phase C — Notice-board layout (client)

- [ ] T134 [R122 / P65] — Rebuild `_build_contract_board` as a seeded notice canvas
      (no ScrollContainer): full-board scatter via quadrant slots + `_seed_jitter`/
      `_seed_tilt`, dramatic seeded sizes (aesthetic, not tier), tack/texture variants,
      `WaxSeal` tack + `ThreatPips`; live notices drawn above flavor and clamped in
      frame, hover raises to front; carved `_notice_placard` header. Render the 4 live
      contracts as clickable notices + a `FLAVOR_NOTICES` table of inert aged notices.
      Remove the obsolete wall/desk/authorization-bar helpers. (TD-040.)
      Verify: playtest item 2 — board shows 4 live + N flavor notices filling the
      board with corner overlap; every live notice's headline/target is readable and
      clickable, flavor are inert (a click on flavor does nothing); `board live=4
      flavor=N` logs.

## Phase D — Read + authorization (client)

- [ ] T135 [R123] — `_open_notice` view state + `_build_notice_reader(intel)`: the
      enlarged parchment over a dim layer with headline/target/site/threat/preamble+
      charge/Archive line/signature; return-to-board dismiss. Pure view state.
      Verify: playtest item 3 — clicking a live notice enlarges it with full prose +
      signature; dismiss returns to the wall; nothing is sent on open/close.

- [ ] T136 [R124 / P66] — Seal block on the reader (revised TD-041): `_seal_block`
      renders one Origin wax seal, faint until sealed / firm once sealed, state from
      the snapshot's `contract`; the **local leader** stamps the faint seal →
      `SELECT_CONTRACT`, clicks the firm seal → `DESELECT_CONTRACT`; non-leaders see
      it read-only. `CONTRACT_SELECTION` drives a top-centre toast for the whole
      party. Raced `NOT_*`/`WRONG_PHASE` still surfaces.
      Verify: playtest items 4–5 (two clients) — the leader stamping seals the charge
      for everyone (toast + seal firm on both clients); clicking the firm seal lifts
      it (un-accepted toast); a non-leader has no stamp affordance; selection changes
      no phase. Logs `seal <contractId> accepted=<bool>`.

## Phase D-server — reversible selection & staged commit (TD-041)

> Numbered after T137 because task IDs are append-only; in dependency order these
> precede the client seal (T136). Implemented mid-build per DECISION_LOG TD-041;
> Vitest already green.

- [x] T138 [R127 / P69] — Redefine `SELECT_CONTRACT` reversible (no phase change) and
      add `DESELECT_CONTRACT` (`deselectContract.ts`, message registry + `protocol.gd`).
      Broadcast `LOBBY_UPDATED` + transient `CONTRACT_SELECTION { accepted, targetName,
      actorName }`. Deselect-with-nothing is an idempotent no-op.
      Test: `selectContract.test.ts` — reversible select stays WAITING, replace,
      `UNKNOWN_CONTRACT`/`INVALID_PAYLOAD`/`NOT_LEADER`/`NOT_AT_CONTRACT_BOARD` reject
      to sender only; `deselectContract.test.ts` — clears selection, no-op when empty,
      leader/at-board gates (P69). **Green.**

- [x] T139 [R128 / P70] — Two-stage `handleDeploy`: WAITING = commit (requires a
      selection else `NO_CONTRACT_SELECTED`; → DEPLOYING, broadcast `ROOM_DEPLOYING`,
      no `FIELD_STARTED`); DEPLOYING = unchanged launch → FIELD. Add
      `NO_CONTRACT_SELECTED` error code.
      Test: `deploy.test.ts` — commit with no selection → `NO_CONTRACT_SELECTED` (no
      mutation); commit with a selection → DEPLOYING + `ROOM_DEPLOYING`, no
      `FIELD_STARTED`; launch from DEPLOYING unchanged (P70). **Green.**

## Cross-cutting

- [ ] T137 [R118–R126] — Full MCP playtest pass: run `specs/notice-board/playtest.md`
      (all items) via `run_project` + `get_debug_output` against `pnpm dev:server`,
      two clients for the leader/non-leader and multi-seal paths; fix any GDScript
      errors; clean `stop_project`. Mark complete only when every item passes and the
      full server + shared suites are green.
      Verify: `playtest.md` all items green; `pnpm --filter @testament/server test`,
      `pnpm --filter @testament/shared test`, and `pnpm build` (tsc) pass.

# Pass 2 — Pixel-art reskin (spine-driven)

> Source of truth is the UX spine pair, not new R# IDs (this is a visual reskin, not a
> behavior change): `specs/notice-board/ux-designs/ux-Testament-2026-07-09/DESIGN.md`
> (§ = its sections) + `EXPERIENCE.md`, validated in `validation-report.md`. Tests are
> the **Pass-2 `playtest.md` items L1–L8** (client-spec convention: no GDScript unit
> harness — measured luminance / client self-check logs read via `get_debug_output`,
> plus eyeball). Behavior is UNCHANGED — these tasks only touch render (I1/I2 hold).
> Toolchain: **stdlib PNG generator** (no Pillow — settled), Aseprite, Godot 4.7.
> Order = dependency order; batching is **structure (T141–T142) → detail (T143–T144)**
> with the legibility/a11y **fix cluster (T145–T146)** landing alongside, then verify.

- [x] T140 [DESIGN § Colors, `pipeline`; P: palette-lock] — **Generator foundation.**
      `client/assets/ui/ashember.py` — a stdlib PNG toolkit carrying the locked **Ash &
      Ember** ramps (18 colours), RGBA per-pixel helpers (`noise`/`lerp_rgb`/`clamp`), the
      **grayscale-additive VFX** convention (`additive()` = white+alpha, tinted at
      runtime), a perceptually-weighted **`quantize()`** to nearest ramp, and
      **`assert_on_palette()`** (opaque pixels ∈ ramps; transparent + white-VFX exempt).
      Built as an imported foundation module (Batch generators `from ashember import …`)
      rather than editing Pass-1 `gen_board.py`, which T141/T142 supersede.
      Test: `python3 ashember.py` self-test — ramps distinct; `quantize` identity on locked
      colours + snaps near-colours; a quantized gradient is 100% on-palette; VFX exemption
      only under `allow_vfx`; PNG writer emits a valid signature. **Green.**

- [x] T141 [DESIGN § Components "Batch 1", Shapes, Layout] — **Structure assets.**
      `client/assets/ui/gen_structure.py` (imports `ashember`) emits 7 palette-locked PNGs:
      `board_frame.png` (64² carved 9-slice, mitred corners + iron studs), `board_backing.png`
      (48² plank 9-slice), `board_placard.png` (64×24 routed plaque 9-slice — Godot draws the
      gold text over it), `stone_tile.png` (48×32 tileable brick/mortar), `torch_flame.png`
      (4-frame grayscale-additive sheet), `torch_glow.png` (96² radial grayscale-additive),
      `torch_sconce.png` (iron bracket). Board art quantized to the ramps; flame/glow are
      white+alpha VFX sources (tinted in Godot). Project default filter = Nearest, integer scale.
      Test: `python3 gen_structure.py` — all `assert_on_palette` pass (VFX under `allow_vfx`);
      flame/glow alpha coverage sane; `run_project` parses clean (MCP), no import errors.
      Full on-board eyeball is T142. **Green.**

- [x] T142 [EXPERIENCE Game Feel, Foundation; DESIGN Elevation] — **Batch 1 integration.**
      Wire the structure assets into `_build_contract_board` (retire the greybox
      styleboxes); torch = `AnimatedSprite2D` flame + glow via `Light2D`/`modulate` tinted
      to the flame ramp; add the **reduced-motion toggle** pinning the glow to **peak**.
      Verify: playtest **L5** (reduced-motion keeps light), **L7** (palette/pixel/VFX
      integrity), **L8** (empty board); `board live=4 flavor=N` still logs; MCP clean.
      **Done:** captures at 1280×720 (int_scale=2, bars=0×0) show the carved 9-slice
      frame, stone backing, routed placard, four sealed parchment notices + aged flavor,
      and lit torches (flame+glow); F9/`--reduced-motion` capture pins the glow to peak
      with the flame frozen (L5); `board live=4 flavor=4` logs. L7 green.
      **Keep-out fit fix (folded in):** the live parchments overflowed their keep-out
      footprints — the `bg` `TextureRect` kept its default `EXPAND_KEEP_SIZE`, which floors
      the min size to the 182×118 source, so with `clip_contents=false` each paper spilled
      ~2× past its rect and buried its neighbours even though the solver's footprints were
      disjoint (`keepout ok=true`). Fixed by `EXPAND_IGNORE_SIZE` on the three parchment
      `bg` sites (live/flavor/reader) so the paper obeys the notice rect; capture confirms
      four disjoint, fully legible notices. L8 (empty board) is exercised at T146 (the
      fixture preview hardcodes 4 live). The scatter/keep-out solver (`_layout_live`/
      `_separate`) already lives here; T145's remaining scope (live-tone paper floor,
      per-notice backlight, ≥44px hit-target, self-check styling) stays open.

- [x] T143 [DESIGN § Components "Batch 2", Shapes] — **Detail assets.**
      Generate + finish: torn/**deckled parchment** variants (a few **pre-rotated** angles,
      live vs flavor tones), **tacks** (nail·wax·pin·ribbon), **cobweb** (grayscale
      additive), **votive**, **foxing/curl**. Refine `WaxSeal` to distinct Origin **sigil
      shapes** + a full-strength **faint ring**; add the **1px black outline** to
      `ThreatPips` (empty = hollow diamond).
      Verify: assets import clean; palette-membership check (T140 helper) passes; MCP clean.
      **Done:** `gen_detail.py` (imports `ashember`) emits 15 palette-locked PNGs —
      `parch_live_{0,1}`, `parch_flavor_{0,1}` (deckled, warm-inner-light live vs
      aged/foxed flavor) + 4 baked ±5° tilts, `tack_{nail,wax,pin,ribbon}`, `cobweb`
      (VFX grayscale-additive), `votive`, `foxing`; `assert_on_palette` passes for all
      (cobweb under `allow_vfx`). `wax_seal.gd`: full-strength black outer ring +
      `set_faint()` (fill washes toward parchment, ring+sigil stay firm) + thicker
      Origin sigils. `threat_pips.gd`: 1px `#12100C` outline on every pip, empty = hollow
      diamond. Verified by reader capture (`--board-preview --reader`): SIN seal reads as
      a firm disc with a pale inverted-cross sigil; APPRENTICE shows 3 filled + 2 hollow
      outlined pips. MCP clean, no import errors. Wiring the deckled paper/tacks/cobweb
      into the notice + reader is T144.

- [x] T144 [DESIGN § Components, Typography] — **Batch 2 integration.**
      Wire parchment/tacks/seal/pips/decay into the notice + reader; **headline in ink
      `#2A2115`** (never wax); live vs flavor tone split.
      Verify: playtest items **1–3** still green (prose/scatter/reader), **L2** (pips
      readable), and the reader shows ink headline + sigil seal.
      **Done:** `_parch_tex` (old `parch_card`) retired; notices load the deckled
      `parch_live` (live) / `parch_flavor` (aged) split and the reader loads `parch_live`
      — all `TEXTURE_FILTER_NEAREST`, which kills the old reader blur. Each live notice
      gets a seeded `_notice_tack` (nail·wax·pin·ribbon) pinning its top edge; the Origin
      `WaxSeal` moved to a lower-right corner badge (`_wax_seal(origin, corner=true)`);
      `_add_decay` tucks a grayscale-additive cobweb + a votive into corners proven clear
      of live footprints (`_decay_clear`). Headline stays `INK`. Captures: board shows 4
      disjoint deckled notices with tacks + corner seals (keepout ok=true); reader shows
      crisp deckled paper, ink headline, cross-sigil seal, and 3-filled/2-hollow pips
      (L2). MCP clean, no import errors.

- [ ] T145 [DESIGN § Layout, Colors "Contrast floor"; EXPERIENCE Accessibility] —
      **Legibility cluster (layout).** Per-notice **local backlight** + **live-tone floor**
      (paper ≥ `#CBB583`, never shadow); the **keep-out rectangle** scatter algorithm
      (headline/target/seal/pip band un-overlapped), **≥44×44** min live hit-target, and
      decay props bound to corners empty of live anchors. Client **logs a keep-out
      self-check** (`keepout seed=<s> ok=<bool>`) for MCP verification.
      Verify: playtest **L1** (headline+body ≥4.5:1 composited, measured, worst-case seed),
      **L3** (backlight not torch-dependent), **L4** (keep-out self-check + eyeball).

- [ ] T146 [EXPERIENCE State Patterns, Accessibility, Voice] — **A11y + state cluster.**
      Keyboard **focus** traversal (Tab = reading order) + gold focus ring + Enter/Space;
      **empty-board** presentation; **error surface** on the top-centre toast
      (`NOT_*`/`WRONG_PHASE`/`NO_CONTRACT_SELECTED`); **pressed/in-flight** + faint-ring
      seal states; captions bound to role/state; drop any off-register label.
      Verify: playtest **L6** (focus/keyboard + hit-target), **L8** (empty board), raced
      error appears on the toast (two-client eyeball).

- [ ] T147 [DESIGN + EXPERIENCE; validation-report] — **Pass-2 verification pass.**
      Run `playtest.md` **L1–L8** on a worst-case seed (measured items sampled, not
      eyeballed) via `run_project` + `get_debug_output`, two clients; fix any GDScript
      errors; clean `stop_project`. Confirm every `validation-report.md` finding is
      addressed or consciously deferred.
      Verify: L1–L8 green; behavior items 1–6 still green; `pnpm --filter @testament/server
      test` + `pnpm --filter @testament/shared test` + `pnpm build` pass; MCP clean.
