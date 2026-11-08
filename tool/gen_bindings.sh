#!/usr/bin/env bash
# Generates the FFI and JNI bindings. Stub in M0.2: ffigen lands in S1/S2 and
# jnigen in S5 (docs/dev-environment.md §6, DECISIONS.md D-012).
set -euo pipefail
cd "$(dirname "$0")/.."

cat <<'EOF'
gen_bindings.sh: nothing to generate yet.

Planned:
  packages/engine/lib/src/bindings/aaudio.dart          ffigen, S1
  packages/engine/lib/src/bindings/mediandk.dart        ffigen, S2
  packages/platform_android/lib/src/bindings/android/   jnigen, S5

ffigen 23 deprecates YAML configuration, so the generators will be Dart
scripts driven from this shell wrapper (see docs/dev-environment.md §6).
Generated output is excluded from analysis and is never edited by hand.
EOF
