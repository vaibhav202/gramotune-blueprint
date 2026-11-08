#!/usr/bin/env bash
# Merged release manifest permission guard (05 §3, P-18).
#
# The `play` flavor must declare no `INTERNET` permission, no flavor may
# declare anything outside the exact list in 05 §3, and READ_EXTERNAL_STORAGE
# must carry `maxSdkVersion=32`. Debug and profile builds add `INTERNET` for
# tooling, so only a release build is checked.
#
# The manifest merger injects `<pkg>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`
# (a `<permission>` plus a matching `<uses-permission>`) for androidx.core's
# dynamic broadcast receivers; the guard allows exactly that name suffix.
#
# Usage:
#   tool/check_manifest.sh [flavor]      build a release APK for the flavor
#                                        (default `play`) and check it
#   tool/check_manifest.sh --self-test   run the rule over fixtures only
#                                        (no build); wired into tool/check.sh
# Exit code 0 means compliant.
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$1"; }

# --- the rules ---------------------------------------------------------------
# ALLOWED is the exact list from 05 §3 plus the AndroidX-injected custom
# permission. Anything outside it fails; FORBIDDEN exists for a clearer
# message on the never-requested permissions.
ALLOWED="android.permission.READ_MEDIA_AUDIO
android.permission.READ_EXTERNAL_STORAGE
android.permission.READ_MEDIA_IMAGES
android.permission.POST_NOTIFICATIONS
android.permission.FOREGROUND_SERVICE
android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK
android.permission.WAKE_LOCK
*.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"

FORBIDDEN="android.permission.INTERNET
android.permission.MANAGE_EXTERNAL_STORAGE
android.permission.RECORD_AUDIO
android.permission.ACCESS_MEDIA_LOCATION"

allowed_name() {
  local name="$1" entry
  while read -r entry; do
    if [[ "$entry" == \*.* ]]; then        # suffix rule (injected permissions)
      if [[ "$name" == *"${entry#\*.}" ]]; then return 0; fi
    elif [[ "$name" == "$entry" ]]; then
      return 0
    fi
  done <<<"$ALLOWED"
  return 1
}

# check_permissions <label>  < permission-list
# Input: one space-separated line per permission: `name maxSdkVersion`, where
# maxSdkVersion is `-` when the attribute is absent. Prints findings, exits 0
# when compliant.
check_permissions() {
  local label="$1" name maxsdk status=0
  while read -r name maxsdk; do
    [[ -z "$name" ]] && continue
    if grep -qxF "$name" <<<"$FORBIDDEN"; then
      printf 'FAIL [%s]: %s is on the never-requested list (05 §3)\n' \
        "$label" "$name"
      status=1
    elif ! allowed_name "$name"; then
      printf 'FAIL [%s]: %s is not in the 05 §3 permission list\n' \
        "$label" "$name"
      status=1
    elif [[ "$name" == android.permission.READ_EXTERNAL_STORAGE ]] \
        && [[ "$maxsdk" != "32" ]]; then
      printf 'FAIL [%s]: READ_EXTERNAL_STORAGE must carry android:maxSdkVersion="32" (object: %s)\n' \
        "$label" "${maxsdk:-(none)}"
      status=1
    fi
  done
  if [[ $status -eq 0 ]]; then
    printf 'PASS [%s]: every permission is in the 05 §3 list\n' "$label"
  fi
  return "$status"
}

# --- the extraction ----------------------------------------------------------
# `aapt2 dump xmltree --file AndroidManifest.xml <apk>` on stdin; writes lines
# `name maxSdkVersion` to stdout (maxSdkVersion `-` when absent).
to_permission_lines() {
  awk '
    function flush() {
      if (name != "") printf "%s %s\n", name, (max == "" ? "-" : max)
      name = ""
      max = ""
    }
    /E: uses-permission/ { flush(); in_node = 1; next }
    in_node && /E: / { flush(); in_node = 0 }
    in_node {
      if (match($0, /:name\(0x[0-9a-fA-F]+\)=/)) {
        v = substr($0, RSTART + RLENGTH)
        match(v, /"[^"]+"/)
        name = substr(v, RSTART + 1, RLENGTH - 2)
      } else if (match($0, /:maxSdkVersion\(0x[0-9a-fA-F]+\)=/)) {
        v = substr($0, RSTART + RLENGTH)
        sub(/\(type [^)]+\)/, "", v)
        sub(/ .*/, "", v)
        max = (v ~ /^0x/) ? strtonum(v) : v
      }
    }
    END { flush() }
  ' | sort -u
}

resolve_flutter() {
  if [[ -n "${FLUTTER_BIN:-}" ]]; then printf '%s' "$FLUTTER_BIN"
  elif command -v flutter >/dev/null 2>&1; then command -v flutter
  elif [[ -x "$HOME/development/flutter/bin/flutter" ]]; then printf '%s' "$HOME/development/flutter/bin/flutter"
  else echo "flutter not found; see docs/dev-environment.md, section 3" >&2; return 1
  fi
}

resolve_aapt2() {
  local sdk aapt
  for sdk in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk"; do
    [[ -z "$sdk" ]] && continue
    aapt=$(find "$sdk/build-tools" -maxdepth 2 -name aapt2 2>/dev/null | sort -V | tail -1)
    if [[ -n "$aapt" ]]; then printf '%s' "$aapt"; return 0; fi
  done
  echo "aapt2 not found; set ANDROID_HOME (docs/dev-environment.md, section 3)" >&2
  return 1
}

# --- the fixtures (self-test: passes on the 05 §3 list, fails when a
# --- permission is added; that is the failure case the milestone asks for) ----
run_self_test() {
  local rc=0 got out
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  step "check_manifest.sh --self-test"

  cat >"$TMP/good" <<'EOF'
android.permission.READ_MEDIA_AUDIO -
android.permission.READ_EXTERNAL_STORAGE 32
android.permission.READ_MEDIA_IMAGES -
android.permission.POST_NOTIFICATIONS -
android.permission.FOREGROUND_SERVICE -
android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK -
android.permission.WAKE_LOCK -
app.gramotune.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION -
EOF

  cat >"$TMP/extra" <<'EOF'
android.permission.READ_MEDIA_AUDIO -
android.permission.READ_EXTERNAL_STORAGE 32
android.permission.POST_NOTIFICATIONS -
android.permission.INTERNET -
EOF

  cat >"$TMP/uncapped" <<'EOF'
android.permission.READ_EXTERNAL_STORAGE -
EOF

  if ! out=$(check_permissions "fixture: exact 05 §3 list" <"$TMP/good" 2>&1); then
    printf '%s\n' "$out"
    rc=1
  else
    printf '%s\n' "$out"
  fi

  if out=$(check_permissions "fixture: INTERNET added" <"$TMP/extra" 2>&1); then
    printf 'FAIL [self-test]: adding a permission did not fail the check\n'
    rc=1
  else
    printf '%s\n' "$out"
    printf 'PASS [self-test]: adding a permission fails as required\n'
  fi

  if out=$(check_permissions "fixture: uncapped READ_EXTERNAL_STORAGE" \
    <"$TMP/uncapped" 2>&1); then
    printf 'FAIL [self-test]: READ_EXTERNAL_STORAGE without maxSdkVersion=32 passed\n'
    rc=1
  else
    printf '%s\n' "$out"
    printf 'PASS [self-test]: READ_EXTERNAL_STORAGE without maxSdkVersion=32 fails as required\n'
  fi

  return "$rc"
}

# --- entry --------------------------------------------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ "${1:-}" == "--self-test" ]]; then
  run_self_test
  exit $?
fi

FLAVOR="${1:-play}"
case "$FLAVOR" in
  play|full) ;;
  *) echo "unknown flavor: $FLAVOR (play|full)" >&2; exit 1 ;;
esac

FLUTTER="$(resolve_flutter)"
AAPT2="$(resolve_aapt2)"
APK="app/build/app/outputs/flutter-apk/app-$FLAVOR-release.apk"

step "flutter build apk --release --$FLAVOR"
( cd app && "$FLUTTER" build apk --release --flavor "$FLAVOR" \
  --target-platform android-arm64 )

step "extract merged permissions ($APK)"
"$AAPT2" dump xmltree --file AndroidManifest.xml "$APK" \
  | to_permission_lines >"$TMP/permissions.txt"
cat "$TMP/permissions.txt"
check_permissions "merged release manifest ($FLAVOR)" <"$TMP/permissions.txt"
