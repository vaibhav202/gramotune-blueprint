# AGENTS.md — how to work on Gramotune

Canonical instructions for any coding agent (Claude Code, Codex, Gemini CLI, Jules, Cursor). `CLAUDE.md` and `GEMINI.md` only point here.

- Name: **Gramotune**, application id `app.gramotune` (owner decision 2026-11-08, D-001 in DECISIONS.md).
- Owner and product lead: Vaibhav. You implement; the owner decides scope.
- Today's baseline: Flutter stable 3.47.x / Dart 3.13.x (verify with `flutter --version` in M0, then pin).

## 1. Mission

Ship a polished, ready-to-use **Android local music player** (v1.0) with an iOS-6-style skeuomorphic skin and an old-school library model borrowed from Audacious and Fooyin. It is built entirely in **Flutter + Dart**, including the audio engine (Dart FFI to AAudio and the NDK media APIs).

After v1.0: direct hardware output (USB bit-perfect, then root/Magisk for the internal jack), then an optional YouTube Music source. The project is open source.

## 2. Read order for every new session

1. This file.
2. `MILESTONES.md`: the first unchecked item is your task unless the owner says otherwise.
3. The spec sections that item links to (`docs/*.md`).
4. `DECISIONS.md`: never contradict an `accepted` ADR. A `proposed` ADR needs owner sign-off before you build on it; say so in your summary.
5. The three newest entries of `CHANGELOG.md` (the first three below its template).

## 3. Source-of-truth order

Owner's latest instruction > accepted ADRs > `docs/*-spec.md` > `ARCHITECTURE.md` > code comments.
If two sources disagree, stop and report the conflict. Do not silently pick one.

## 4. Commands (created in M0.2 and M0.3; keep this list true)

```
tool/setup.sh                       # pin Flutter, pub get at workspace root, generate bindings
tool/check.sh                       # analyze + format check + boundary check + token check + docs check + host tests  (run before finishing)
tool/gen_bindings.sh                # ffigen (aaudio, mediandk) + jnigen (platform_android)
dart run tool/check_boundaries.dart # package import rules (section 5)
dart run tool/check_tokens.dart     # no literal colors, no print(), no isLeaf in engine (docs/08-testing-spec.md §10)
tool/check_manifest.sh              # merged release manifest permissions (CI and before release; M0.3)
python3 -I tool/check_docs.py       # every §n, D-nnn, P-/Q-/U-/R- and milestone id in the docs resolves (shipped with the blueprint)
flutter test integration_test -d <device-id>   # on-device / emulator tests
flutter run -d <device-id> --flavor full       # run the app
```

## 5. Package boundaries (hard rules, enforced by `tool/check_boundaries.dart`)

| Package | May import | Must never import |
|---|---|---|
| `engine_api` | `meta` only | anything of ours, Flutter, FFI |
| `engine` | `engine_api`, `ffi` | Flutter, `music_library`, `jni`, any UI |
| `music_library` | `drift`, `sqlite3`, `path` | Flutter widgets, `engine*` |
| `sources` | `music_library`, `engine_api` | Flutter widgets |
| `platform_android` | `jni`, `music_library` | `engine*`, UI |
| `skin` | Flutter | `engine*`, `music_library` |
| `ui_kit` | Flutter, `skin` | `engine*`, `music_library` |
| `app` | everything above | n/a (composition root only) |

The UI layer talks to the engine only through `engine_api` (`EngineClient`, sealed commands and events). No FFI in `app`, `ui_kit` or `skin`.

`music_library` is the package and directory for the database and scanner. The blueprint first called it `library`, but that is a Dart reserved word and pub rejects it; the owner approved `music_library` on 2026-11-05 (D-014 amendment).

## 6. Engine and real-time rules (hard)

1. The engine runs in its own isolate. Only `engine` calls AAudio or MediaCodec FFI.
2. The hot loop (decode → DSP → write) allocates nothing. Buffers are preallocated at open. No closures, `List.add`, string building or logging inside it.
3. Never mark a blocking native call `isLeaf: true`. Leaf calls delay GC safepoints for the whole isolate group.
4. No Dart callbacks from native threads. `NativeCallable.listener` is asynchronous and void-only; `isolateLocal` must run on the creating thread. Use pumped or blocking writes instead.
5. Isolate messages: at most ~20 per second per type, never per audio chunk, no large payloads. Use `TransferableTypedData` for bytes.
6. Every native handle (`AAudioStream`, `AMediaCodec`, `AMediaExtractor`, `AMediaFormat`, malloc) has an owner class with an idempotent `close()`. Tests assert handle counters return to zero.
7. Handle every error explicitly (negative AAudio results, codec errors, disconnects) per `docs/03-engine-spec.md` §9. No empty `catch`.
8. The default signal chain is bit-transparent. Gain or EQ applies only when the user enabled ReplayGain or EQ. Software volume is off by default (D-007).
9. Playback position is derived from presented frames (`AAudioStream_getTimestamp`), never from frames written.

## 7. Android rules

- No hand-written Kotlin or Java. Platform calls go through `package:jni` with jnigen-generated bindings in `platform_android`. Exceptions: manifest, Gradle config, and what the `audio_service` plugin requires. Need Kotlin anyway? Write an ADR and ask.
- Permissions are exactly those listed in `docs/05-android-platform-spec.md` §3. The core flavor declares no `INTERNET` permission.
- `minSdk` 26 (AAudio). API-gated features use capability checks and a graceful fallback.

## 8. UI rules

- Colors, metrics and textures come from skin tokens only. No literal `Color(...)` outside `skin` and `ui_kit` token files.
- `ui_kit` widgets are presentational: no engine, no database.
- Strings go through ARB localization. Every interactive widget has a semantics label. Minimum tap target 48 dp. Check layouts at 200% font scale.
- Long lists use builders and slivers. No work inside `build`. Decode artwork at display size (`cacheWidth`/`cacheHeight`).
- **Assets: original work only.** Record each asset in `ASSETS.md` (author, source, license). Never copy Apple assets, icons, wallpapers or fonts. Apple, iOS and iPod marks must not appear in the app name, package id or user-visible strings. Docs may say "iOS 6 style" as a description.

## 9. Testing rules

- Every bug fix starts with a failing regression test.
- Changes to decode, DSP or output run the PCM golden tests (`docs/08-testing-spec.md` §3). Changes to queue or gapless run the gapless suite (`docs/08-testing-spec.md` §4).
- **You cannot hear audio or see the device (D-025).** Never write "sounds right" or "smooth on device". Provide evidence (hashes, xrun counts, frame-timing summaries). For everything else, create a Human check file from `docs/human-checks/TEMPLATE.md` and mark the item 🟡 until the owner records the result.

## 10. Working agreement

- One milestone item per session. Do not start the next item uninvited unless the owner said "continue".
- Before finishing: `tool/check.sh` is green; `MILESTONES.md` checkboxes and status are updated; a `CHANGELOG.md` entry is added directly below the template at the top of that file (newest first); an ADR is added or updated if you made an architectural decision.
- Dependencies: prefer permissive licenses (MIT, BSD, Apache-2.0) and recent releases. A new native-code dependency or any copyleft license needs owner approval. Record versions in `ARCHITECTURE.md` §12.
- **Do not copy code from Fooyin (GPL-3.0) or Audacious plugins (mixed licenses).** They are UX references only; read their docs, not their source (D-024).
- Never edit generated files by hand (`*.g.dart`, ffigen and jnigen output). Change the generator config and rerun `tool/gen_bindings.sh`.
- Time-box spikes (the box is in `MILESTONES.md`). If you hit the box, write down findings and stop.
- Keep files under ~400 lines. Each package has a `README.md` listing its public API.

## 11. Ask the owner before you

- Add a dependency with native code, or one with a copyleft license.
- Raise `minSdk`, change the applicationId, or add a permission.
- Deviate from a `proposed` or `accepted` ADR, or when a spike result contradicts a spec.
- Add a feature that is not in `MILESTONES.md`.
- Touch anything under `android-module/` (root tooling) or the YouTube track (Y-series).

## 12. Definition of Done (per milestone item)

- [ ] Acceptance criteria in the milestone item are met, with evidence attached in the CHANGELOG entry.
- [ ] `tool/check.sh` is green; new code has tests; public APIs are documented.
- [ ] No new analyzer warnings; no TODO without a milestone reference.
- [ ] Human check file created if any criterion needs ears, eyes or a real device.
- [ ] `MILESTONES.md`, `CHANGELOG.md` and (if needed) `DECISIONS.md` updated.

## 13. Glossary

- **Now Playing list**: the current play context (an album, a playlist, a search result) with the item being played.
- **Up Next queue**: manual queue that plays before the rest of the Now Playing list (Audacious-style queue).
- **Lens**: a saved way of grouping the library (Artist › Album, Genre › Artist, Folders…), like a Fooyin Library Tree grouping.
- **Signal path**: the displayed chain decoder → DSP → output, with rate, bit depth and backend.
- **Direct output**: any output path that bypasses Android's software mixer (D-series).
