/// The audio engine.
///
/// Decodes with the NDK media APIs, runs DSP, and pumps PCM into AAudio from a
/// dedicated engine isolate. Only this package may call AAudio or MediaCodec
/// (AGENTS.md §6).
///
/// Public API (also listed in `README.md`): the concrete `EngineHost` and the
/// AAudio `OutputBackend` are added in M1 (docs/03-engine-spec.md).
library;
