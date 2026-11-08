# 05 — Android platform spec

Status: v0.1 (2026-10-31). Items marked **[verify]** are confirmed in S4 (service lifecycle) or S5 (storage).

## 1. Targets

| Item | Value |
|---|---|
| `minSdk` | 26 (AAudio) |
| `targetSdk` | the current Play requirement at M0 time; check, do not assume |
| ABIs | arm64-v8a primary; armeabi-v7a only if a plugin or the owner needs it |
| Dev devices | POCO M3 (`citrus`, LineageOS 23.2, Android 16) as the DAP reference; the owner's other Android 16 phone; an emulator (API 34 and latest) for CI |
| Flavors | `play` (local only, no `INTERNET`) and `full` (adds the YouTube source; Y-series) |
| App id | `app.gramotune` (owner decision 2026-11-08, D-001) |

## 2. Build notes

- Flutter and Dart pinned per `ARCHITECTURE.md` §12.
- `ffigen` generates bindings from NDK headers (AAudio, `NdkMediaCodec`, `NdkMediaExtractor`, `NdkMediaFormat`); libraries are opened at runtime with `DynamicLibrary.open` so older API levels still load.
- `jnigen` generates Java bindings for `MediaStore`, `ContentResolver`, `AudioManager`, `DocumentsContract` and related classes into `platform_android`. No hand-written Kotlin (AGENTS §7).
- R8 and shrinking enabled for release; keep rules only where a plugin documents them.
- Adaptive icon with a monochrome layer; all artwork original (`ASSETS.md`).

## 3. Permissions (exact list)

| Permission | When | Why |
|---|---|---|
| `READ_MEDIA_AUDIO` | API 33+ | scan and read music via MediaStore |
| `READ_EXTERNAL_STORAGE` (`maxSdkVersion=32`) | API 26–32 | same, on older Android |
| `POST_NOTIFICATIONS` | API 33+, optional | playback notification; the app still plays if denied |
| `FOREGROUND_SERVICE` | all | playback service |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | API 34+ | required for the `mediaPlayback` foreground service type (no runtime prerequisite) |
| `WAKE_LOCK` | all | used by `audio_service` |
| `READ_MEDIA_IMAGES` | API 33+, **optional** | folder artwork (`cover.jpg`) read by path **[verify S5]** |

Never requested: `MANAGE_EXTERNAL_STORAGE`, `RECORD_AUDIO`, `ACCESS_MEDIA_LOCATION`, location, contacts. The `play` flavor has no `INTERNET`.

**Folder artwork question [verify, S5]**: reading `cover.jpg` by path may require `READ_MEDIA_IMAGES` on Android 13+. S5 tests whether `ContentResolver.loadThumbnail` on the audio item returns folder art without that permission. Plan: use thumbnails if they work, otherwise offer the optional permission with a clear explanation.

## 4. Storage access

1. **MediaStore (primary)**: queries via JNI, results written by the scanner (`docs/04-library-spec.md` §3).
2. **Direct file paths**: with `READ_MEDIA_AUDIO` the app can read indexed audio files by path (the `_data` column) **[verify S5 on Android 16]**. The engine and the tag reader prefer paths.
3. **File descriptors**: for `content://` URIs (SAF trees, "Open with"), open `ContentResolver.openFileDescriptor` and pass the fd to `AMediaExtractor_setDataSourceFd` and to the tag reader. Close fds deterministically.
4. **Unmounted volumes**: scanning must never purge tracks on an unmounted SD card (library spec §3).

## 5. Foreground service and MediaSession (`audio_service`)

- Manifest: `AudioServiceActivity` (or a subclass of it), the `AudioService` service with `foregroundServiceType="mediaPlayback"` and `exported`, and `MediaButtonReceiver`, as the plugin documents.
- `audio_service` 0.18 uses a single isolate (the handler lives in the UI isolate). Our `AudioHandler` is a thin adapter to `PlaybackController` (D-008).
- **[verify, S4]** All of these must hold:
  1. Swiping the app from recents keeps playback running while the service lives.
  2. Destroying the Activity does not stop playback or lose controls.
  3. If the OS kills the process, the notification disappears, nothing crashes on relaunch, and state is restored paused.
  4. Headset play/pause and Bluetooth buttons (play, pause, next, previous) work with the screen off.
  5. Starting playback from the notification or a media button after the app was backgrounded for a long time does not hit foreground-service start restrictions.

**Notification**: compact actions previous, play/pause, next; large icon is the artwork; title, artist, album; tapping opens Now Playing. The service leaves the foreground when paused so the notification can be dismissed, and re-enters the foreground on play.

**MediaSession metadata**: title, artist, album, duration, artwork (bitmap or content URI), position. Supported actions: play, pause, stop, seekTo, skipToNext, skipToPrevious, setRepeatMode, setShuffleMode. Custom actions (later): love, stop after current. The queue is exposed to the session when Android Auto becomes a goal (v1.1).

## 6. Audio focus and noisy events (`audio_session`)

Configure the session as music. Policy:

| Event | Behavior |
|---|---|
| Focus gain | resume only if we paused because of a transient loss |
| Transient loss (call, assistant) | pause |
| Transient loss, can duck (navigation, notification) | duck by −12 dB with a 150 ms fade; this is the only software gain outside user DSP, and Signal Path shows "ducked" while active |
| Permanent loss | pause and keep the state; do not auto-resume |
| Becoming noisy (headphones unplugged) | pause; never auto-resume |
| Headset connected | no auto-play unless the user enables "Resume when headphones connect" |

## 7. "Open with" and share intents (P-19)

- Intent filter: `ACTION_VIEW` with `audio/*` for `content` and `file` schemes (and `ACTION_SEND` later).
- Opening a file builds a one-item context (or the containing folder if resolvable) and plays it; Up Next is untouched.
- **[verify, S5]** Which route delivers the initial and `onNewIntent` data to Dart without our own Kotlin: `app_links`, `receive_sharing_intent`, or JNI against the current Activity. If none works, request an ADR to allow a minimal shim.

## 8. System integration details

- Edge-to-edge: apply system insets in the skin layer; Android 15+ enforces edge-to-edge for apps targeting API 35+.
- Predictive back: set `android:enableOnBackInvokedCallback` and use `PopScope` correctly on Now Playing and sheets.
- Notification channel "Playback": low importance, no sound.
- Battery optimization help page in Settings: explain how to exempt the app on aggressive OEM ROMs. The reference DAP runs LineageOS, so this path needs a test on another vendor's ROM before v1.0.
- Large heap is not requested; artwork is decoded at display size.

## 9. Lifecycle matrix (what must work, tested in S4 and again in M4)

| Scenario | Expected |
|---|---|
| App in background, screen off, 30 min | continuous playback, 0 xruns |
| Rotate during playback | no restart, UI restores |
| Phone call during playback | pause; resume after the call only if we were playing |
| Bluetooth connects | route changes, playback continues on the new route without restart (or pause per policy) |
| Low-memory kill | relaunch restores paused queue |
| Force stop | no auto-play on relaunch |
| Storage unmounted mid-playback | item fails with a clear reason, next item plays |

## 10. Release and distribution

- Signing config documented in `docs/release.md` (created in M4.6); keystores never committed.
- `flutter build apk --split-per-abi` and `appbundle` for `play`; the `full` flavor is built separately.
- Repository metadata prepared for F-Droid (fastlane layout) when D-016 (license) is decided; dependencies must be buildable from source.
