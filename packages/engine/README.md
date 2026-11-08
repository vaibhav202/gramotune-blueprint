# engine

The audio engine: decoder, DSP, timeline and output pump in one isolate.

## Boundaries

- May import `engine_api` and `ffi`; may use `dart:` libraries except `dart:ui`.
- Never Flutter, `music_library`, `sources`, `platform_android`, `ui_kit`, `skin` or
  the app (AGENTS.md §5). Enforced by `tool/check_boundaries.dart`.
- Only this package calls AAudio and MediaCodec FFI (AGENTS.md §6).

## Public API

Added in M1 (docs/03-engine-spec.md): `EngineHost`, the AAudio `OutputBackend`,
the NDK `Decoder`, the DSP chain and the trim planner.

## Status

Skeleton created in M0.2. Bindings and implementation land in S1, S2 and M1.
`tool/gen_bindings.sh` is a stub until then.
