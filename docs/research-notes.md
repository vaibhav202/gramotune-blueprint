# Research notes

Status: v0.1 (written 2026-10-31, Flutter line re-checked 2026-11-05). This file records what the blueprint rests on, where each fact came from, and what nobody has verified yet.

**How to read it.** *Seen* means read in a web page or search result while writing. *Recalled* means background knowledge that was not re-read. Both are starting points: the milestone named in the last column re-verifies them, and anything a running experiment contradicts wins over this file.

## 1. Reference projects (UX ideas only, D-024)

### Fooyin
- A customisable desktop music player (Qt, GPL-3.0). Source: <https://github.com/fooyin/fooyin>; docs: <https://docs.fooyin.org/en/latest/>. The fetch tool could not open the docs pages, so the details below come from the repository README and search snippets of it and of the release notes (<https://newreleases.io/project/github/fooyin/fooyin/release/v0.14.0>).
- Seen features that shaped the blueprint: library tree with a directory-structure view; directory browser; standard playlists, dynamic autoplaylists and a playback queue; M3U and M3U8 import and export; tag editor; waveform seekbar; ReplayGain; scrobbling; FooScript for display formatting, queries and autoplaylists; plugins for widgets, decoders, tag readers and DSPs; layouts built from a blank canvas or presets. Windows builds exist from the 0.12 line; 0.14.x releases were seen.
- Use: the concept-to-mobile mapping is in `docs/02-ux-spec.md` §1. No code is read, copied or translated. Reusing GPL code would turn the project's license into a forced choice.

### Audacious
- Official repository: <https://github.com/audacious-media-player/audacious> ("A lightweight and versatile audio player", about 1.3k stars and 158 forks when seen); site: <https://audacious-media-player.org>.
- License: BSD-2-Clause for the core. The README says many of the plugins distributed with Audacious use other licenses (see `COPYING` and each plugin), which is why AGENTS.md treats the whole project as reference-only.
- Seen: plugin families for input, output, effects, general, visualization, playlist formats (M3U, ASX, cue sheets) and transports (HTTPS, FTP, SMB); GTK, Qt and Winamp-classic-skin interfaces; plugin names such as playlist-manager, search-tool, song-info, playback-history and lyrics in packaging files. Plugins live in a separate repository of the same organization.
- Recalled, not re-read: the keyboard shortcuts quoted in `docs/02-ux-spec.md` §1 (jump to song, queue, stop after current, song info). Check the manual before quoting them in user-facing text.

### Warning: the Audacious link in the original brief is a lookalike
- The brief linked `https://github.com/audacious-music-player/audacious-software`. The organization name differs from the official `audacious-media-player`, which the official site and distribution packaging point to.
- What was seen on the page: 0 stars, 0 forks, 4 commits; a README written in generic marketing language ("develops a fast, open-source listening experience…"); file names copied from upstream (`meson.build`, `COPYING`, `NEWS`, `audtool.1.in`, `aud-dbus.xml`); an owner id (342733420) far higher than the official organization's (1249822). GitHub ids are sequential, so that account is much newer. The last point is an inference.
- Conclusion: it looks like a repackaged copy of upstream under another name. Do not clone, build, depend on or link to it. If the link came from a search engine or a chatbot, double-check other links from the same source. If the owner meant a different project, tell the agent.

## 2. Technology facts the blueprint relies on

| # | Fact | Source | Where used | Verify in |
|---|---|---|---|---|
| 1 | Flutter 3.47 was released 2026-08-12 and 3.47.2 was the docs version on 2026-11-05; the previous stables were 3.44 (2026-05-18) and 3.41 (2026-02-11). The next stable, 3.50, is expected around Nov 2026 and was not listed yet. | <https://docs.flutter.cn/release/whats-new> (mirror; also <https://docs.flutter.dev/release/archive>) | ARCHITECTURE §12, R13 | M0.1, M4.7 |
| 2 | AAudio offers blocking `AAudioStream_write` with a timeout; exclusive sharing and MMAP are requests the system may decline, so the granted mode and format are read back after opening; xrun counts and presentation timestamps are available. | <https://developer.android.com/ndk/guides/audio/aaudio/aaudio>, <https://source.android.com/docs/core/audio/aaudio> | 03 §6, 06 | S1, D1 |
| 3 | `NativeCallable.listener` is asynchronous and returns nothing; `isolateLocal` callbacks must run on the thread that created them; `isLeaf: true` calls hold up GC safepoints for the isolate group while they run. *Recalled* from the `dart:ffi` API docs. | <https://api.dart.dev/dart-ffi/NativeCallable-class.html> (not re-fetched) | D-005, AGENTS §6 | S1 |
| 4 | Dart build hooks (`hooks`, `code_assets`, `native_toolchain_c`) let a package build and bundle native code without Gradle or CMake glue. | <https://dart.dev/tools/hooks>, <https://pub.dev/packages/native_toolchain_c> | D-004 | only if D-004 is invoked |
| 5 | `jnigen` generates Dart bindings for Java and Kotlin APIs, including Android SDK classes (0.16.x seen). | <https://pub.dev/packages/jnigen>, <https://github.com/dart-lang/native/tree/main/pkgs/jnigen> | D-012 | S5 |
| 6 | `audio_service` 0.18 runs its handler in the main isolate (single-isolate model); it replaced the older background-isolate design. | <https://pub.dev/packages/audio_service> (0.18 changelog), <https://github.com/ryanheise/audio_service> | D-008 | S4 |
| 7 | Android 14 requires a foreground-service type; `mediaPlayback` needs `FOREGROUND_SERVICE_MEDIA_PLAYBACK`. | <https://developer.android.com/guide/components/fg-service-types> | 05 §3, §5 | S4 |
| 8 | Media access: `READ_MEDIA_AUDIO` on API 33+, `READ_EXTERNAL_STORAGE` up to API 32. | <https://developer.android.com/training/data-storage/shared/media> | 05 §3 | S5 |
| 9 | USB bit-perfect: from API 34, `AudioMixerAttributes` with behavior `BIT_PERFECT` is set per USB device through `setPreferredMixerAttributes`; it applies to media usage over USB. | <https://developer.android.com/media/platform/improve-audio-playback> | 06 §7 | D2 |
| 10 | Gapless data lives in LAME or Xing headers and `iTunSMPB` tags (Media3's `GaplessInfoHolder` documents the parsing). Reports differ on whether platform codecs trim by themselves. Media3 is background reading only; we do not use it (D-002). | <https://developer.android.com/reference/androidx/media3/extractor/GaplessInfoHolder> | 03 §5 | S3 |
| 11 | Flutter fragment shaders: GLSL `.frag` only, no vertex shaders, no UBO or SSBO, `sampler2D` only, `FlutterFragCoord()` for position; `ImageFilter.shader` needs Impeller. | <https://docs.flutter.dev/ui/design/graphics/fragment-shaders> | 09 §8 | S6 |
| 12 | `drift` 2.35.x; `drift_flutter` provides isolate-shared databases (`shareAcrossIsolates`). | <https://pub.dev/documentation/drift/latest/>, <https://pub.dev/documentation/drift_flutter/latest/> | D-010 | M2.1 |
| 13 | Pure-Dart tag readers exist: `audio_metadata_reader` and `metadata_audio`. | <https://pub.dev/documentation/audio_metadata_reader/latest>, <https://pub.dev/documentation/metadata_audio/latest> | D-011 | M2.3 |

## 3. Not researched, on purpose or yet

- Fooyin and Audacious source code (D-024).
- Apple's iOS 6 visual specifications and assets. The look comes from the owner's Figma work and original artwork (09 §11).
- YouTube extractors and the exact YouTube terms; `docs/07-sources-spec.md` §9 is a summary, not legal advice. Y0 does the real evaluation.
- The audio HAL and codec of the POCO M3 (`citrus`) under LineageOS. S7 and the D-series find out.
- Behavior on vendor ROMs with aggressive battery management (M4.3).
- Which tool writes `iTunSMPB` into test files (M0.5).
