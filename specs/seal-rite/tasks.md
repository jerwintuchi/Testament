# Tasks — The seal rite (TD-062)

> T# continues global from T206 (contract-reader). Client render only — tests are `--board-preview`
> captures (client-spec convention) + author playtest for the interactive/animated items. Order:
> fit correctness first (a live bug), then the seal look/word, then behavior, then ceremony.

- [x] T207 [R196 / P113 / V1] — **Fit the line spacing.** `_fit_writ` adds the Label
      `line_spacing` per wrapped line (target + site independently) + 2px safety; fixture sites
      adopt the longest authored server names so preview exercises the failure.
      Test: **V1** — board capture: every site line whole (incl. "at The Gall Road Ossuary");
      `keepout ok=true hit_ok=true`.

- [x] T208 [R197 / V2] — **Round the seal.** `wax_seal.gd` draws the texture in a centred square
      (min dimension), both states; ring concentric.
      Test: **V2** — reader captures (faint + `--sealed`) show a circular seal.

- [x] T209 [R198 / V3] — **The oath + tooltip.** Leader captions become the named-target oath
      (name from `_display_name_plain(_self_id)`, fallback "Seeker"); instructions move to
      `tooltip_text`; non-leader keeps the party forms; popup theme styles `TooltipPanel`/
      `TooltipLabel` to the scene.
      Test: **V3** — unsealed + `--sealed` reader captures show the oath lines, no parenthetical
      instruction on the sheet.

- [x] T210 [R199 / P114 / V4] — **Preserve the scroll across stamps.** `_reader_open_cid` +
      `_reader_scroll_mem`; same-cid rebuild restores the offset, fresh open pins top, close
      clears; `_reset_reader_scroll` generalised to a target value (`--reader-foot` rides it).
      Test: **V4** — author playtest: stamp at the foot stays at the foot. (Static check: a
      `--sealed --reader-foot` capture still lands at the foot.)

- [x] T211 [R200 / P115 / V5] — **The press + wax flash.** `_seal_prev` transition detection;
      `_animate_seal`: drop-in press + squash + additive radial flash + 2px sheet nudge on stamp;
      firm→faint peel on lift; reduced-motion skips to end state.
      Test: **V5** — author playtest for the motion; `--reduced-motion --sealed` capture shows the
      plain end state (no flash residue).

- [x] T212 [R196–R201 / V6] — **Verification pass.** V1–V6; asset-map `--check`; suites
      untouched-green; diff scope; refresh the board preview artifact; append DECISION_LOG TD-062;
      swap the active spec in CLAUDE.md.
