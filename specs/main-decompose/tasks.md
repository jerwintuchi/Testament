# Tasks — main.gd decomposition (TD-067)

> T# continues global from T224 (seal-refresh). Client render only; behavior-preserving — the named
> test is a `--board-preview`/`--rite-banner` capture compared to pre-change. Tranche 1 (T225–T228)
> is executed here; the remaining tranches (R217–R219) are queued as their own future commits.

## Tranche 1 — shared UI builders + the rite banner

- [x] T225 [R216 / P122 / V1] — **`ui/fonts.gd`.** Move `_cinzel` → `Fonts.cinzel`; preload in
      `main.gd`; update `_engraved_line`; delete `_cinzel`.
      Test: **V1** — headless parse clean; a `--board-preview` capture shows the header still in
      Cinzel (identical).

- [x] T226 [R216 / P122 / V1] — **`ui/popup_theme.gd`.** Move `_build_popup_theme` + `_btn_box` →
      `PopupTheme.build` (`_btn_box` private static); preload; update the theme assignment; delete
      both.
      Test: **V1** — a `--board-preview` capture shows the popup's gothic frame + gold controls +
      scene-tint tooltip unchanged.

- [x] T227 [R216 / P122 / V1] — **`ui/rite_banner.gd`.** Move `_show_rite_banner` +
      `_rite_band_gradient` → `RiteBanner.show(host, title, sub, reduced_motion)` + `_band_gradient`
      (uses `Fonts.cinzel`); preload; update the two `CONTRACT_SELECTION`/preview call sites (+
      `.call_deferred(self, …)`); delete both.
      Test: **V1** — a `--rite-banner` capture shows `CONTRACT SEALED` + subline unchanged.

- [x] T228 [R215, R220 / V1, V2] — **Tranche-1 verify.** Headless parse clean; board + rite-banner
      captures identical to pre-change; regenerate asset-map + `--check` (new `preload` edges);
      `git diff` scoped `client/ specs/ docs/`; server + shared suites green (untouched); commit;
      append DECISION_LOG TD-067; set active spec.

## Queued tranches (their own future commits — R217–R219)

- [x] T229 [R217 / P122 / V1, V2] — `ui/widgets.gd`: `_card_label` (20 refs), `_h1`, `_hrule`,
      `_focus_ring`, `_engraved_line`. Mechanical but many call sites; its own commit.
      `h1` takes the host (`Widgets.h1(_root, text)` — the builds-on-a-host idiom), the rest are
      pure static factories; `engraved_line` carries its own `Fonts` preload. `main.gd`
      2,538→2,475 (−63).
      Test: **V1** — headless parse clean; a `--board-preview` capture is composition-identical to
      HEAD (compared against a worktree build of 1c2204f: same header engraving, notices, hrules,
      legend bar; the only deltas are the torch particles and which card holds hover-focus, both
      nondeterministic run-to-run — a same-build control run differs the same way). A default
      `--capture` shows the menu `h1` unchanged. **V2** — asset-map regenerated + `--check` green;
      `git diff` scoped `client/ specs/ docs/`; server 362 + shared 65 green (untouched).
- [x] T230 [R218 / P122 / V1, V2] — `board/notice_reader.gd`: the reader + seal + `_animate_seal` +
      `_spawn_seal_flash` + cooldown + scroll continuity (the delicate TD-062/64/65 logic).
      Shipped as a **preloaded RefCounted with static builders**, not a scene: the reader is
      TRANSIENT (built on open, freed on close, rebuilt in place on a stamp), so it follows the
      `BoardDecor.add_torches(host, …)` idiom. Its memory (open cid, scroll offset, seal-prev,
      cooldown) moved with it as **static state**, because it IS reader state. The shell keeps the
      socket (S3.5): a `Ctx` carries snapshot/leader/parch/etc. in, and `on_seal`/`on_dismiss`
      callbacks carry intents out, so the module never touches `_net`. `main.gd` 2,919→2,545 (−374).
      `INK`/`INK_SOFT` promoted to `Widgets` (shared by the wall writs and the reader) rather than
      duplicated. Preserves TD-068's fast path — `show()` still attaches one named `ReaderOverlay`.
      Test: **V1** — headless parse clean; captures verified for **unsealed** (dashed socket + the
      leader's named oath), **sealed** (firm oxblood wax, device debossed, witnessed caption),
      **foot** (scroll pin), **reader-cycle** (open→close, `board live=` once — TD-068 intact) and
      the **flash** (warm bloom reading *past the sheet edge*, i.e. still unclipped per TD-064).
      **V2** — asset-map + `--check`; no `src/**` change.
      Two things worth recording: `_origin_word` was almost re-written as `capitalize()`, which is
      NOT what the original did — caught before it shipped, and the verbatim `substr` form restored
      (P122 means verbatim, not equivalent-looking). And `--flash-preview` now **loops** the bloom:
      it lasts ~0.76s while the capture harness takes whole seconds, so a one-shot flash was never
      catchable on film and had only ever been verified by "it did not error", which is not
      verification.
- [ ] T231 [R219] — `board/contract_board.gd`: the board shell driven by the snapshot, emitting
      intents via signal; `main.gd` delegates. The largest extraction; leaves `main.gd` a thin router.

## Notes

- Behavior is byte-for-byte unchanged per tranche (P122) — if a capture differs, the extraction was
  not verbatim; fix the move, don't "improve" it here.
- A tranche that would change behavior is out of scope — file a separate spec for the change.
