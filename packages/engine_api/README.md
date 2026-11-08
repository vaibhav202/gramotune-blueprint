# engine_api

The contract between the UI isolate and the engine isolate. Pure Dart: no
Flutter, no FFI, no database (AGENTS.md §5).

## Public API

- `engineApiVersion` — contract version; the engine and the UI must agree on it.

Added in M1 (docs/03-engine-spec.md §2): sealed `EngineCommand` and
`EngineEvent` hierarchies, `PlayItem`, `OutputBackend`, `Decoder`, `EngineClient`.

## Status

Skeleton created in M0.2. Implementation lands in M1.
