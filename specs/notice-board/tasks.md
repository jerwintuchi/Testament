# Tasks — The Notice Board (procedural notices, sacred register)

> **STATUS: CLOSED 2026-07-24.** The Contract Board shipped and is signed off by the author
> ("the contract board … is already done and good"). What remained open here was **stale** — it
> described a scatter board with threat pips under a palette lock, none of which survive. The
> superseded items are marked in place with what replaced them rather than deleted, so the trail
> from requirement to shipped code stays walkable; `requirements.md` + `design.md` stay as the
> record for R118–R128, which shipped client code and the live server handlers still cite.
> The one genuinely unfinished thing is a **two-client manual playtest**, which needs a second
> client the capture harness does not have. See DECISION_LOG TD-074.
>
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

## Phases B–D — client render — **CLOSED (superseded, not abandoned)**

> **T133–T136 shipped, then were rebuilt past recognition.** Everything these tasks asked for
> exists and works; the *descriptions* below no longer match the code, because the board was
> redesigned three times after they were written. Re-running them verbatim would verify a board
> that does not exist. Closed 2026-07-24 on the author's call ("the contract board … is already
> done and good"). Where the work actually lives now:
>
> | asked for | shipped as |
> |---|---|
> | T133 `ui/notice.gd` — headline/charge/preamble/signature | `client/scripts/board/notice.gd`; grew `plea(intel)` when TD-061 retired the threat pips |
> | T134 seeded full-board **scatter** + `ThreatPips` + `_notice_placard` | **superseded**: the framed **grid** (TD-040) replaced the scatter, the carved sign (TD-053/058) replaced the placard, the pips are **deleted** (TD-061), and flavor scraps are opt-in behind `--flavor`. The wall now lives in `board/contract_board.gd` + `board/notice_card.gd` (TD-067 T231) |
> | T135 `_build_notice_reader` | `board/notice_reader.gd` (TD-067 T230) |
> | T136 the seal block | shipped, then far outgrew this spec: the named oath (TD-062), the press ceremony + party-wide `CONTRACT SEALED` banner (TD-063), the unclipped flash + spam lockout (TD-064), the targeted reader refresh (TD-065), the overlay swap (TD-068) |
>
> The **requirements** (R118–R128) and **design** stay in this folder as the record: they are
> cited from shipped client code (`notice.gd`, `wax_seal.gd`, `main.gd`) and they document the
> server behaviour that is still live and still tested (T131/T132/T138/T139, green).

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

## Cross-cutting — **CLOSED**

- [~] T137 [R118–R126] — Full MCP playtest pass. **Closed as superseded**: `playtest.md` items 2
      (scatter), and Pass-2 L2 (threat pips) / L7 (palette lock) describe things that have since
      been deleted or retired, so the document cannot be run as written. The one item it holds
      that is still real and still unrun is the **two-client** path (leader/non-leader seal
      split, the `CONTRACT_SELECTION` broadcast, staged deploy) — that survives as a standing
      manual playtest, not as a task here, because the capture harness has no second client.
      Server-side, all of it is covered by Vitest (`selectContract` / `deselectContract` /
      `deploy`, 362 green).

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

- [x] T145 [DESIGN § Layout, Colors "Contrast floor"; EXPERIENCE Accessibility] —
      **Legibility cluster (layout).** Per-notice **local backlight** + **live-tone floor**
      (paper ≥ `#CBB583`, never shadow); the **keep-out rectangle** scatter algorithm
      (headline/target/seal/pip band un-overlapped), **≥44×44** min live hit-target, and
      decay props bound to corners empty of live anchors. Client **logs a keep-out
      self-check** (`keepout seed=<s> ok=<bool>`) for MCP verification.
      Verify: playtest **L1** (headline+body ≥4.5:1 composited, measured, worst-case seed),
      **L3** (backlight not torch-dependent), **L4** (keep-out self-check + eyeball).
      **Done:** `_floor_tone()` clamps every live-paper modulate to ≥`#CBB583`, and the live
      stack (backlight+shadow+card) now draws at `LIVE_Z=3` **above** the wall vignette so a
      writ never sinks into shadow (the vignette shapes the wall, not the writs — its own
      stated intent). Per-notice warm **additive** backlight (`BoardGeo.backlight_gradient`)
      makes legibility torch-independent (L3). `HIT_MIN=44` floors the interactive size; the
      self-check logs `keepout live=N ok=<bool> minhit=WxH hit_ok=<bool>`. **L1 measured
      analytically** (floor-enforced ⇒ every notice): INK on `#CBB583` = **7.90:1**, INK_SOFT
      = **6.32:1**, both ≥4.5:1. **L4**: `keepout live=8 ok=true minhit=93x60 hit_ok=true`,
      board captures show 8 disjoint legible writs incl. corners. **L3**: capture shows each
      writ in its own warm halo, distinct from the gutter torches. Client-only.

- [x] T146 [EXPERIENCE State Patterns, Accessibility, Voice] — **A11y + state cluster.**
      Keyboard **focus** traversal (Tab = reading order) + focus mark + Enter/Space;
      **empty-board** presentation; **error surface** on the top-centre toast
      (`NOT_*`/`WRONG_PHASE`/`NO_CONTRACT_SELECTED`); **pressed/in-flight** + faint-ring
      seal states; captions bound to role/state; drop any off-register label.
      **Done** — shipped incrementally across TD-046/062/064/065 and ticked here 2026-07-24 on
      an audit of the live code, not on assertion. Where each piece is: writs are
      `FOCUS_ALL` Buttons in a `live_notice` group, walked by Tab in geometric reading order
      (`ContractBoard.focus_first`, restored across rebuilds by contractId), and marked by a
      **corner-bracket reticle** rather than a stylebox ring (`NoticeCard._focus_reticle`) —
      the gold ring named in the original task was rejected because it fought the flat card
      states. Empty board renders "The wall stands empty." above the vignette. Raced errors
      surface **where the leader is looking**: `LOBBY_ERROR` while the board is open raises the
      board's own toast, not just the far status line (`main.gd`, the `T146` comment). The seal
      carries `disabled` (non-leader **and** cooldown), pressed, and a leader-only focus ring,
      with captions bound to role/state — the leader's named oath vs. "Awaiting the leader's
      seal." The `44x44` hit floor self-checks every build (`hit_ok=`).

- [x] T147 [DESIGN + EXPERIENCE; validation-report] — **Pass-2 verification pass.**
      **Closed 2026-07-24, partly verified and partly obsolete** — stated honestly rather than
      ticked whole:
      - **L1 (contrast floor) — MEASURED, and this time off a real composited capture**, not the
        analytic floor-enforcement argument T145 settled for. Sampling each of the 8 writs'
        text band (darkest ~1.2% = glyph cores vs. brightest 20% = lit paper, WCAG relative
        luminance): **6.76:1 worst** (The Weeping Reliquary), 9.28:1 best, all eight ≥ 4.5:1.
      - **L4** `keepout live=8 ok=true`, **L6** `minhit=80x53 hit_ok=true`, **L8** empty board,
        **L3** per-notice backlight — all green on capture.
      - **L5** reduced motion keeps the light — green (glow pinned, flame frozen to `_static_flame`).
      - **L2 — OBSOLETE.** Threat pips were **deleted** in TD-061 ("no knowledge as a number"
        applies to the Collegium's paperwork too); danger now reads as the petitioner's dread.
        There is nothing left to measure.
      - **L7 — OBSOLETE.** The 15-colour palette lock was **retired** in TD-046; 24-bit painted
        ramps are the norm. The check it describes would fail by design.
      - The two-client items stay a standing manual playtest (see T137).

