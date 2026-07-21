# Requirements — Seal refresh (targeted reader update + robust cooldown)

> Phase 5, Contract Board fix on the user's playtest of TD-064 (TD-065). Two defects survived: (1)
> the seal **can't be re-stamped/lifted after the first stamp** until the contract is closed and
> reopened — the cooldown's re-enable never fires; (2) the **stutter persists** on stamp/lift — the
> texture memoization didn't remove the frame hitch.
>
> **Root causes (verified in code):**
> - **Stuck cooldown:** the re-enable timer runs for `cool_left/1000 s` measured AFTER the ~round-
>   trip, so it fires a few ms BEFORE `_seal_cooldown_until`; the strict `now >= _seal_cooldown_until`
>   recheck then fails and never retries — the button stays disabled until a fresh open.
> - **Stutter:** every stamp/lift triggers a **full `_build_contract_board` rebuild** — which calls
>   `BoardDecor.add_torches` (frees + recreates 2 sconces, 2 CPUParticles flames, 2 glows, 2 banner
>   sprites) and rebuilds all 8 notices + the reader. Caching the textures didn't touch that node
>   churn. The seal only ever lives inside the OPEN reader, so a stamp never needs the board rebuilt.
>
> Client render only (I1/I2) — stamping still sends the same intents (P66). Numbering continues
> global: **R211+**, correctness **P120+**, tasks **T222+**. Logged **TD-065**. Verified by author
> playtest (interactive) + `--board-preview` captures.

---

## The rebuild

**R211** (client): a stamp/lift refreshes **only the open reader**, not the whole board.
- AC: when a `LOBBY_UPDATED` for the contract board arrives while a notice is **open** (the only way
  to stamp), the client rebuilds **just the reader overlay** (dim + reader + seal block + ornament)
  in place — it does **not** rebuild the board notices, backing, decay, or the torches
  (`add_torches` is not called), so there is **no frame hitch**.
- AC: the seal's faint↔firm state, the stamp/lift animation, and the scroll-position continuity
  (R199) all still work through the targeted refresh; the `CONTRACT SEALED` banner still fires.
- AC: when the reader is **closed** (grid view — a non-stamp lobby update: ready-toggle, join), the
  existing full rebuild still runs (no animation is in flight there). No behavior regresses.

## The cooldown

**R212** (client): the stamp/lift lockout is **robust** — it never sticks and always prevents spam.
- AC: the spam prevention is a **hard time-guard in the click handler** (a click while
  `Time.get_ticks_msec() < _seal_cooldown_until` is ignored — sends nothing), independent of any
  button-disabled state, so the lockout cannot be defeated and cannot get stuck.
- AC: the button's disabled state during the window is **visual only** and always re-enables — the
  re-enable is unconditional after the timer (no strict deadline recheck that can miss by a frame),
  with a small buffer, guarded by `is_instance_valid`.
- AC: affordance ≠ authority (P66/P119): the guard never substitutes for the server check — a raced
  `NOT_LEADER`/`WRONG_PHASE` still surfaces; non-leaders unaffected.

## Cross-cutting

**R213** (containment): client render only.
- AC: no `src/**` change; diff scope `client/ specs/ docs/ CLAUDE.md`; suites untouched-green;
  asset-map `--check` passes.

---

## Verification (author playtest + captures)

- **V1 (R211):** author playtest — stamping/lifting is smooth (no hitch); the seal animates, the
  banner fires, the scroll stays put. (Static: a `--reader --sealed` capture still renders the
  sealed reader correctly, and the board is unchanged.)
- **V2 (R212):** author playtest — after a stamp, the seal can be lifted again once the window
  (~0.9s) elapses **without** closing/reopening; rapid clicks fire at most one action per window.
- **V3 (R213):** diff scope; suites green; asset-map current.
