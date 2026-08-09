# Tasks — The Quartermaster's Feel (TD-102)

> T# continues global from T380. A polish pass on TD-101 — the data model, interaction flow and
> architecture are preserved. No `src/**` change.

- [x] T381 [R376, R373 / V2] — **Re-author the ten instrument icons in Aseprite.** Hand-placed
      pixels via 24×24 ASCII maps (TD-057: a shape function samples a curve and cannot decide which
      pixel carries a crossguard; TD-077 set the ASCII-stamp precedent). `.aseprite` + `.lua` source
      kept in `art/src/` so the author can edit them by hand.
      **The brief's "large conventional UI arrow" turned out to be an ICON, found by measuring:**
      `cantors-ear` was 204 opaque pixels in 4 colours dominated by `#A6803A`, the goldest object on
      the whole screen, and at 24px it read as a chevron. It is now a bronze horn seen side-on.
      Test: an audit over the sheet — **0 bright-gold pixels across all ten** (P168).
      Two first-pass failures caught by looking: the fetish read as a **brush** (parallel strokes;
      talons need a curve, a taper and unequal lengths) and the censer was the **brightest thing on
      screen** (flame belongs to the lantern and the seal, not a shelf item — now a dull ember).

- [x] T382 [R370] — **The wall stops competing.** 16px courses of 32px blocks repeat four times per
      64px tile and read as brick wallpaper. Now one course and one block per tile edge, the joint a
      two-pixel **recess** rather than a lit line, and one tonal step instead of two — contrast in
      the backdrop is contrast stolen from the instruments.

- [x] T383 [R371 / V1] — **The counter reads as worked at.** Two new props (sealing wax + stamp, a
      leaning stack of paperwork) and **three zones**: the Quartermaster writes on the left, the
      instrument is inspected in the middle, the sealing tools sit on the right beside the light.
      The centre stays clear because that is where the object lands. All scenery (P169).

- [x] T384 [R372] — **The plaque no longer sits on the stock.** The upper dressing row starts clear
      of the category plate; before, goods were drawn under a nailed-up sign and read as clutter.

- [x] T385 [R373] — **Hover takes a Collegium-gold edge.** Four one-pixel offset copies of the icon
      behind it, tinted gold and revealed on hover — readable at low resolution where a shader
      outline would smear, and built once so hovering allocates nothing. Costs 5 nodes per
      instrument (148 → 191 total, still inside the budget).

- [x] T386 [R374] — **The record gains hierarchy.** Name larger and in the heading face;
      classification in gold; and the handling note promoted to a **WARNING** block under its own
      heading in muted burgundy — unheaded it read as one more line of description. Every word still
      comes from `lore.gd`.
      The right column also grew from 0.72 to 0.80 of the frame: it was leaving dead black under the
      rite while the record — the thing with the most to say — was squeezed to 119px and hid its
      warning behind a scroll.

- [x] T387 [R375, R376] — **Status and departure.** `EXPEDITION PACK — n / 4` replaces the readout
      wording, and **SEAL & DEPART** is subdued at one-pixel border while the pack cannot be issued,
      taking gold and a doubled border when it can. Verified in both states by capture.

- [x] T388 [R377] — **Dust, budgeted.** 14 motes drifting through the candle's reach, declared as
      `Room.DUST_COUNT` so `qm_budget.py` can read it — a literal at the call site would be invisible
      to the budget, and the tool now fails if one appears.

- [x] T389 [R378 / V5] — **Containment.** No `src/**` change. **No shared surface touched**, so the
      Contract Board cannot be affected by construction — verified by `git status` rather than by an
      expensive re-diff. `qm_budget.py` green (now 10 checks incl. the emitter rule), `--selftest`
      green with every check proven to bite.

## The font (author ruled: fix it)

- [x] T390 — **`theme/custom_font` has never applied.** Godot's project-settings parser folds a
      preceding `#` comment block into the following key's name, so `project.godot`'s
      `gui/theme/custom_font` is not the key Godot reads and **the project default has silently been
      Godot's fallback sans since TD-097**. Proven twice: deleting the comment flips the Contract
      Board to Almendra (**29% of pixels differ**, `minhit` 80x53 → 80x51), and a re-import rewrote
      the folded key back out as one long garbage key.
      Call sites asking `Fonts.body()/heading()` were always fine; only the *default* was wrong —
      which is what CLAUDE.md's "the board's small text is the default sans" was recording.
      **FIXED on the author's ruling, and the board re-checked.** The comment is deleted; the key
      applies for the first time since TD-097, so the canon claim "Testament is set in Almendra" is
      now true in practice rather than only in the document.
      **Board verified, not assumed:** `keepout live=8 ok=true minhit=80x51 hit_ok=true`, all eight
      writs live and nothing clipped. Writs measure slightly SHORTER in Almendra (80x53 → 80x51), so
      the re-flow gained room rather than costing it.
      **⚠ THIS CHECK WAS WRONG, and the author caught it (see T391).** A 1× read suggested collapsed
      word spaces; magnifying to 3× I judged them merely narrow and moved on. I had magnified a line
      of CAPITALS and never looked at lowercase, where the real artifact was — gaps *inside* words.
      **A bonus fell out of it:** Almendra is narrower, so the Quartermaster record's note now fits in
      fewer lines and the **WARNING block is visible without scrolling** — which is what R374 wanted
      and T386 could not quite reach. The title screen is unaffected (it names its faces explicitly).
      **The rule that comes out of this:** `project.godot` must stay comment-free inside a section;
      the reasons live in `fonts.gd`, which a parser cannot corrupt.

- [x] T391 — **Words were breaking apart; `subpixel_positioning` was the cause.** With Almendra
      finally rendering the default, running text showed 1px gaps INSIDE words (`WA RNING`,
      `b etween`, `c annot`). Found by elimination against captures, not by theory:
      `keep_rounding_remainders=false` — no change; `hinting` 0/1/2 — no change at any value (it had
      been `3`, **out of range** for Godot's 0–2 enum, so undefined all along; now `0`);
      **`subpixel_positioning=0` was it** — disabled, every advance rounds to a whole pixel and
      Almendra's fractional advances at 7–9px accumulate into visible gaps.
      **Amends TD-077**, which was right about antialiasing and overreached about subpixel
      positioning: the two settings do different jobs, and only antialiasing costs crispness.
      `Almendra`/`Almendra-Bold` → `subpixel_positioning=1`; **`AlmendraDisplay` stays disabled**
      (ornament-only at ≥21px). **Antialiasing remains 0 everywhere** — title re-captured to prove
      the type is still hard-edged.
      Re-checked: board `keepout live=8 ok=true minhit=80x51 hit_ok=true`, legend and record both
      spaced correctly.
      **Method lesson:** to check whether text renders correctly, read **lowercase running text**, not
      a heading in capitals — capitals hide advance-rounding because their advances are wider and
      more uniform, which is exactly how this passed the first check.

## Rehaul — painted register + real light (TD-103, author brief)

- [x] T392 — **The room is lit by the Contract Board's own shader.** `board_surface.gdshader` exists
      precisely because `Light2D` cannot reach `Control` (TD-047), and it was already packing torch
      lights from a rig. `surface_material()` takes an **optional** `rig` (defaulting to the board's
      torches, so every existing call is byte-for-byte unchanged) and the stores pass a **candle
      rig**. Wall, shelving, planks and counter are now normal-mapped and lit: warm near the flame,
      falling to dark at the edges.
      **Candle and light share ONE source.** The first pass declared the light's position and placed
      the prop separately — the warm pool sat a tenth of a frame left of the flame casting it, and
      the candle floated seven pixels above the bench. `candle_pos()` is now authoritative and its
      VERTICAL position is *derived* from `COUNTER_Y`, because a candle stands on a surface.

- [x] T393 — **Surfaces repainted to the board's register.** Every surface now has a **height field**
      that drives BOTH its shading and its normal map, so paint and relief cannot disagree — which is
      what makes the board's wood read as carved. Lit arrises, pooled shadow, grain running along the
      plank, wear concentrated at the counter's front edge where forearms have rested (wear that is
      even reads as noise; wear with a cause reads as age).

- [x] T394 — **The gears remodelled with material and form.** Glyph letters now name a **substance**
      (glass, iron, brass, wood, bone, wax, flame) and a **form-aware shading pass** picks light, mid
      or dark from that substance's triple by looking at each pixel's neighbours: lit where nothing
      sits above-left, occluded where nothing sits below-right. That is how a pixel artist renders a
      small object, and it is why the previous set read as icons — every glyph was one flat tone
      inside an outline. 4–7 tones each, up from 3–5 flat. **Still zero bright-gold** (P168).

- [x] T395 — **Hover is an outline and nothing else** (author ruling). The lift and the warm tint are
      gone: an object that rises under the cursor reads as a UI element answering a mouse; one that
      catches an edge of light reads as an object the Quartermaster has noticed. It also stops the
      shelf twitching as the cursor crosses it, and now runs **no tween at all**.

- [x] T396 — **Containment.** `board_decor.gd` is shared and was touched, so the board was re-checked
      rather than assumed: `keepout live=8 ok=true minhit=80x51 hit_ok=true`, eight writs live. The
      `rig` parameter defaults to `torch_rig`, so the board's lighting call is unchanged. Budget holds
      at 191 nodes / 220 and 14 particles / 20; `qm_budget --selftest` green.

- [x] T397 [author ruling] — **Moodier interiors, and the candle pulled back.** The case backs were
      one near-black tone plus noise — a *void*, not a shadow. A shelf's interior is deepest at the
      top and lifts toward the foot, where the board beneath bounces light back up; that gradient
      (carried in the height field, so the normal map tilts with it) is what makes it read as a space
      an object stands **inside** rather than a hole cut in the wall.
      The candle's reach went **0.62 → 0.44**: at 0.62 it lit the whole left half of the frame
      evenly, which is bright but not atmospheric — **a light that reaches everywhere casts no shadow
      anywhere**. Still far wider than the board's 0.24 sconce, because a workroom must read as
      usable, but the shelves now fall off into dark with distance and the bench is plainly the lit
      place. Ambients down across the room (wall 0.30→0.22, shelf 0.20→0.13, plank 0.30→0.24,
      counter 0.38→0.32) and the flat vignette eased 0.34→0.26, since the light is doing that work now.
      **Deliberate exception:** the instruments themselves stay UNLIT sprites. Physically an object
      far from the candle should dim, but these are the things the player is being asked to browse
      and choose between — readability of the interactive objects beats strict lighting consistency,
      and the darker interiors give them *more* contrast, not less.

- [x] T398 [author ruling] — **A weak fill light at the shelf end, with a fixture to come from.**
      Two lights now: the candle (energy 0.9, reach 0.44) and a **lamp** (energy 0.34, reach 0.52,
      warm-neutral rather than a second flame — two equal candles would flatten the room again).
      The far instruments lift off black; the bench stays the lit place.
      **It has a visible source on purpose.** A fill with no fixture is a cheat, and the board
      couples every flame to its sconce (P95) — so `gen_qm_room.py` gained a small iron wall-lamp
      and the light is placed from the prop's position.
      **Corrected on the first capture:** hung at the shelf end the lamp was drawn BEHIND the
      shelving, which fills that whole side of the room — so the fixture was invisible while its
      light was not, which is exactly the cheat it was meant to avoid. It now stands on the bench's
      near end beside the paperwork (which shifted right to make room), with its feet derived from
      `COUNTER_Y` exactly as the candle's are, so neither can float.
      **`surface_material` gained per-light energy** (`t.get("energy", 0.9)`): the board's
      `torch_rig` sets no energy key, so it keeps the old hardcoded 0.9 and is unchanged by
      construction — but a room with a working light and a fill has to be able to say which is which.
      Board re-checked: `keepout live=8 ok=true minhit=80x51 hit_ok=true`. Budget 192 / 220.

## Regression, found by the author

- [x] T399 — **The Contract Board drew from the top-left corner with its header cut off, after
      visiting the Quartermaster.** A regression I introduced in **TD-101**, and NOT the font change
      I had been blaming layout shifts on.
      **Cause:** the stations share one popup. TD-101 made the Quartermaster ask for the whole
      viewport, and `custom_minimum_size` is a **floor, not a size** — setting a smaller one does not
      shrink a control already laid out larger. So the popup stayed viewport-sized, and
      `_slide_popup_in` centres with `(vp - _popup.size) * 0.5`, which for a viewport-sized popup is
      **(0,0)**. The board then rendered from the corner: header clipped by the screen edge, no
      gutters, no banners, Hall floor showing beneath.
      **Fix:** zero the shared popup's minimum AND its current size before each station applies its
      own, so every station gets the popup at ITS size rather than at the largest size any previously
      opened station asked for.
      **Why my checks missed it:** every board capture I took opened the board **directly**. A player
      does not — they walk the Hall and visit stations in sequence. New debug flag
      **`--board-after-qm`** opens the Quartermaster, closes it, then opens the board, which is the
      route that breaks it; it is kept as a standing regression guard for shared-popup state.
      Verified after: board-after-QM is identical to board-direct (frame, gutters, banners, header
      all present, `keepout live=8 ok=true`), and the Quartermaster and Deploy Gate still render
      correctly.

## Do not re-invent

- **The data model, capacity, flow and seal rite are TD-101's and are not re-opened.**
- **Gold is scarce** (R376/P168): selection, headings, insignia, seal, ready state. Nothing else.
- **Aseprite owns sprites; Python owns surfaces** (TD-057). Neither generates art in Godot at run
  time — every PNG is authored offline and imported Nearest.
- **`project.godot` must stay comment-free inside a section.** See T390.
- **Antialiasing off ≠ subpixel positioning off.** Text faces need Auto; only ornament keeps it
  disabled. See T391.
- **The stations share ONE popup.** `custom_minimum_size` is a floor; a station that grows it must
  not leave it grown. Capture stations **in sequence** (`--board-after-qm`), never only in isolation.
  See T399.
