#!/usr/bin/env bash
# First-run setup for this host (docs/dev-environment.md §3). Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."

resolve_flutter() {
  if [[ -n "${FLUTTER_BIN:-}" ]]; then
    printf '%s' "$FLUTTER_BIN"
  elif command -v flutter >/dev/null 2>&1; then
    command -v flutter
  elif [[ -x "$HOME/development/flutter/bin/flutter" ]]; then
    printf '%s' "$HOME/development/flutter/bin/flutter"
  else
    echo "flutter not found; see docs/dev-environment.md §3" >&2
    return 1
  fi
}

FLUTTER="$(resolve_flutter)"

printf 'Flutter: %s\n' "$("$FLUTTER" --version | head -n 1)"
printf 'Dart:    %s\n' "$("$(dirname "$FLUTTER")/dart" --version)"

if [[ -n "${ANDROID_HOME:-}" ]]; then
  printf 'Android: %s\n' "$ANDROID_HOME"
else
  printf 'Android: ANDROID_HOME is not set (host tests still work; builds need it)\n' >&2
fi

printf '\n==> flutter pub get (workspace root)\n'
"$FLUTTER" pub get

printf '\n==> generated bindings\n'
tool/gen_bindings.sh

printf '\nsetup.sh: done. Next: tool/check.sh\n'
