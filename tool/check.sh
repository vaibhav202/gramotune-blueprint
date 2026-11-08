#!/usr/bin/env bash
# The full host check (AGENTS.md §4, docs/08-testing-spec.md §10).
# Green here is a precondition for finishing any milestone item.
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
DART="$(dirname "$FLUTTER")/dart"

step() { printf '\n==> %s\n' "$1"; }

step "flutter pub get"
"$FLUTTER" pub get

step "dart format --set-exit-if-changed"
mapfile -t DART_FILES < <(
  find app/lib app/test app/integration_test packages/*/lib packages/*/test tool test \
    -name '*.dart' -type f 2>/dev/null | sort
)
if [[ ${#DART_FILES[@]} -gt 0 ]]; then
  "$DART" format --output=none --set-exit-if-changed "${DART_FILES[@]}"
fi

step "flutter analyze (warnings and infos are fatal)"
"$FLUTTER" analyze --fatal-infos --fatal-warnings

step "package boundaries"
"$DART" run tool/check_boundaries.dart

step "token and source hygiene"
"$DART" run tool/check_tokens.dart

step "merged release manifest guard (fixtures; the full build check is tool/check_manifest.sh <flavor>)"
tool/check_manifest.sh --self-test

step "documentation cross-references"
python3 -I tool/check_docs.py

step "host tests"
if [[ -d test ]]; then
  "$DART" test
fi
for pkg in app packages/*; do
  [[ -d "$pkg/test" ]] || continue
  if grep -A1 -E '^  flutter:$' "$pkg/pubspec.yaml" | grep -q 'sdk: flutter'; then
    ( cd "$pkg" && "$FLUTTER" test )
  else
    ( cd "$pkg" && "$DART" test )
  fi
done

printf '\ncheck.sh: all green\n'
