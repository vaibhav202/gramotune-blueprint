# MILESTONES.md — the build plan

Live document. The first unchecked item is the next task (AGENTS.md §2). Update this file at the end of every session, and keep the **Now** block true.

## Now

- Phase: **M0 — foundation**
- Next item: **M0.5** (synthetic fixtures)
- Blocked on owner: nothing for M0.5. The POCO M3 is reachable over `adb` when needed; the CI repository is `https://github.com/vaibhav202/gramotune-blueprint` (Actions green).
- Human checks pending: none (format: `item → docs/human-checks/<file>.md`)

## Legend and rules

- `[ ]` not done · `[x]` agent work done and every machine-checkable criterion passes.
- Status marks: ⬜ not started · 🔄 in progress · 🟡 done by the agent, **human check pending** · ✅ verified · ⛔ blocked · ⏸ parked.
  A `[x]` item marked 🟡 is not the "first unchecked item"; it waits for the owner and is listed under **Human checks pending** above.
- Sizes: **S** ≈ 1 session · **M** ≈ 1–2 sessions · **L** ≈ 2–4 sessions. A session is one focused agent run (AGENTS.md §10). A spike's **box** is the maximum number of sessions; when it runs out, write down what you know and stop.
- Order is strict: **M0 → S1…S7 → G0 → M1 → M2 → M3 → M4 → G1 (v1.0)**. The D-series and Y-series start only after G1 and only when the owner says so. Inside the spikes, S1 → S2 → S3 → S4 run in that order; S5, S6 and S7 are independent.
- Optional parallel lanes, only if the owner runs several agents: A = engine (M1), B = library (M2), C = `skin` and `ui_kit` with fake data (M3.1–M3.2). Each lane touches only its own packages; the boundary check keeps them apart.
- Agents may mark status, add sub-steps and append notes. Adding, deleting or reordering items needs the owner's approval. Never delete an item; park it (⏸) with a reason.
- Spike code lives in `spikes/` and is thrown away or promoted deliberately at G0. Spike results go to `docs/spikes/S<n>-<name>.md` (question, method, numbers, decision) and into the CHANGELOG.
- Where a step needs the phone and the agent has no `adb` access, write the exact commands into a human-check file, ask the owner to run them and paste the output, and mark the item 🟡.

---

## M0 — Foundation (≈ 4–6 sessions)

- [x] ✅ **M0.1 — Toolchain and pins** · S · ARCHITECTURE §12
  - Do: verify Flutter stable (3.47.x expected), Dart, JDK, Android SDK and NDK, `adb`, and the `libclang` that `ffigen` needs. Look up the current version of every package in the dependency table. Choose the lint set.
  - Done when: `flutter doctor -v` is clean for Android; the table in ARCHITECTURE §12 lists exact versions and the date checked; `docs/dev-environment.md` lists setup commands and which devices `adb` can see; lint choice recorded.
- [x] ✅ **M0.2 — Workspace, packages, tool scripts** · M · ARCHITECTURE §3, AGENTS §4–5
  - Do: workspace root, the seven packages and `app` (each with a `README.md` stating its public API), flavors `play` and `full`, `tool/setup.sh`, `tool/check.sh`, `tool/gen_bindings.sh` (may be a stub), `tool/check_boundaries.dart`, `tool/check_tokens.dart`, and `tool/check_docs.py` (shipped with the blueprint; wire it into `tool/check.sh`).
  - Done when: `tool/check.sh` is green; a test proves the boundary check fails on a forbidden import; the app launches on a device in both flavors showing a placeholder screen.
  - Note (2026-11-08, owner-approved): this said "on an emulator". The Android emulator (37.2.12 and 37.2.13) crashes on this host inside `libgfxstream_backend.so` under every GPU backend (`host`, `swangle_indirect`, `off`), so the proof runs on the POCO M3 with `app/integration_test/placeholder_test.dart`. Details in `docs/dev-environment.md`, section 4; the emulator bug is a risk for M0.4 CI.
- [x] ✅ **M0.3 — Android baseline and manifest guard** · S · 05 §1, §3, §8 · P-18
  - Do: `minSdk` 26, `targetSdk` per the current Play requirement (look it up), the exact permission list from 05 §3, edge-to-edge and predictive-back flags. `tool/check_manifest.sh` inspects the **merged release manifest** (debug and profile builds add `INTERNET` for tooling, so they must not be used for this check).
  - Done when: the guard passes for `play` with no `INTERNET` and fails when a permission is added (test).
  - Status: `minSdk` 26 and `targetSdk` 36 (Play requirement re-checked 2026-11-08) are explicit in `build.gradle.kts`; the exact 05 §3 permission list with `maxSdkVersion=32` and the predictive-back flag are in the main manifest; `tool/check_manifest.sh` checks the merged release manifest via aapt2 and `--self-test` proves failure when a permission is added.
  - Note (2026-11-08): edge-to-edge needs **no** manifest flag on Flutter 3.47 — the engine sizes the window without decor fitting and forces it (`WindowCompat.setDecorFitsSystemWindows(window, false)`) when Dart requests EDGE_TO_EDGE; on API 35+ it is OS-enforced for `targetSdk 35+`. The manifest flag from the Do list is the predictive-back `android:enableOnBackInvokedCallback="true"`.
  - Note: the manifest merger injects `app.gramotune.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (androidx.core dynamic receivers); `tool/check_manifest.sh` allow-lists exactly that name suffix.
- [x] ✅ **M0.4 — CI** · S · 08 §1
  - Do: GitHub Actions running `tool/check.sh` on push and pull request; a nightly emulator job running a stub integration test; debug APK as an artifact.
  - Done when: a green run is linked in the CHANGELOG. Needs the repository (owner input).
  - Status: `.github/workflows/ci.yml` has a `check` job (tool/check.sh + play debug APK artifact; Flutter 3.47.9, temurin 17, gawk) on every push/PR and an `emulator-nightly` job (API 34, swiftshader, stub integration test) on a daily 03:00 UTC cron and on demand. Green run: https://github.com/vaibhav202/gramotune-blueprint/actions/runs/43105066311 (check 12 min, emulator job 12.5 min).
  - Note (2026-11-11): GitHub had a major Actions outage when the first push landed (runs queued with zero jobs for ~30 min); the runs started by themselves once the incident was over.
  - Note: GitHub-hosted Ubuntu runners do **not** expose `/dev/kvm`, so the emulator runs without hardware acceleration (boot ≈ 7 min) — accepted for a nightly job. The runner GPU stack avoids the owner-host `libgfxstream_backend.so` crash entirely (`docs/dev-environment.md`, section 4).
  - Note: `reactivecircus/android-emulator-runner@v2` executes each `script:` line in its own shell (`parseScript` → `sh -c` per line): `cd app` does not persist and a trailing line-continuation backslash becomes a literal argument that makes `flutter test` glob the whole repository (mixed integration and unit tests). Use the action's `working-directory` input and one-line commands.
- [ ] ⬜ **M0.5 — Synthetic fixtures** · M · 08 §2
  - Do: `tool/gen_fixtures.sh` and `test_assets/manifest.json` per 08 §2, including the continuous-sine gapless pairs and the weird-files set. **[verify]** which tool writes `iTunSMPB`; if none does, the generator writes the atom itself.
  - Done when: fixtures are committed (under ~5 MB); a test checks that every manifest entry matches its file; the README explains regeneration.

## Spikes (time-boxed; each ends with GO, PIVOT or PARK)

- [ ] ⬜ **S1 — Dart pump under jank** · box 3 · 03 §3, §6, §13 · risk R1
  - Method: `ffigen` bindings for `AAudio.h` only. In an engine isolate, pump a generated stereo sine (44.1 kHz i16, then 48 kHz float) with blocking `AAudioStream_write` and a timeout. A harness UI induces jank (heavy builds, fast scrolling, allocation pressure). Run ≥10 min on an emulator and ≥30 min on the POCO M3. Compare performance modes "none" and power-saving. Record xrun count, buffer fill, CPU, and the behavior of `getTimestamp` across pause, flush and seek.
  - Exit: report with numbers and a buffer-size recommendation. **GO** if 0 xruns for 10 min under jank. **PIVOT** otherwise: C pump built via Dart build hooks behind the same `OutputBackend` (needs ADR and owner approval, D-004).
- [ ] ⬜ **S2 — NDK decoder matrix** · box 3 · 03 §4 · risk R2
  - Method: `ffigen` for `NdkMediaExtractor.h`, `NdkMediaCodec.h`, `NdkMediaFormat.h`. Decode every fixture to PCM; request float PCM; record the format the codec really produces; compare hashes (lossless) or RMS error (lossy) per 08 §3; check seek accuracy and CPU; test `AMediaExtractor_setDataSourceFd` with a `content://` fd. Emulator and POCO M3.
  - Exit: matrix in `docs/spikes/S2-decoders.md`; the supported-format list for P-01; **GO** or a proposed D-004 fallback (bundled FLAC decoder via hooks, owner approval).
- [ ] ⬜ **S3 — Gapless boundaries** · box 2 · 03 §5 · risk R3 · P-02
  - Method: with the S2 decoders, find the delay and padding source per format (MediaFormat keys, LAME or Xing, `iTunSMPB`, Opus pre-skip). Prototype the trim planner. Measure boundary error on the continuous-sine pairs. Find out whether `MediaCodec` trims by itself on the target devices.
  - Exit: boundary error in frames per format; the formats promised sample-accurate gapless in v1.0; 03 §5 updated.
- [ ] ⬜ **S4 — `audio_service` lifecycle** · box 2 · 05 §5, §9 · risk R4
  - Method: minimal app with `audio_service` and `audio_session`; a thin handler forwards to the S1 engine isolate. Run the five scenarios in 05 §5 and the lifecycle matrix in 05 §9 on an emulator and on the POCO M3 (media keys with `adb shell input keyevent`; wired and Bluetooth headsets by hand).
  - Exit: pass or fail per scenario. **GO** or an ADR for a plugin fork or a minimal Kotlin shim (D-008).
- [ ] ⬜ **S5 — Storage and intents** · box 2 · 05 §3–4, §7 · risk R5
  - Method: query MediaStore audio through `jnigen` (10k+ rows, timed); read files by `_data` path on Android 16 with only `READ_MEDIA_AUDIO`; try folder art through `loadThumbnail` without `READ_MEDIA_IMAGES`; test the SAF tree fallback and fd handoff to the extractor; compare `app_links`, `receive_sharing_intent` and JNI for delivering "Open with" intents (initial and `onNewIntent`).
  - Exit: answers to every **[verify S5]** item in 05; D-009 and D-012 confirmed or amended.
- [ ] ⬜ **S6 — Skin rendering budget** · box 2 · 09 §8 · risk R6
  - Method: throwaway Classic-style screens (nav bar, tab bar, a 20k-row list, Now Playing with flip) using baked textures and placeholder art; then add a gloss shader and a reflection shader. Measure janky frames, raster time and memory with `flutter drive --profile` on the POCO M3, with Impeller and with the fallback renderer **[verify]**.
  - Exit: budgets in 09 §8 confirmed or changed; the list of effects that may be live shaders.
- [ ] ⬜ **S7 — Device probe (= D0)** · box 2 · 06 §5 · risk R9
  - Method: in-app probe screen plus `tool/probe_root.sh`, run on the POCO M3 with the 3.5 mm jack, and with a USB DAC if one is available.
  - Exit: `docs/device-notes/citrus.md` with raw outputs and a one-paragraph feasibility reading; 06 §11 table filled in. Needs the owner to run the root script.

## G0 — Feasibility gate (owner sign-off)

- [ ] ⬜ **G0** · S
  - Spike reports S1–S7 exist, each ending in GO, PIVOT or PARK.
  - ADRs D-004, D-005, D-006, D-008, D-009 are `accepted` or replaced; specs updated wherever a spike contradicted them, and every resolved **[verify]** tag removed or re-dated.
  - Risk register reviewed; new risks added.
  - D-001 (name, application id) and D-016 (license) decided. If the owner defers them, the placeholders stay and **M4.6 is blocked** until they are decided.
  - `spikes/` code promoted or deleted.
  - Record "G0 passed" in the CHANGELOG and update **Now**.

## M1 — Playback core: "it plays, perfectly" (≈ 12–16 sessions)

Exit: a debug harness app plays a pushed folder of fixtures gaplessly in the background for 30 minutes with a notification and headset buttons, 0 xruns, and a recorded listening check.

- [ ] ⬜ **M1.1 — `engine_api` and fakes** · S · 03 §2, §12
  - Done when: `PlayItem`, sealed commands and events, `PlaybackState`, `EngineClient`, `OutputBackend`, `Decoder`; `MemoryOutputBackend`, `FakeDecoder` and a manual clock exist, in pure Dart, with tests and a package README.
- [ ] ⬜ **M1.2 — AAudio backend** · M · 03 §6, §9 · P-01
  - Do: production `AAudioBackend`: open, start, pause, flush, close; blocking write with timeout; xrun counter; presentation clock from `getTimestamp`; disconnect handling; reopen on format change; every native handle has an owner class.
  - Done when: error-mapping and clock tests pass with fakes; a device smoke test plays a sine for 60 s with 0 xruns (counter evidence); handle counters return to zero.
- [ ] ⬜ **M1.3 — NDK decoder** · M · 03 §4 · P-01 · Q-8
  - Do: `NdkDecoder`: extractor and codec, format report, seek, float or i16 output, path and fd sources, error mapping. Add the bundled decoder from S2 only if D-004 was approved.
  - Done when: PCM goldens pass (hash for lossless, RMS for lossy) in an on-device integration test; 1000 open and close cycles leak no handles.
- [ ] ⬜ **M1.4 — Timeline, state machine, window protocol** · M · 03 §2–3, D-022
  - Done when: pump loop, states and every command (`LoadWindow`, `Play`, `Pause`, `Seek`, `SkipTo`, `SetRepeatOne`, `StopAfterCurrent`, `Release`) work; `NeedMoreItems` fires at ≤50 remaining; event rates are asserted; the scenario tests of 08 §5 pass on the host.
- [ ] ⬜ **M1.5 — Gapless** · M · 03 §5 · P-02 · Q-8
  - Done when: trim planner, prepare-next, tail hold-back and reopen-on-format-change are in; the gapless suite (08 §4) passes on the host and on a device for FLAC, MP3, AAC and Opus. 🟡 Human check: listen for clicks on real albums.
- [ ] ⬜ **M1.6 — DSP chain** · M · 03 §7 · P-10
  - Done when: ReplayGain, 10-band EQ with preamp, clipping protection, TPDF dither on narrowing, and 10 ms transition fades work; numeric tests per 08 §3 pass; with DSP off the output hash equals the source hash; a 60 s run shows no GC activity on the engine isolate **[verify method: VM service]**.
- [ ] ⬜ **M1.7 — Engine host and recovery** · M · 03 §10–12
  - Done when: `EngineClient` over the isolate (spawn, ports, rate limits); crash recovery restarts the engine and restores the position; diagnostics counters; a debug harness page; baseline numbers for 03 §10 recorded; `tool/soak.sh` v1 completes 30 min with 0 xruns.
- [ ] ⬜ **M1.8 — Service and session integration** · M · 05 §5–6 · P-03
  - Done when: minimal `PlaybackController` (in-memory queue), thin `AudioHandler`, notification, media and headset buttons, focus policy (pause, duck −12 dB, becoming noisy), restore-paused after process death; the lifecycle matrix passes on an emulator. 🟡 Human check on the POCO M3: headset buttons, a phone call, Bluetooth.
- [ ] ⬜ **M1.9 — Hardening** · S · 03 §9
  - Done when: skip storms, truncated and corrupt files, and disconnect scenarios are covered on host and device; every row of the 03 §9 error table has a test; `spikes/` is gone.

## M2 — Library: "it knows my music" (≈ 12–16 sessions)

Exit: the owner's real collection scans, groups and searches correctly, within the Q-4 numbers, and the owner has reviewed it on a debug browser page.

- [ ] ⬜ **M2.1 — Schema, DB isolate, migrations** · M · 04 §2, §10
  - Do: drift tables per 04 §2 (names normative), a migration framework with committed schema dumps, a shared DB isolate (`drift_flutter` `shareAcrossIsolates`), a synthetic 50k-track generator (rows only), and the FTS5 availability check (04 §5 has the LIKE fallback).
  - Done when: the migration test passes; `EXPLAIN QUERY PLAN` shows an index for every lens query on the 50k library; the FTS5 result is recorded; benchmark numbers are in the CHANGELOG.
- [ ] ⬜ **M2.2 — MediaStore reader** · M · 04 §3, 05 §4 · P-04
  - Do: paged audio query through `jnigen` (id, URI, `_data`, size, modified, duration, mime, volume); volume list with mounted state; change detection by MediaStore generation or modified time **[verify, S5]**; `content://` fd opener.
  - Done when: 20k rows are read within the Q-4 budget on a device (numbers recorded); a fake reader interface is used in unit tests; unmounted volumes are reported, never purged.
- [ ] ⬜ **M2.3 — Metadata reader** · M · 04 §3 · risk R14
  - Do: `MetadataReader` interface; evaluate `audio_metadata_reader` and `metadata_audio` on the owner's real sample and the weird-files set (accuracy, speed, memory, odd tags, embedded art, ReplayGain, LAME or Xing and `iTunSMPB` values). Pick one; keep the other as a fallback behind the interface.
  - Done when: comparison in `docs/spikes/M2.3-metadata.md`; D-011 accepted; the weird-files corpus never crashes the reader; ReplayGain and gapless values reach `PlayItem`.
- [ ] ⬜ **M2.4 — Scanner** · L · 04 §3 · P-04 · Q-4
  - Do: scanner isolate with the stages of 04 §3; incremental rules (unchanged files are not re-read, deletions are marked `missing`, purge after 30 days unless the volume is unmounted); cancel and resume; progress stream; SAF folders if S5 proved them. `tool/gen_library.dart` writes N tiny tagged files outside the repo for benchmarks.
  - Done when: 20k generated files scan in ≤3 min and an unchanged rescan takes ≤5 s on the reference device (recorded); scenario tests cover moves, renames, tag edits and unmount.
- [ ] ⬜ **M2.5 — Normalization and grouping** · M · 04 §2–3 · risk R14
  - Done when: sort keys (leading articles, case, diacritics, non-Latin into an honest "#" bucket), album identity (album artist, compilations, disc numbers), multi-value artists and genres, and year handling pass table-driven tests on the weird-tags corpus; "group by album artist" is configurable.
- [ ] ⬜ **M2.6 — Lens queries and search** · M · 04 §4–5 · P-05 · P-08
  - Done when: `LensQuery` paging works for Artists, Albums, Songs, Genres, Years, Folders and Recently Added; alphabet-index counts are available; search covers artist, album, title and genre; on 50k rows the first page takes <200 ms and search <50 ms.
- [ ] ⬜ **M2.7 — Artwork pipeline** · M · 04 §3, 05 §3
  - Done when: embedded art and folder art (per the S5 result) are extracted once and cached as files at fixed sizes with an LRU cap; decoding happens at display size and never on the UI isolate; a placeholder exists; memory stays flat while scrolling 20k rows.
- [ ] ⬜ **M2.8 — Playlists, queue, statistics** · M · 04 §6–8, §10 · P-06 · P-07 · P-13
  - Done when: playlist CRUD and reorder; M3U and M3U8 import and export (UTF-8, `#EXTINF`, relative and absolute paths); built-ins Recently Played, Most Played, Loved; persisted play context and Up Next; history; the play-count rule (50% or 240 s); `PlaybackController` persists through the database instead of the M1.8 placeholder.
- [ ] ⬜ **M2.9 — Library review on the real collection** · S · risk R14
  - Do: a minimal debug page lists every lens and search. The owner browses their own library and notes what is wrong.
  - Done when: findings are fixed or logged as new items; 🟡 until the owner records the result.

## M3 — App and skins: "it looks and feels right" (≈ 20–28 sessions)

Exit: every screen U-01…U-20 exists in both skins and works with the real engine and library.

- [ ] ⬜ **M3.1 — `skin` and `ui_kit` foundations** · L · 09 §3–5, 02 §8 · P-14
  - Do: skin model and token loader; Plain skin first; core widgets (NavBar, TabBar, ListRow with three presets, SectionHeader, SegmentedControl, ActionSheet, Toast, EmptyState, Switch, PillButton); Classic tokens with placeholder textures until the owner's Figma exports arrive; `check_tokens.dart` active.
  - Done when: every widget has goldens in both skins at 1× and 2× font scale; the accessibility guideline tests pass for Plain (tap target, label, contrast).
- [ ] ⬜ **M3.2 — App shell and navigation** · M · 02 §2, §7 · U-17
  - Do: `go_router` routes, the tab bar (Playlists | Artists | Songs | Albums | More), the mini-player slot, Riverpod structure with fake providers, ARB localization, empty, loading and error states, selection and scroll restoration, lens ordering model for More › Edit.
  - Done when: smoke tests open every route with fakes; the tab choice persists; layouts hold at 360, 412 and 600 dp and at 200% font scale.
- [ ] ⬜ **M3.3 — Library screens** · L · 02 §4, §6 · U-03, U-04, U-05, U-17 · P-05, P-20, P-21, P-23
  - Done when: lens lists with alphabet index, Albums list or grid, artist detail, album detail with disc headers, row presets (Classic, Detailed, Compact), format badges, remembered per-lens sort; ≤1% janky frames on a 20k-row list (profile timeline); index-scrubbing accuracy test. 🟡 Human check: one-hand ergonomics.
- [ ] ⬜ **M3.4 — Playlists and actions** · M · 02 §4 · U-06, U-07, U-19, U-20
  - Done when: playlists with smart lists pinned; detail and edit mode (reorder, delete, multi-select); Add-to-playlist sheet with inline create; the shared track action sheet (Play next, Add to queue, Add to playlist, Go to artist, Go to album, Track Info, Love); Save queue as playlist.
- [ ] ⬜ **M3.5 — Now Playing** · L · 02 §5 · U-08, U-09, U-12, U-16 · P-09, P-11, P-12
  - Done when: framed artwork, accurate scrubber (position from the engine clock), transport, shuffle, repeat all and one, stop after current, volume slider mirroring system volume, flip to the track list with star rating, Track Info sheet, sleep timer (minutes, end of track) driven by the engine; effects stay within the S6 budget. 🟡 Human check: visuals against Figma, smoothness of the flip.
- [ ] ⬜ **M3.6 — Up Next and Search** · M · 02 §4 · U-10, U-11 · P-07, P-08
  - Done when: queue screen (reorder, remove, clear, Save as playlist) persisted; search with scope control and actionable results, debounced, usable with TalkBack.
- [ ] ⬜ **M3.7 — Equalizer, ReplayGain, Signal Path** · M · U-13, U-14 · P-10, P-11
  - Done when: EQ screen (10 bands, preamp, presets, on or off) and ReplayGain settings (mode, preamp, clipping protection) drive the engine DSP; Signal Path shows decoder, DSP stages, output rate, depth and backend, xruns, "ducked", and evidence level E0 (06 §3); tests map UI state to engine commands.
- [ ] ⬜ **M3.8 — Onboarding and Settings** · M · 02 §3 · U-01, U-02, U-15, U-18 · P-15, P-16
  - Done when: welcome and permission explainer, library setup with scan progress and extra folders, Settings (Library, Playback, Output with Standard only in v1.0, Appearance with skin switch, About and licenses), Diagnostics with log export. 🟡 Human check: fresh install to first playback ≤60 s (Q-6).
- [ ] ⬜ **M3.9 — System glue** · M · 05 §7–8 · P-13, P-19
  - Done when: "Open with" for `content` and `file` URIs (initial and `onNewIntent`); queue and position restored paused after restart; system volume mirror; notification opens Now Playing; predictive back and edge-to-edge; battery-optimization help page; integration tests drive intents with `adb shell am start`.
- [ ] ⬜ **M3.10 — Classic skin art pass** · L · 09 §10–12 · P-14 · owner input: Figma exports
  - Do: import the owner's textures, nine-slices and glyphs into `packages/skin/assets/classic/`; add the shaders S6 allowed; fill `ASSETS.md`; run the review loop screen by screen (reference PNG → screenshot → deviation list).
  - Done when: every screen on the 09 §12 checklist has an approved review recorded (🟡 until each approval); skin size and texture memory are inside the budget.

## M4 — Polish and release: "ready for an average user" (≈ 10–14 sessions)

- [ ] ⬜ **M4.1 — Accessibility pass** · M · 02 §10 · P-17 · Q-7
  - Done when: every screen has semantics labels and a sane focus order; tap targets ≥48 dp; no clipping at 200% font scale; Plain reaches AA contrast; Classic contrast gaps are listed. 🟡 Human check with TalkBack.
- [ ] ⬜ **M4.2 — Performance pass** · M · Q-3, Q-4
  - Done when: startup, 20k-row scrolling, scan and memory are profiled on the reference device and fixed; measured numbers replace the provisional targets in 01 §9 (owner confirms).
- [ ] ⬜ **M4.3 — Reliability and lifecycle** · M · 05 §9 · Q-2 · risk R15
  - Done when: the 30-minute screen-off soak passes (0 xruns, memory ±5%); the lifecycle matrix passes on the POCO M3, the owner's second Android 16 phone and **one device on a non-LineageOS vendor ROM**; battery-optimization help is checked on that ROM. 🟡 Human checks.
- [ ] ⬜ **M4.4 — Battery** · S · Q-5
  - Done when: one-hour screen-off runs against a reference player are recorded (target ≤1.5×); performance mode and tick rates are tuned if needed.
- [ ] ⬜ **M4.5 — Edge cases** · M
  - Done when: each is a test or a human check: corrupt, zero-byte and wrongly named files (skipped with a clear message); SD card removal; permission revoked mid-session; a 100k-track library; very long tags; duplicate files; RTL and non-Latin text sanity; usable landscape (P-22).
- [ ] ⬜ **M4.6 — Release engineering** · M · 05 §10 · P-18 · **blocked until D-001 and D-016 are decided**
  - Done when: `LICENSE`; signing config and `docs/release.md` (keystores never committed); versioning; an original adaptive app icon (09 §9); store text and package id free of Apple marks; a user README and a privacy statement (no network, no analytics); a licenses page generated from dependencies plus `ASSETS.md`; a dependency license audit; F-Droid metadata (fastlane); a GitHub release workflow for the `play` flavor.
- [ ] ⬜ **M4.7 — Upgrade window** · S · risk R13
  - Do: evaluate the then-current Flutter stable (3.50 is due Nov 2026) and package updates. Upgrade only if `tool/check.sh` and the integration suite pass; otherwise record why and stay. This is the only place where SDK upgrades happen before G1.
- [ ] ⬜ **M4.8 — Dogfood** · M · Q-1
  - Done when: seven days on two devices with the local crash log; every blocker fixed; the rest triaged into v1.1.

## G1 — v1.0 gate (owner sign-off)

- [ ] ⬜ **G1** · S
  - Every MUST requirement P-01…P-19 has a passing test or a recorded human check; the traceability table is in the CHANGELOG entry.
  - Q-1…Q-8 have recorded evidence; SHOULD items P-20…P-23 are done or explicitly moved to v1.1.
  - No item is left at 🟡; the risk register is reviewed; D-001 and D-016 are decided.
  - Tag `v1.0.0`, publish release notes, update **Now**.

## M5 — v1.1 candidates (scoped one by one by the owner)

Not planned in detail. Candidates from 01 §6: autoplaylists with a rule editor, CUE sheets, lyrics, user-loadable skins, crossfade, ReplayGain scanner, custom row-format strings, tag editing, A–B repeat, optional fixed-rate resampler, ListenBrainz scrobbling, tablet two-pane layout, Cover Flow-style landscape browse, Android Auto. When the owner picks one, it gets an `M5.n` item in the format above.

---

## D-series — Direct output (after G1; the owner says go; research-grade, see 06)

Order D1 → D2 → D3 → D4 → D5. **D0** is the same work as S7 (the probe is built before v1.0 so its findings can shape the design). Touching `android-module/` always needs the owner's approval (AGENTS §11).

- [ ] ⬜ **D1 — AAudio exclusive and MMAP experiment** · box 3 · 06 §6 · risk R9
  - Done when: exclusive plus low-latency streams at 44.1 and 96 kHz are tried on the internal jack, USB and Bluetooth; granted mode and MMAP state are in `docs/device-notes/citrus.md`; a 10-minute run records xruns and battery. If MMAP exclusive is granted on the jack, an experimental `ExclusiveBackend` exists with E2 evidence (`dumpsys`); if not, the HAL limit is documented.
- [ ] ⬜ **D2 — USB bit-perfect (API 34+)** · box 3 · 06 §7
  - Done when: JNI wrappers for preferred mixer attributes; `UsbBitPerfectBackend`; the one-time volume warning and a fade-in; fallback on any failure. With a USB DAC, Signal Path shows E1 with a matching format. 🟡 Human check with a DAC and IEMs.
- [ ] ⬜ **D3 — Magisk module `gramotune-direct`** · box 4 · 06 §8 · risk R10 · owner approval to start
  - Done when: properties and install-time policy patch (never a static vendor file); device allowlist; safe-mode and rescue notes; uninstall restores stock behavior; on `citrus`, `dumpsys media.audio_flinger` shows a direct or MMAP path at the expected rate for 44.1 and 96 kHz (E2). 🟡 Human check including a reboot and the rescue procedure.
- [ ] ⬜ **D4 — Raw ALSA research (rooted)** · box 5 · 06 §9
  - Kill criteria: park it if five sessions on `citrus` give no stable E2-proven playback, or if normal audio cannot be restored safely after a crash. A helper binary needs an ADR.
- [ ] ⬜ **D5 — Output settings, safety, fallback** · M · 06 §10
  - Done when: Settings › Output offers Standard, Exclusive, USB bit-perfect and Root direct, each labeled experimental with its evidence level; auto-fallback on open failure or route change; "Reset audio"; experimental modes never auto-enable and switch off after 2 failures in 5 minutes.
- [ ] ⬜ **G2 — Direct output decision** · S: record which modes ship, their evidence levels and the device matrix (06 §11); update the product spec.

## Y-series — YouTube Music source (after G1; the owner says go; flavor `full`, see 07)

- [ ] ⬜ **Y0 — Evaluation spike** · box 3: pick one candidate (07 §7), show search, 60 s playback and a download on the POCO M3, document maintenance risk and every component's license.
- [ ] ⬜ **Y1 — Plugin skeleton and flavor** · M: `sources_youtube` (add it to the boundary matrix in AGENTS §5: it may import `sources`, `music_library` and `engine_api`, never UI packages), `full` flavor wiring, provider health check, "Online source unavailable" state, README with the legal notes (07 §9).
- [ ] ⬜ **Y2 — Search and browse** · L: songs, albums, artists, playlists; Online section in Search below Library results.
- [ ] ⬜ **Y3 — Stream resolve and playback** · L: loopback caching proxy, re-resolve on expiry, cleartext-to-localhost config **[verify]**, WebM Opus and MP4 AAC playback.
- [ ] ⬜ **Y4 — Downloads, tag writing, linking** · L: queue (concurrency 2, resumable), tags with the remote id, link to the existing remote row, `cached` state (D-023).
- [ ] ⬜ **Y5 — Unified library UX** · M: cloud and downloaded glyphs, "Downloaded only" filter, merged album and artist pages, Download album and playlist buttons.
- [ ] ⬜ **Y6 — Optional sign-in** · only if the owner asks.

## X-series — Desktop (roadmap only)

X1 Linux output backend (ALSA or PipeWire through FFI) · X2 Windows output backend (WASAPI exclusive) · X3 desktop layouts (two-pane). None is scheduled; the engine's interfaces already allow them.

---

## Owner inputs (needed by)

| Input | Needed by | Why |
|---|---|---|
| GitHub repository (name, visibility) | M0.4 | CI and releases |
| Whether the agent can reach the phone with `adb`, or use the paste-back workflow | M0.1 | Every on-device spike depends on it |
| A short session with the POCO M3 (and root for the probe) | S1, S4, S7 | Real-hardware numbers |
| Name and application id (D-001), license (D-016) | G0 (latest M4.6) | Changing them later is costly |
| A representative sample of the real music library (2–5k tracks, odd tags included) or consent to run on-device | M2.3 | Metadata reader choice |
| Figma tokens (colors, type) for Plain and Classic | M3.1 | Skins |
| Figma frames and exports: textures, nine-slices, glyphs, icon | M3.10 | Classic art pass |
| A borrowed phone on a non-LineageOS vendor ROM | M4.3 | OEM battery behavior |
| A USB DAC and wired IEMs | S7, D2 | USB evidence |
| Approval to start root work | D3 | Risk of device damage |

## Item template (when the owner approves a new item)

```
- [ ] ⬜ **<ID> — <title>** · <S|M|L> · <spec links> · <P-/Q-/R- ids>
  - Do: <what>
  - Done when: <observable, machine-checkable where possible; mark 🟡 when a human must check>
```
