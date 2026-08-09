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
      **A 1× read said the word spaces had collapsed** ("PETITIONTYPES"); magnifying to 3× showed
      they are present and simply narrower than the sans — a typographic difference, not a defect.
      Checked by looking closer instead of acting on the first impression.
      **A bonus fell out of it:** Almendra is narrower, so the Quartermaster record's note now fits in
      fewer lines and the **WARNING block is visible without scrolling** — which is what R374 wanted
      and T386 could not quite reach. The title screen is unaffected (it names its faces explicitly).
      **The rule that comes out of this:** `project.godot` must stay comment-free inside a section;
      the reasons live in `fonts.gd`, which a parser cannot corrupt.

## Do not re-invent

- **The data model, capacity, flow and seal rite are TD-101's and are not re-opened.**
- **Gold is scarce** (R376/P168): selection, headings, insignia, seal, ready state. Nothing else.
- **Aseprite owns sprites; Python owns surfaces** (TD-057). Neither generates art in Godot at run
  time — every PNG is authored offline and imported Nearest.
- **`project.godot` must stay comment-free inside a section.** See T390.
