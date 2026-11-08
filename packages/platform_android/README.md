# platform_android

Android APIs that need Java, called through JNI bindings. No hand-written
Kotlin or Java (D-012).

## Boundaries

- May import `jni` and `music_library`.
- Never `engine`, `engine_api`, `ui_kit`, `skin`, Flutter or the app
  (AGENTS.md §5). Enforced by `tool/check_boundaries.dart`.
- Generated bindings live in `lib/src/bindings/` and are never edited by hand.

## Public API

Added in S5 and M2: `MediaStoreGateway`, `AudioManagerInfo`, the audio focus
and device probe helpers.

## Status

Skeleton created in M0.2. Bindings generation is a stub in
`tool/gen_bindings.sh` until S5.
