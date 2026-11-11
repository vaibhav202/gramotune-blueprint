# CHANGELOG — live development log

Newest entry first. Add your entry directly below the `---` line that follows the template, at the end of every agent session (AGENTS.md §10). This is the project's memory between sessions: the next agent reads the three newest entries before starting.

User-facing release notes are written separately at release time (M4.6, `docs/release.md`); this file is the engineering log.

## Entry template

```
### YYYY-MM-DD — <item ids> — <one-line outcome>
- Agent: <tool and model> · Session: <link or id> · Commit or branch: <ref>
- Status: ✅ done | 🟡 done, human check pending (<docs/human-checks/file.md>) | ⛔ blocked | ⏸ parked
- Changed: <3–6 bullets: packages and files, what they now do>
- Evidence: <commands and results: test counts, hashes, xrun counters, benchmark numbers, timeline summaries>
- Decisions: <ADRs added or changed, or "none">
- Spec changes: <docs touched, or "none">
- Open questions for the owner: <or "none">
- Next item: <id>
```

Rules: evidence is pasted, not described. Never write "sounds good" or "looks smooth"; write what was measured, and link the human check for the rest.

---



### 2026-11-12 — M0.4 — CI live: check on every push, emulator job nightly, APK artifact
- Agent: Big Pickle (opencode) · Session: this conversation · Commit or branch: master, pushed to origin
- Status: ✅ done
- Changed:
  - `.github/workflows/ci.yml` (new): `check` job runs `tool/check.sh` on every push and pull request (Flutter pinned 3.47.9, temurin 17, gawk installed for the manifest guard's `strtonum`), then builds the play debug APK and uploads it as the `gramotune-play-debug-apk` artifact. `emulator-nightly` job runs the stub integration test on a GitHub-hosted emulator (API 34, `swiftshader_indirect`) on a 03:00 UTC cron and on demand.
  - `README.md`: rewritten to speak about the product on its own terms (owner request: no references to other players or design eras; the look is described as inspired by classic audio hardware). D-001 line updated to decided.
  - Temporary `probe.yml` workflow added and removed again while diagnosing; it is not in the final tree.
- Evidence:
  - **Green run linked (the M0.4 done-criterion):** https://github.com/vaibhav202/gramotune-blueprint/actions/runs/43105066311 — both jobs green: `check` (tool/check.sh, ~12 min) and `emulator-nightly` (12m29s). The artifact `gramotune-play-debug-apk` (76.9 MB) uploads on every run; first green run (check only): https://github.com/vaibhav202/gramotune-blueprint/actions/runs/43099142442.
  - The stub integration test ran **on the emulator**: log line `✅ placeholder renders with the active flavor`.
  - The runner GPU stack avoids the owner-host `libgfxstream_backend.so` emulator crash entirely — the guest rendered frames all through the 12-minute run without a crash. GitHub-hosted Ubuntu runners expose no `/dev/kvm`, so the emulator boots without hardware acceleration (~7 min boot); accepted for a nightly.
  - GitHub Actions had a major outage 20:48–20:58 UTC on 2026-11-11 while the first push landed (runs queued with zero jobs); the queued runs completed by themselves once the incident ended. No project change was needed.
- Decisions: none.
- Spec changes: MILESTONES M0.4 + **Now** (next: M0.5); README status. No ADR.
- Open questions for the owner: none.
- Next item: M0.5 (synthetic fixtures)

### 2026-11-08 — D-001 — the project is named Gramotune; application id `app.gramotune`
- Agent: Big Pickle (opencode) · Session: this conversation · Commit or branch: repository initialized today; no commits yet
- Status: ✅ done
- Changed:
  - D-001 accepted (owner decision 2026-11-08): the product name is **Gramotune** and the Android application id / namespace is `app.gramotune`.
  - Dart workspace: root package `gramotune_workspace`, app package `gramotune`; imports moved to `package:gramotune/main.dart`; root class `GramotuneApp`; the placeholder and its tests now say `Gramotune`; every package description updated.
  - Android: `MainActivity` moved to `app/android/app/src/main/kotlin/app/gramotune/MainActivity.kt` with `package app.gramotune`; launcher label `Gramotune`; `docs/05-android-platform-spec.md` §1 records the decided id.
  - Directory renamed to `~/Gramotune/gramotune-blueprint`; the outside-repo environment file is now `~/.bashrc.d/gramotune-toolchain.sh` (`~/.bashrc` sources `~/.bashrc.d/*` by glob, so nothing else changed).
  - Future artifacts renamed with the codename: the D3 Magisk module is `gramotune-direct`; local IDE artifacts (.idea, .iml) and the AVD updated (old `tonearm_*` AVDs deleted, `gramotune_a36` created).
  - History note: older CHANGELOG entries keep the old name on purpose — they describe what happened that day.
- Evidence:
  - Conflict check required by D-001, run 2026-11-08 before the commitment: GitHub search API for `gramotune` → `total_count: 0`; `pub.dev/packages/gramotune` → HTTP 404; web, F-Droid and trademark searches → no entries; no Apple, iOS or iPod marks are used.
  - `flutter build apk --release --flavor play` succeeds with the new id; `aapt2 dump badging`: `package: name='app.gramotune'`, `application-label:'Gramotune'`.
  - `tool/check_manifest.sh play` → `PASS [merged release manifest (play)]` (the guard's allow-list handles `app.gramotune.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`).
  - `tool/check.sh` all green: analyze "No issues found!", docs check 30 files/189 references, host tests 14 + 1 + 2 passed.
  - On-device launch of the renamed id was not captured — the POCO M3 disconnected right before `adb install`. Owner check (30 s): `adb install -r app/build/app/outputs/flutter-apk/app-play-release.apk && adb shell am start -n app.gramotune/.MainActivity`, then `adb shell pidof app.gramotune` should print a pid and the launcher shows "Gramotune".
- Decisions: D-001 → accepted (application id `app.gramotune`).
- Spec changes: `DECISIONS.md` D-001; `docs/05-android-platform-spec.md` §1; `AGENTS.md` header; `README.md` title; `ARCHITECTURE.md` §3 tree root; `MILESTONES.md` D3 module name; `docs/dev-environment.md` toolchain filename and AVD name.
- Open questions for the owner: none.
- Next item: M0.4

### 2026-11-08 — M0.3 — Android baseline set; merged-manifest guard added
- Agent: Big Pickle (opencode) · Session: this conversation · Commit or branch: none (not a git repository)
- Status: ✅ done
- Changed:
  - `app/android/app/build.gradle.kts`: `minSdk = 26` and `targetSdk = 36` explicit (were `flutter.minSdkVersion`/`flutter.targetSdkVersion`); comment carries the Play-requirement date and the D-015 compileSdk note.
  - `app/android/app/src/main/AndroidManifest.xml`: the exact permission list of 05 §3 with comments (`READ_MEDIA_AUDIO`; `READ_EXTERNAL_STORAGE` capped at `maxSdkVersion=32`; `POST_NOTIFICATIONS`; `FOREGROUND_SERVICE`; `FOREGROUND_SERVICE_MEDIA_PLAYBACK`; `WAKE_LOCK`; optional `READ_MEDIA_IMAGES` pending the S5 folder-art answer) and `android:enableOnBackInvokedCallback="true"` (predictive back, 05 §8).
  - `tool/check_manifest.sh` (new): builds `app-<flavor>-release.apk`, extracts `<uses-permission>` nodes (name + `maxSdkVersion`) from the merged manifest with `aapt2 dump xmltree`, and applies the 05 §3 rules; `--self-test` runs the rule on fixtures without a build and proves failure when a permission is added. Wired into `tool/check.sh` as the cheap fixture run.
  - `docs/dev-environment.md`, section 2: targetSdk requirement re-checked date. README status line.
- Evidence:
  - Play requirement (looked up 2026-11-08, Google Play Console "Target API level requirements"): new apps and app updates must target **Android 16 (API 36)** effective 2026-08-31 → `targetSdk 36` confirmed, no bump before M4.6.
  - Merged release manifest (`aapt2 dump xmltree`, `app-play-release.apk`, 17.3 MB): `minSdkVersion=26`, `targetSdkVersion=36`, `enableOnBackInvokedCallback=true`; `uses-permission` set = READ_MEDIA_AUDIO, READ_EXTERNAL_STORAGE 32, READ_MEDIA_IMAGES, POST_NOTIFICATIONS, FOREGROUND_SERVICE, FOREGROUND_SERVICE_MEDIA_PLAYBACK, WAKE_LOCK, `org.example.tonearm.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (injected by the androidx.core manifest merger); **no `INTERNET`**.
  - `tool/check_manifest.sh play` → `PASS [merged release manifest (play)]`, exit 0; `tool/check_manifest.sh full` → same list, PASS, exit 0.
  - Failure cases (self-test, exit 0 overall): exact-list fixture PASS; list + `INTERNET` **fails**; `READ_EXTERNAL_STORAGE` without `maxSdkVersion=32` **fails**.
  - Release smoke on POCO M3 `b9b56e3c1220`: `adb install -r app-play-release.apk` → Success; `am start` → `mCurrentFocus=...MainActivity`, `pidof org.example.tonearm` = 6970 (process alive).
  - `tool/check.sh`: all green, including the new "merged release manifest guard (fixtures)" step; analyze "No issues found!", host tests 14 + 1 + 2 passed.
  - Edge-to-edge finding: no manifest flag exists in the Flutter 3.47 embedding — `PlatformPlugin` calls `WindowCompat.setDecorFitsSystemWindows(window, false)` when Dart requests EDGE_TO_EDGE, and `FlutterActivity` forces a transparent status bar on API 35+. So the Do-list "flags" resolve to the predictive-back attribute alone.
- Decisions: none (compileSdk 37/targetSdk 36 already in D-015 and ARCHITECTURE §12).
- Spec changes: `docs/dev-environment.md`, section 2; MILESTONES M0.3 + **Now**; README status. No ADR.
- Open questions for the owner: **M0.4 needs the GitHub repository** (owner input; also recorded in the MILESTONES Now block). Release builds still sign with debug keys until M4.6.
- Next item: M0.4

### 2026-11-08 — M0.2 — workspace, packages, tool scripts; the app launches in both flavors
- Agent: Big Pickle (opencode) · Session: this conversation · Commit or branch: none (not a git repository)
- Status: ✅ done
- Changed:
  - Pub workspace `tonearm_workspace` (root `pubspec.yaml`, `analysis_options.yaml` with `flutter_lints` 6.0.0 and strict analyzer modes) with eight members: `engine_api`, `engine`, `music_library`, `sources`, `platform_android`, `skin`, `ui_kit` and `app`, each with a `README.md` stating its public API and its allowed imports.
  - `tool/check.sh` runs pub get, `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos --fatal-warnings`, the boundary check, the token check, `tool/check_docs.py` and the host tests; `tool/setup.sh` installs and pins the toolchain; `tool/gen_bindings.sh` is a stub until the first real bindings.
  - `tool/check_boundaries.dart` enforces the AGENTS §5 matrix and `tool/check_tokens.dart` rejects literal colors, `print()` and `isLeaf` in the engine; both have tests that feed a violating file through the rule and require failure.
  - Flavors `play` and `full` (`flavorDimensions += "distribution"`, same `applicationId`), `compileSdk` 37 with `targetSdk` 36, flavor read at runtime through `appFlavor`.
  - Added `app/integration_test/placeholder_test.dart` plus the `integration_test` dev dependency as the launch proof; `tool/check.sh` formats it too.
- Evidence:
  - `tool/check.sh`: format 17 files (0 changed); analyze "No issues found!"; boundaries and tokens pass; docs check "30 files, 179 section references"; host tests 14 passed; `app` widget test 1 passed; `ui_kit` 2 passed; final line `check.sh: all green`.
  - Boundary and token checks fail on a forbidden import, a literal `Color`, `print()` and `isLeaf: true` (root tests `test/check_boundaries_test.dart`, `test/check_tokens_test.dart`).
  - Debug APKs: `app-play-debug.apk` (158,682,206 bytes) and `app-full-debug.apk` (158,681,946 bytes).
  - POCO M3 `b9b56e3c1220` (`citrus`, LineageOS, API 37): `flutter test integration_test -d b9b56e3c1220 --flavor play --dart-define=EXPECTED_FLAVOR=play` → build 26.7 s, install 6.8 s, `00:06 +1: All tests passed!`; the same command with `--flavor full` → `00:04 +1: All tests passed!`. The test asserts that `appFlavor` is set, equals `EXPECTED_FLAVOR`, and that `M0.2 placeholder · play flavor` / `· full flavor` is rendered.
  - Emulator, negative result kept so it is not repeated: `tonearm_a36` (API 36 Play Store image, `pixel_5`) boots in about 20 s and authorizes adb, but `qemu-system-x86_64-headless` dies within ~35 s of guest GL work — SIGILL in `libgfxstream_backend.so` `RenderThread` (`gles2_decoder_context_t::decode`), SIGSEGV in `ColorBufferGl::create` → `TextureResize` with `-gpu host`. Reproduced on emulator 37.2.12 and 37.2.13 with `-gpu host`, `swangle_indirect`, `swiftshader_indirect` and `off`; `coredumpctl info` shows the `RenderThread` stack. Host: Fedora 45, Mesa 26.2.6, hybrid Intel Iris Xe + NVIDIA MX450 (NVK), Wayland.
- Decisions: D-015 amended — `compileSdk` 37 because `permission_handler_android` 14.1.1 refuses to compile against 36, `targetSdk` stays 36. D-014 amendment (`music_library`) recorded 2026-11-05. With owner approval, M0.2's "launches on an emulator" criterion now reads "launches on a device".
- Spec changes: MILESTONES M0.2 (done, note) and M0.4 (emulator risk note) and the **Now** block; `docs/dev-environment.md` sections 2 (emulator 37.2.13) and 4 (rewritten: POCO M3, the integration-test recipe, the emulator bug, adb auth and lock-file notes); README status. ARCHITECTURE §3 and §12 were already updated for `music_library` and `compileSdk` 37.
- Open questions for the owner: none blocking. For M0.4, the nightly emulator job needs a runner without this hybrid-GPU/Wayland stack, or a pinned older emulator build.
- Next item: M0.3

### 2026-11-05 — M0.1 — toolchain installed, verified and pinned
- Agent: Big Pickle (opencode) · Session: this conversation · Commit or branch: none (not a git repository)
- Status: ✅ done
- Changed:
  - Installed Flutter 3.47.9 stable (Dart 3.13.7) under `~/development/flutter` and Android cmdline-tools 23.0 under `~/Android/Sdk`; verified the archive against its published SHA-256.
  - Added `~/.bashrc.d/tonearm-toolchain.sh` (outside the repository) exporting `ANDROID_HOME`, `ANDROID_SDK_ROOT`, `JAVA_HOME`, `FLUTTER_ROOT` and the tool `PATH`.
  - Created `docs/dev-environment.md`: host, exact pins, setup commands, adb device state, lint choice, and the verified ffigen/libclang recipe.
  - Updated ARCHITECTURE §12 to exact versions with the 2026-11-05 check date; updated the **Now** block and marked M0.1 complete; updated the README status line.
- Evidence:
  - `flutter --version`: `Flutter 3.47.9 • channel stable • revision c197ca5199 • 2026-10-29`; `Tools • Dart 3.13.7 • DevTools 2.60.0`.
  - `flutter doctor -v`: Flutter `[✓]`; Android toolchain `[✓]` (SDK 36.0.0, platform android-37.0, build-tools 36.0.0, emulator 37.2.12.0, Java 25.0.3, "All Android licenses accepted"). Linux desktop `[✗]` only for missing clang/CMake/ninja/GTK (not an Android target). Cosmetic notice: two adb binaries (`~/Android/Sdk/platform-tools/adb` 37.0.1 and `/usr/bin/adb` 37.0.0p1); `PATH` selects the SDK copy.
  - `adb devices -l`: no devices attached. No AVD exists yet; the POCO M3 is not reachable from this host.
  - `sdkmanager --list_installed`: platform-tools 37.0.1, cmdline-tools 23.0, NDK 28.2.13676358, build-tools 34/35/36.0.0, platforms 34/35/36/37.0, system image android-37.0 google_apis_playstore x86_64.
  - Pub.dev lookups (2026-11-05): ffi 2.2.0, ffigen 23.0.0, jni 1.1.2, jnigen 1.0.1, audio_service 0.18.19, audio_session 0.2.4, drift 2.35.3, drift_flutter 0.3.1, sqlite3 3.9.0, flutter_riverpod 3.4.3, go_router 18.1.3, permission_handler 13.0.2, flutter_lints 6.0.0, hooks 2.2.0, code_assets 2.1.0, native_toolchain_c 0.19.5, audio_metadata_reader 1.8.1, metadata_audio 0.9.6. Flutter stable is 3.47.9; 3.50 is still beta.
  - ffigen/libclang probe: no system LLVM, but ffigen 23.0.0 generated AAudio bindings from NDK 28.2's `libclang.so` (171,098 bytes, 733 `AAudioStream` references, SHA-256 `5eb38d0e8fcc452893b7ef176aa198cb55647e540c64f23a417928aae5d2da96`). `dart analyze` on the generated file: 0 errors, 82 warnings (generated code; excluded from analysis in M0.2).
  - `python3 -I tool/check_docs.py`: passed (22 files, 164 section references).
- Decisions: none (no ADR). Lint set recorded in `docs/dev-environment.md`: `flutter_lints` 6.0.0 plus analyzer strict modes and a short extra rule list; generated bindings are excluded from analysis.
- Spec changes: ARCHITECTURE §12 (exact pins and date); new `docs/dev-environment.md`; MILESTONES **Now** and M0.1; README status.
- Open questions for the owner:
  - Can the agent reach the POCO M3 over `adb`, or should on-device steps use the paste-back workflow? (Needed by S1, S4 and S7.)
  - `jnigen` is now 1.0.1, not the 0.16.x line the blueprint saw. S5 must re-verify its config/API under D-012; no action in M0.2.
  - `sqlite3_flutter_libs` is EOL (`0.6.0+eol`). `drift_flutter` 0.3.1 still pulls it as a shim; M2.1 should check whether drift has migrated before the library schema work.
  - ffigen 23 deprecates YAML configuration; `tool/gen_bindings.sh` in M0.2 should use the Dart generator API.
- Next item: M0.2

### 2026-10-31 — Blueprint — initial blueprint written (no code yet)
- Agent: Claude (Sonnet 5.5) in Claude Code, working with Vaibhav · Session: this conversation · Commit or branch: none (not a repository yet)
- Status: 🟡 awaiting owner review of the blueprint and the open decisions below
- Changed: created the whole blueprint.
  - Agent entry points: `AGENTS.md` (canonical), `CLAUDE.md` and `GEMINI.md` (pointers), `README.md` (index and first prompt).
  - Plan and memory: `MILESTONES.md`, `CHANGELOG.md`, `DECISIONS.md` (D-001…D-025), `ASSETS.md`.
  - Design: `ARCHITECTURE.md`; specs `docs/01-product-spec.md` to `docs/10-risks.md`; `docs/research-notes.md`; `docs/human-checks/TEMPLATE.md`.
  - Tooling: `tool/check_docs.py`, a documentation cross-reference check that agents run after editing any document (listed in AGENTS §4; to be wired into `tool/check.sh` in M0.2).
- Evidence: `python3 -I tool/check_docs.py` passes (21 files, 163 section references, and every ADR, requirement, quality, screen, risk and milestone id resolves). Research basis, not tests: the library model and UX concepts come from Fooyin (GPL-3.0) and Audacious (BSD-2-Clause core), studied through their public READMEs, documentation and release notes; the mapping is in `docs/02-ux-spec.md` §1 and `docs/research-notes.md`. Platform and package facts were taken from web searches and documentation during writing. Version numbers in ARCHITECTURE §12 (Flutter 3.47.x with 3.47.2 seen on a docs mirror on 2026-11-05, Dart 3.13.x, `jnigen` 0.16.x, `drift` 2.35.x, `audio_service` 0.18.x) were not checked against pub.dev or the official SDK archive here and **must be re-checked in M0.1**.
- Not verified: every item tagged **[verify]** in the specs is a claim from documentation or reasoning that no one has run on a device. The spikes S1–S7 exist to settle them. The engine design (a Dart pump over AAudio) is plausible but unproven until S1 and S2 report.
- Finding for the owner: the Audacious link in the original brief (`github.com/audacious-music-player/audacious-software`) is not the official project. It has 0 stars, 0 forks and 4 commits, and a generic marketing-style README. The official repository is `github.com/audacious-media-player/audacious` (site: audacious-media-player.org). The blueprint uses the official one; see D-024 and `docs/research-notes.md`.
- Decisions: D-001 to D-025 recorded. `open`: D-001 (name), D-011 (metadata reader, decided in M2.3), D-016 (license). `proposed`, pending spikes: D-004, D-008, D-009.
- Spec changes: none (first version of every file).
- Open questions for the owner: the name and application id (D-001); the license (D-016); whether the agent can reach the POCO M3 over `adb`; the list under "Owner inputs" in MILESTONES.md; whether to approve the blueprint defaults.
- Next item: M0.1
