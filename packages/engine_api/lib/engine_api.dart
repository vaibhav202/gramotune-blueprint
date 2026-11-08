/// The engine contract.
///
/// Everything the UI layer may know about audio lives here: commands, events,
/// `PlayItem` and the output and decoder interfaces. This package is pure Dart:
/// it must not import Flutter, `dart:ffi` or any implementation package
/// (AGENTS.md §5).
///
/// Public API (also listed in `README.md`): [engineApiVersion]. The command,
/// event and interface types are added in M1 (docs/03-engine-spec.md §2).
library;

/// Version of the engine contract.
///
/// Bumped whenever a command or event changes shape. The engine and the UI
/// must agree on this value when the engine isolate starts.
const int engineApiVersion = 1;
