# Development environment

Status: created in M0.1 on 2026-11-05. Every version here was checked on this host on that date. Update this file whenever a pin changes (normally only at M4.7).

## 1. Host

| Item | Value |
|---|---|
| OS | Fedora Linux 44 (Workstation Edition) |
| Kernel | 7.2.11-200.fc44.x86_64 |
| Architecture | x86_64 |
| RAM / free disk at setup | 15 GiB / 126 GiB on `/home` |
| Shell | bash; environment hooks live in `~/.bashrc.d/` |
| Root access | not available to the agent (`sudo` requires a password); all tools are installed under `$HOME` |

Linux desktop tooling (clang, CMake, ninja, GTK) is incomplete. It is not needed for the Android v1.0 target. If the X-series desktop work starts, install those packages with root access and re-run `flutter doctor -v`.

## 2. Pinned toolchain

| Tool | Pin | Location | Checked with |
|---|---|---|---|
| Flutter | 3.47.9 stable (released 2026-10-29, framework `c197ca5199`) | `~/development/flutter` | `flutter --version` |
| Dart | 3.13.7 stable (2026-10-22) | bundled with Flutter | `dart --version` |
| DevTools | 2.60.0 | bundled with Flutter | `flutter --version` |
| JDK | OpenJDK 25.0.3 (Android Studio JBR, build AI-262.9437.185.2621.16467767) | `~/Downloads/android-studio/jbr` | `flutter doctor -v` |
| Android SDK platform | Android 37.0 (also 34, 35, 36 installed) | `~/Android/Sdk` | `sdkmanager --list_installed` |
| Android build-tools | 36.0.0 (also 34.0.0, 35.0.0) | `~/Android/Sdk/build-tools` | `flutter doctor -v` |
| Android platform-tools / adb | 37.0.1 | `~/Android/Sdk/platform-tools` | `adb version` |
| Android NDK | 28.2.13676358 | `~/Android/Sdk/ndk` | `sdkmanager --list_installed` |
| Android cmdline-tools | 23.0 (Android CLI 1.1.16717390) | `~/Android/Sdk/cmdline-tools/latest` | `sdkmanager --version` |
| Android emulator | 37.2.13 | `~/Android/Sdk/emulator` | `emulator -version` |
| libclang for ffigen | NDK 28.2 `libclang.so` (clang 19 resource headers) | `~/Android/Sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64` | ffigen probe, section 6 |
| Python | 3.14.7 | `/home/linuxbrew/.linuxbrew/bin/python3` | `python3 --version` |

Flutter 3.47.9's Android template uses **Gradle 9.3.1, AGP 9.1.0 and Kotlin 2.4.0**. Its defaults are `compileSdk 36`, `targetSdk 36`, `minSdk 24` and `ndkVersion 28.2.13676358`. The project overrides `minSdk` to 26 in M0.3 and `compileSdk` to 37 in M0.2, because `permission_handler_android` 14.1.1 (pulled by `permission_handler` 13.0.2) refuses to build against API 36. `targetSdk` stays 36 (the Play requirement). AGP 9.1.0 calls 36 its "maximum recommended" compile SDK; compiling against 37 produces that warning only and the debug build succeeds (M0.2). The template sets Java/Kotlin compatibility to 17; the toolchain requires JDK 17 or newer and accepts the installed JDK 25.

Android 16 / API 36 is the current Google Play target requirement for new apps and updates (in force since 2026-08-31), so `targetSdk 36` stays. Re-checked on the Play Console target-API page on 2026-11-08 (M0.3): a further bump is not required before M4.6.

## 3. Setup commands

The reusable environment is in `~/.bashrc.d/gramotune-toolchain.sh`, which `~/.bashrc` sources:

```sh
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export JAVA_HOME="$HOME/Downloads/android-studio/jbr"
export FLUTTER_ROOT="$HOME/development/flutter"
export PATH="$JAVA_HOME/bin:$FLUTTER_ROOT/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$PATH"
```

Fresh-machine steps used here:

```sh
# Flutter, pinned and checksum-verified (sha256 from releases_linux.json)
mkdir -p ~/development && cd ~/development
curl -fLO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.9-stable.tar.xz
sha256sum flutter_linux_3.47.9-stable.tar.xz   # 25ed8c3c29d51a7353f2a944310b478af8214920639524b19c50a19e6c044c5a
tar xf flutter_linux_3.47.9-stable.tar.xz && rm flutter_linux_3.47.9-stable.tar.xz

# Android cmdline-tools (sdkmanager/avdmanager)
mkdir -p ~/Android/Sdk/cmdline-tools
curl -fLO https://dl.google.com/android/repository/commandlinetools-linux-16111833_latest.zip
unzip -q commandlinetools-linux-16111833_latest.zip -d /tmp/cmdline
mv /tmp/cmdline/cmdline-tools ~/Android/Sdk/cmdline-tools/latest

# SDK packages and licenses
sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" "ndk;28.2.13676358"

# Flutter settings
flutter config --android-sdk "$HOME/Android/Sdk" --android-studio-dir "$HOME/Downloads/android-studio"
```

Notes: `sdkmanager` now prints a deprecation warning and points at the `android sdk` CLI; the current binary still works and `--licenses` reports that it is no longer required because every license is already accepted. `flutter doctor -v` reports two adb binaries (`~/Android/Sdk/platform-tools/adb` 37.0.1 and `/usr/bin/adb` 37.0.0p1); the `PATH` above picks the SDK copy. The warning is cosmetic.

## 4. Devices

### POCO M3 (`citrus`) — the target device

Connected over USB on 2026-11-08 and authorized, so on-device work runs directly (no paste-back workflow; owner approved `adb` on 2026-11-05).

```sh
adb devices -l
# b9b56e3c1220  device usb:3-2 product:lineage_chime model:M2010J19CG device:citrus
adb -s b9b56e3c1220 shell "getprop ro.product.device; getprop ro.build.version.sdk"
# citrus
# 37
```

The device runs LineageOS (`lineage_chime`, `M2010J19CG`, Android 17 / API 37, user build). An unrelated A069 phone (`002977645001032`, `FroggerIND`, API 37) was attached on 2026-11-05 and used once for an install smoke test; it is not the POCO and is not a target.

### On-device integration test

The M0.2 launch proof is `app/integration_test/placeholder_test.dart`. It starts the real app, asserts that `appFlavor` is set and matches `EXPECTED_FLAVOR`, and that the placeholder shows `M0.2 placeholder · <flavor> flavor`.

```sh
cd app
flutter test integration_test -d b9b56e3c1220 --flavor play --dart-define=EXPECTED_FLAVOR=play
flutter test integration_test -d b9b56e3c1220 --flavor full --dart-define=EXPECTED_FLAVOR=full
```

Prefer this over `uiautomator dump`: Flutter exposes no text nodes to `uiautomator` unless an accessibility service is active, so the dump contains only the `FlutterView`. Setting `settings put secure accessibility_enabled 1` does not help and makes `uiautomator dump` fail with `null root node returned by UiTestAutomationBridge`.

### Emulator — broken on this host (2026-11-08)

The AVD is `gramotune_a36` (recreated from `tonearm_a36` after the 2026-11-08 rename) (`system-images;android-36;google_apis_playstore;x86_64`, `pixel_5`, 2560 MB, 4 cores). It boots in about 20 s and accepts adb, but the emulator process dies as soon as the guest renders a frame, with `SIGILL`/`SIGSEGV` inside `libgfxstream_backend.so` (`gles2_decoder_context_t::decode` on the `RenderThread`; `ColorBufferGl::create` → `TextureResize`). Reproduced on emulator 37.2.12 and 37.2.13 with `-gpu host`, `-gpu swangle_indirect`, `-gpu swiftshader_indirect` and `-gpu off`. Host: Fedora 45, Mesa 26.2.6, hybrid Intel Iris Xe + NVIDIA MX450 (NVK), Wayland, KVM usable. This is an emulator/host-graphics bug, not a project bug; it is a risk for M0.4 and M0.2 was closed on the POCO instead (owner-approved 2026-11-08).

```sh
# what was tried (each crashes within ~35 s of guest GL work)
emulator -avd gramotune_a36 -no-window -no-audio -no-boot-anim -no-snapshot \
  -gpu swangle_indirect -memory 2560 -cores 4
coredumpctl info            # TID RenderThread, Signal 4 (ILL), libgfxstream_backend.so
```

Findings worth keeping:

- Play Store images ship `ro.adb.secure=1`. A freshly created (or `-wipe-data`d) AVD accepts `~/.android/adbkey` at boot and shows `device`; an AVD whose userdata predates that key stays `unauthorized` and cannot be approved on a headless emulator.
- A crashed emulator leaves lock files behind; the next start fails with "Running multiple emulators with the same AVD". Remove `~/.android/avd/<name>.avd/*.lock` first.
- If an emulator is needed later, install an older emulator build outside `sdkmanager` (the SDK only offers 37.2.x now) or run it on a machine without the hybrid-GPU/Wayland combination. M0.4's nightly job also uses a CI runner, which avoids this host entirely.

## 5. Lint set

Choice recorded in M0.1, implemented in M0.2:

- Base: `flutter_lints` 6.0.0 (official set, tracks the SDK, no extra dependency).
- Analyzer strict modes: `strict-casts`, `strict-inference`, `strict-raw-types`.
- Extra rules: `always_declare_return_types`, `avoid_dynamic_calls`, `cancel_subscriptions`, `close_sinks`, `discarded_futures`, `prefer_final_locals`, `unawaited_futures`.
- Generated bindings are excluded from analysis (ffigen and jnigen output), because generated code emits warnings the project does not own. The ffigen probe produced 82 warnings and 0 errors on generated bindings; see section 6.
- `very_good_analysis` 11.0.0 was available but is not adopted; the project gets strictness from the analyzer modes above without another third-party rule set.

The resulting `analysis_options.yaml` is created at the workspace root in M0.2. `tool/check_tokens.dart` remains the place for project-specific bans (`print`, literal colors, `isLeaf`).

## 6. ffigen and libclang

There is no system LLVM/libclang installation and `sudo` is unavailable. The NDK ships a working `libclang.so`; ffigen 23.0.0 used it directly.

Verified with a throwaway package in `/tmp` (not committed):

```yaml
name: AaudioProbe
description: Minimal AAudio binding probe for M0.1
output: 'aaudio_probe.dart'
llvm-path:
  - '/home/vaibhav05/Android/Sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64/lib/libclang.so'
compiler-opts:
  - '--target=aarch64-linux-android26'
  - '--sysroot=/home/vaibhav05/Android/Sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64/sysroot'
  - '-resource-dir=/home/vaibhav05/Android/Sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/19'
headers:
  entry-points:
    - '/home/vaibhav05/Android/Sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/aaudio/AAudio.h'
```

Result: `aaudio_probe.dart`, 171,098 bytes, 733 references to `AAudioStream`, SHA-256 `5eb38d0e8fcc452893b7ef176aa198cb55647e540c64f23a417928aae5d2da96`. `dart analyze` reported 0 errors and 82 warnings (all in generated code).

Findings for M0.2:

- The `--target`, `--sysroot` and `-resource-dir` compiler options are all required; without them clang cannot find `stdbool.h` or `asm/types.h`.
- ffigen 23.0.0 deprecates the YAML configuration file in favour of the programmatic Dart generator API. `tool/gen_bindings.sh` should use the Dart API; if it keeps YAML for now, the deprecation warning is expected and must not be treated as a failure.
- If a future NDK bump removes the bundled `libclang.so`, the fallback is `sudo dnf install clang-devel` and pointing `llvm-path` at the system `libclang.so`.

## 7. Reproduce the M0.1 check

```sh
flutter --version
flutter doctor -v
adb devices -l
sdkmanager --list_installed
python3 -I tool/check_docs.py
```

Expected: Flutter and the Android toolchain report `[✓]`; the Linux desktop and multiple-adb notices remain as described above.
