# ARCHITECTURE.md

Status: v0.1 blueprint (2026-10-31). Specs referenced as `docs/NN-*.md`. Decisions referenced as `D-nnn` (DECISIONS.md).

## 1. Constraints that shape everything

- Flutter + Dart only; the audio engine is Dart (D-002). Native access is FFI (AAudio, NDK media) and JNI via generated bindings (D-012).
- Android first, minSdk 26. Desktop later, so engine logic stays platform-neutral behind interfaces (D-015).
- v1.0 is a polished local player for average users. Direct output is a later track that must slot in without touching the UI (D-020).
- Agent-driven development: small packages, hard boundaries, tests that machines can run, human checks for anything audible.

## 2. System overview

```
UI isolate (Flutter)
  Screens ── Riverpod providers ── PlaybackController (owns queue, persists it)
     │                                  │                │
  ui_kit + skin                    EngineClient      AudioHandler ◄── notification / lock screen /
     │                              (engine_api)     (audio_service)    headset / Bluetooth
  music_library (drift) ◄── DB isolate        │
     ▲                                  │ SendPort (commands ↓, state/events ↑, ≤20 msg/s)
     │ writes                           ▼
  Scanner isolate                 ENGINE ISOLATE (pure Dart)
                                    EngineHost → Timeline (window of items) → Decoder (AMediaExtractor + AMediaCodec, FFI)
                                                     → DSP (ReplayGain → EQ → dither/limiter) → OutputBackend ─ AAudio (FFI)
                                                                                                      └ later: Exclusive, USB, RootAlsa
```

## 3. Repository layout (Dart workspace)

```
gramotune/
├─ pubspec.yaml               workspace root
├─ packages/
│  ├─ engine_api/             commands, events, PlayItem, OutputBackend + Decoder interfaces (pure Dart)
│  ├─ engine/                 engine implementation, DSP, FFI bindings (aaudio, mediandk)
│  ├─ music_library/         drift schema, scanner, queries, playlists, metadata, art cache
│  ├─ sources/                SourceProvider interface + local provider (youtube lives in sources_youtube later)
│  ├─ platform_android/       jnigen bindings + wrappers: MediaStore, AudioManager, device info
│  ├─ skin/                   skin model, token loader, shader helpers
│  └─ ui_kit/                 skeuomorphic widgets (nav bar, tab bar, segmented control, scrubber, knob…)
├─ app/                       composition root, screens, routing, audio_service adapter, flavors
├─ tool/                      check.sh, check_boundaries.dart, check_tokens.dart, check_docs.py, gen_bindings.sh, golden generators
├─ test_assets/               tiny licensed fixtures + expected hashes
└─ android-module/            Magisk module sources (scripts, XML; later, D-track)
```

Import rules are in `AGENTS.md` §5 and enforced by `tool/check_boundaries.dart` (D-014).

## 4. Runtime topology

| Isolate | Lives | Does | Must not |
|---|---|---|---|
| UI | app lifetime | widgets, providers, `PlaybackController`, `AudioHandler` | call audio FFI, block >8 ms |
| Engine | while playing or armed | decode, DSP, output pump, timeline | touch Flutter or the DB |
| DB | app lifetime (shared) | drift queries via `drift_flutter` `shareAcrossIsolates` | run UI code |
| Scanner | during scans | MediaStore walk, tag reads, art extraction, batch writes | hold DB write locks >50 ms |

Notes:
- `audio_service` 0.18 runs the handler in the main isolate (no separate background isolate). The handler is therefore a thin adapter: it forwards media-session commands to `PlaybackController` and mirrors engine state back to the session. Verified in S4 (D-008).
- Isolates started with `Isolate.spawn` share an isolate group, so GC safepoints are shared. The engine thread is mostly inside blocking native calls and buffers hundreds of milliseconds, so short GC pauses are tolerable. S1 measures this under UI jank.

## 5. Playing a track (sequence)

1. User taps a track. `PlaybackController` builds a **play context** (ordered list), persists it, and sends `LoadWindow(items, startIndex, startPositionUs)` to the engine (a window of up to ~500 `PlayItem`s, D-022).
2. Engine opens the extractor and codec for item 0, reads the format, opens the output stream at the item's rate and channels (D-006), and starts pumping.
3. While item *n* plays, the engine prepares item *n+1* (extractor, codec, first chunks decoded) so the transition needs no output reopen when the format matches (gapless).
4. Engine emits `PositionTick` (≤10 Hz when UI visible, ≤1 Hz otherwise), `ItemChanged`, `StateChanged`, `NeedMoreItems(afterIndex)` (when ≤50 items remain), and `Error`.
5. `PlaybackController` refills the window, writes play counts and history to the DB, and updates the session through `AudioHandler`.

## 6. Engine pipeline (summary; detail in `docs/03-engine-spec.md`)

```
Extractor → Codec → PCM (i16 | f32) → [trim: leading/trailing padding] → [ReplayGain] → [EQ] → [dither if narrowing]
          → output format conversion (only if required) → OutputBackend.write → AAudio stream
```

- Internal DSP format is float32. With all DSP off and a matching output format, samples pass through untouched (bit-transparent, testable by hash).
- One output stream format at a time. Format change (rate, channels, encoding) reopens the stream; gapless is guaranteed only across identical formats (D-006).
- Pump model: decode ~100 ms chunks, write with a short timeout, then yield to the event loop so commands are handled within ~50 ms (no `isLeaf`, no native→Dart callbacks).

## 7. Queue ownership

`PlaybackController` (UI isolate) is authoritative for the play context, shuffle order, repeat-all and the Up Next queue, and persists them in the database. The engine plays a window sequentially and natively supports repeat-one and stop-after-current, because those must be gapless-safe. If the window runs dry the engine stops cleanly and emits `QueueEnded`.

## 8. Library and database

- drift on SQLite. A flat `tracks` table plus derived `albums` and `artists`, join tables for multi-valued artist and genre, playlists, queue, history, scan roots (`docs/04-library-spec.md`).
- Track identity supports local, remote and cached states from day one (`origin`, `local_uri`, `remote_ref`), so downloaded YouTube files merge into the same library later (D-023).
- Scanner is incremental and runs in its own isolate. MediaStore is the primary index; folders chosen via SAF are a fallback (D-009).

## 9. Android integration

- Foreground service with type `mediaPlayback` and a `MediaSession`, supplied by `audio_service` (`docs/05-android-platform-spec.md`).
- Audio focus, becoming-noisy and ducking via `audio_session`.
- System volume is mirrored in-app; no software volume stage by default (D-007).
- `platform_android` wraps JNI calls: MediaStore queries, `AudioManager` properties, mixer attributes (later).

## 10. Skin system

A skin is a token set (colors, metrics, typography), nine-slice and texture assets, and shader parameters, loaded from a folder that follows `docs/09-design-handoff.md` (D-018). v1.0 ships one built-in skin ("Classic") and one plain high-contrast skin. User-loadable skins come in v1.1. Shaders are used sparingly (Now Playing showpieces); everything else is baked textures (S6 decides the budget).

## 11. Flavors and distribution

- `play`: local only, no `INTERNET` permission, no YouTube code. Suitable for Play Store and F-Droid.
- `full`: adds the YouTube source plugin (Y-series). Distributed outside Play (D-013).
- Root and Magisk tooling is a separate companion artifact in `android-module/` and never ships inside the APK.

## 12. Dependencies (verified and pinned 2026-11-05)

Checked against pub.dev, the Flutter release archive and the installed Android SDK on 2026-11-05 (M0.1). M0.2 writes these exact versions into the pubspecs; do not float them. Host details and setup commands are in `docs/dev-environment.md`.

| Purpose | Package | Version (2026-11-05) | Note |
|---|---|---|---|
| SDK | Flutter / Dart | 3.47.9 stable / 3.13.7 | Released 2026-10-29. 3.50 is still beta (3.50.0-0.4.pre on 2026-11-04); do not upgrade before M4.7 |
| Android build | Gradle / AGP / Kotlin | 9.3.1 / 9.1.0 / 2.4.0 | Flutter 3.47.9 template defaults; `compileSdk` 37 (permission_handler_android 14.1.1 needs it), `targetSdk` 36, NDK 28.2.13676358, JDK 17 minimum (JDK 25 works) |
| FFI | `ffi`, `ffigen` | 2.2.0, 23.0.0 | Bindings for `aaudio/AAudio.h`, `media/NdkMediaCodec.h`, `media/NdkMediaExtractor.h`, `media/NdkMediaFormat.h`. ffigen 23 deprecates YAML config; M0.2 uses the Dart generator API |
| JNI | `jni`, `jnigen` | 1.1.2, 1.0.1 | Android Java APIs without our own Kotlin. The blueprint expected the 0.16.x line; current is 1.0.1, so S5 re-verifies config and API (D-012) |
| Service | `audio_service`, `audio_session` | 0.18.19, 0.2.4 | Single-isolate model; check forks only if upstream blocks us |
| DB | `drift`, `drift_flutter`, `sqlite3` | 2.35.3, 0.3.1, 3.9.0 | `sqlite3_flutter_libs` 0.6.0+eol is EOL and appears only as a `drift_flutter` shim; FTS5 checked in M2.1 |
| Metadata | `audio_metadata_reader`, `metadata_audio` | 1.8.1, 0.9.6 | Candidates only; decided in M2.3 behind a `MetadataReader` interface |
| State, routing | `flutter_riverpod`, `go_router` | 3.4.3, 18.1.3 | D-017; go_router 18 needs Flutter 3.44 or newer (satisfied) |
| Permissions | `permission_handler` | 13.0.2 | Runtime permissions only |
| Hooks (optional) | `hooks`, `code_assets`, `native_toolchain_c` | 2.2.0, 2.1.0, 0.19.5 | Only if S1/S2 force bundled C (D-004); already transitive dependencies of ffigen 23 |
| Lint | `flutter_lints` | 6.0.0 | Base set plus strict analyzer modes and a few extra rules; recorded in `docs/dev-environment.md` |

## 13. Observability

- Local rotating log (no network) viewable and exportable from Settings › Diagnostics.
- Diagnostics screen: engine state, stream format and backend, xrun count, buffer fill, decoder names, last errors.
- Debug builds record timeline summaries to the console for `flutter drive --profile` runs.
