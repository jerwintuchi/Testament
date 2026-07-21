# Requirements — The seal rite (writ-fit correctness, the round seal, the oath, the stamp)

> Phase 5, Contract Board polish on the user's playtest review (TD-062). Five defects/asks on the
> TD-061 board: (1) long texts **still clip** the writ foot ("at The Gall Road Ossuary" loses
> "Ossuary") — the fit measurement missed the Label's per-wrapped-line `line_spacing`; (2) the wax
> seal renders **stretched into an oval** (the control is taller than wide and the texture fills
> the whole rect); (3) the seal captions are dry UI instructions — the author wants a first-person
> **oath**; (4) stamping/unstamping **resets the reader's scroll to the top** (the snapshot rebuild
> re-pins it); (5) the stamp deserves a **ceremony** — a press-and-flash animation.
>
> **User rulings (do not re-litigate):** oath = the **named-target** form — unsealed leader:
> *"I, \<name\>, take up the charge against \<target\>. Let it be witnessed."*, sealed: *"It is
> witnessed. \<target\> is ours to answer."*; the how-to instruction moves to a **hover tooltip**;
> animation = **press + wax flash** (seal drops, squash on impact, warm radial flash, sheet nudge),
> skipped under reduced-motion.
>
> Client render only — no server/shared change (I1/I2); stamping still sends the same intents
> (P66). Numbering continues global: **R196+**, correctness **P113+**, tasks **T207+**. Logged
> **TD-062**. Verified by `--board-preview` captures + author playtest (animation).

---

## The writ fit (correctness)

**R196** (client): `_fit_writ`'s measurement matches the Label's real rendered metrics.
- AC: the measured height adds the Label theme's `line_spacing` for every wrapped line beyond the
  first (target and site independently), plus a small safety margin — no writ text ever clips at
  the sheet edge, including the longest authored server names ("at The Gall Road Ossuary", "at
  Hollowmere Crossing").
- AC: the `--board-preview` fixture adopts the longest server site names so the failure case is
  capture-verifiable without a live server; measure == render still holds (P111 heritage).

## The seal

**R197** (client): the wax seal renders **round**, never stretched.
- AC: `wax_seal.gd` draws its texture in a centred **square** (side = min of the control's
  dimensions), aspect preserved, for both faint and firm states — the seal is a circle at any
  control size; the faint ring stays concentric with the wax.

**R198** (client): the caption is the leader's **oath**; instructions become tooltips.
- AC: leader, unsealed: *"I, \<name\>, take up the charge against \<target\>. Let it be
  witnessed."* — `<name>` = the local Seeker's lobby display name (fallback "Seeker" when absent,
  e.g. preview); tooltip: *"Click the seal to stamp it"*. Leader, sealed: *"It is witnessed.
  \<target\> is ours to answer."*; tooltip: *"Click the seal to lift it"*.
- AC: non-leaders read the party form: unsealed *"Awaiting the leader's seal."*, sealed *"It is
  witnessed. \<target\> is ours to answer."* — no tooltip (their seal is read-only).
- AC: the tooltip is themed to the scene (dark panel, parchment-tone text), not Godot's default
  grey.

## The reader

**R199** (client): stamping/unstamping **preserves the reader's scroll position**.
- AC: a snapshot-driven reader rebuild for the SAME open notice restores the previous scroll
  offset (the stamp stays under the pointer); the pin-to-top happens only on a **fresh open** of a
  notice. Closing the reader clears the memory.

**R200** (client): the stamp and the lift are **animated** (press + wax flash).
- AC: on seal (faint→firm transition observed between rebuilds): the seal drops in (scale ~1.8→1.0,
  ease-in), squashes on impact, a brief warm **additive radial flash** blooms and fades, and the
  sheet nudges ~2px; on lift (firm→faint): the seal peels up (scale up + fade) and settles faint.
- AC: `--reduced-motion` (and the F9 toggle) skips straight to the end state — the light/state is
  load-bearing, only the ceremony is decorative (L5 heritage). The animation renders no new
  information and emits nothing (P66: affordance ≠ authority is untouched).

## Cross-cutting

**R201** (containment): client render only.
- AC: no `src/**` change; the seal block still derives state from the snapshot's `contract` and
  sends only `SELECT_CONTRACT`/`DESELECT_CONTRACT`; diff scope `client/ specs/ docs/ CLAUDE.md`;
  suites untouched-green; asset-map `--check` passes.

---

## Verification (`--board-preview` captures + author playtest)

- **V1 (R196):** a board capture with the long-site fixture shows every writ's full site line
  inside its sheet ("Ossuary" whole); `keepout ok=true hit_ok=true`.
- **V2 (R197):** a reader capture shows a circular seal (faint and firm — `--sealed`), no oval.
- **V3 (R198):** reader captures show the oath (leader form with the fixture target) unsealed and
  sealed; the caption carries no parenthetical instruction (it lives in the tooltip).
- **V4 (R199):** author playtest — stamping with the reader scrolled to the foot leaves the scroll
  at the foot (no jump to top).
- **V5 (R200):** author playtest — the press/flash on stamp and the peel on lift; reduced-motion
  capture shows end states only.
- **V6 (R201):** diff scope client/specs/docs/CLAUDE.md; suites green; asset-map current.
