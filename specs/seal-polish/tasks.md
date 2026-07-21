# Tasks — Seal polish (TD-064)

> T# continues global from T217 (seal-ceremony). Client render only — tests are `--board-preview`
> captures + author playtest. Order: cache (frames the smoothness), then the flash overlay, then the
> cooldown, then verify.

- [x] T218 [R208 / P118 / V2] — **Memoize the board textures.** Add static caches to
      `BoardGeo.wood_grain_texture`, `vignette_gradient`, `curl_gradient`, `backlight_gradient`,
      `additive_material` (bodies → `_build_*`); return the cached instance.
      Test: **V2** — board capture visually identical to pre-change; author playtest: stamp/lift is
      smooth (no hitch).

- [x] T219 [R207 / P116 / V1] — **Flash on an overlay above the board.** `_animate_seal` stamp path
      calls `_spawn_seal_flash(seal)`: a dedicated `CanvasLayer` (layer 95) with the additive flash
      `TextureRect` centred at `seal.get_global_transform_with_canvas() * (seal.size*0.5)`, sized by
      the canvas scale; same bloom tween; frees its own layer; independent of the seal's lifecycle.
      Seal drop/squash/settle unchanged. `--flash-preview` debug hook.
      Test: **V1** — `--flash-preview` capture shows the flash blooming past the sheet edge,
      unclipped, above the board; author playtest confirms full radius.

- [x] T220 [R209 / P119 / V3] — **The stamp cooldown.** `SEAL_COOLDOWN_MS := 900`;
      `_seal_cooldown_until`; set on press; `_seal_block` disables the stamp while cooling and
      schedules a re-enable timer; affordance-only (raced server rejection still surfaces).
      Test: **V3** — author playtest: rapid clicks fire at most one action per window; re-enables
      after ~the press length.

- [x] T221 [R207–R210 / V4] — **Verification pass.** V1–V4; asset-map `--check`; suites
      untouched-green; diff scope; refresh the board preview artifact; append DECISION_LOG TD-064;
      swap the active spec in CLAUDE.md.
