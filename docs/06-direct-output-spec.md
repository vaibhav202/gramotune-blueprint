# 06 — Direct output spec (D-series)

Status: v0.1 (2026-10-31). **Research-grade.** Nothing here is promised for v1.0. Feasibility on the internal jack depends on the device's HAL and codec, and is unknown until the probe and experiments say otherwise.

## 1. Goal and honesty rules

Goal: get audio from the player to the DAC with as little Android processing as the device allows, on USB and on the internal jack (the owner's main use on the POCO M3).

Honesty rules (enforced in the UI, D-021):
- The app says **"bit-perfect" only with evidence** (§3). Otherwise it says what it knows ("Exclusive stream, MMAP active", "Shared mixer").
- "Bit-perfect to the codec" is not the same as "better sound": analog volume, the DAC and the amplifier stay as they are. The benefit is no sample-rate conversion, no mixing, no system effects, and full bit depth.

## 2. Output levels

| Level | Name | What it bypasses | Root | Evidence possible |
|---|---|---|---|---|
| L0 | AAudio shared (v1.0) | nothing; Android mixer, possible SRC, volume stage | no | E0 |
| L1 | Shared at native rate | SRC only, when the stream rate equals the hardware rate | no | E2 |
| L2 | AAudio exclusive / MMAP | mixer, when the HAL grants MMAP exclusive | no | E2 |
| L3 | USB bit-perfect (`AudioMixerAttributes`, API 34+) | mixer, volume, effects over USB | no | E1 |
| L4 | Direct PCM output via audio policy | mixer, via a Magisk-patched policy | yes | E2 |
| L5 | Raw ALSA from the app | AudioFlinger and HAL routing | yes | E2 (E3 for USB DACs with a digital loopback) |

## 3. Evidence ladder

| Level | Meaning | Example |
|---|---|---|
| E0 | none | shared mixer |
| E1 | platform API reports the behavior | mixer behavior `BIT_PERFECT` is active for the USB device |
| E2 | system state shows the expected path | `dumpsys media.audio_flinger` lists a direct or MMAP output with the expected rate and format; `/proc/asound/cardN/pcmMp/subK/hw_params` shows the live hardware parameters **[verify availability]** |
| E3 | captured digital output matches the source | digital loopback of a USB DAC output hashed against the decoded source |

Signal Path (U-13) displays the evidence level next to the claim.

## 4. Backend contract

All backends implement `OutputBackend` (`docs/03-engine-spec.md` §2) and add:

```dart
OutputCapabilities  // rates, formats (i16, i24-packed, i32, float), sharing modes, exclusive/MMAP,
                    // bit-perfect level and best evidence level, volume control available (bool)
```

Selection lives in Settings › Output: Standard, Exclusive (experimental), USB bit-perfect, Root direct. Any open failure falls back to Standard with a visible message.

## 5. D0 — Probe tool (S7)

A small in-app screen plus a shell script that produce a **device report** the agent can read and commit as `docs/device-notes/<codename>.md`.

**In-app (JNI, no root)**
- `AudioManager` properties: native output sample rate, frames per buffer.
- Output devices: type, id, supported rates, formats, channel masks.
- `isDirectPlaybackSupported` (API 29+) and `getDirectProfilesForAttributes` (API 33+) for media attributes **[verify]**.
- `getSupportedMixerAttributes` for each USB output (API 34+).
- `AudioTrack` offload support.
- AAudio: open an output stream with exclusive sharing and low-latency mode; record granted sharing mode, rate, format, burst, capacity, and `isMMapUsed` (via `dlsym`).

**Root script (`tool/probe_root.sh`, run through `su`)**
- `getprop` filtered for `audio`, `aaudio`, `vendor.audio`.
- `/vendor/etc/audio_policy_configuration.xml` and its includes; `mixer_paths*.xml`.
- `tinymix` output if present; `/proc/asound/cards`, `/proc/asound/pcm`, `ls /dev/snd`.
- `dumpsys media.audio_flinger` and `dumpsys media.audio_policy` while a 44.1 kHz FLAC and a 96 kHz FLAC play.

**Report schema**: device codename, Android version and build, SoC, kernel, each probe above with raw output attached. The report ends with a one-paragraph reading of what looks feasible.

## 6. D1 — AAudio exclusive / MMAP experiment

- Open exclusive plus low-latency streams for 44.1 and 96 kHz on the internal jack, USB, and Bluetooth (for reference).
- Record whether exclusive was granted and whether MMAP is active.
- Play a 10-minute test; record xruns and battery impact.
- If MMAP exclusive is granted on the internal jack: ship it as the experimental "Exclusive" backend at evidence E2 (verify with `dumpsys`).
- If not: record the HAL limitation in the device notes and continue to D3.

## 7. D2 — USB bit-perfect via mixer attributes (API 34+)

Flow (platform behavior per the Android "Improve audio playback" guide):
1. Detect the USB output device.
2. `getSupportedMixerAttributes(device)`; choose attributes that match the track's encoding, channel mask and sample rate with behavior `BIT_PERFECT`.
3. `setPreferredMixerAttributes(AudioAttributes(usage MEDIA), device, attributes)`; listen for `OnPreferredMixerAttributesChangedListener`.
4. Open the AAudio stream with exactly that format. Playback then attaches to the bit-perfect mixer: no mixing, volume adjustment or effects; data goes to the HAL and the USB device as-is.
5. `clearPreferredMixerAttributes` when playback ends or the output changes.

Notes:
- The platform currently allows this for media usage over USB only.
- **Volume warning**: with bit-perfect active, system volume cannot attenuate. Show a one-time safety warning, start with the first track fading in, and recommend low DAC/amp volume.
- Evidence level E1 (API-reported); E3 only with a loopback rig.

## 8. D3 — Magisk module `gramotune-direct` (internal jack, rooted)

Lives in `android-module/`, released as a separate zip. Works on Magisk; KernelSU and APatch use similar module layouts and need separate testing. The module is **systemless** and never writes to system partitions.

Plan (in order of risk):
1. **Properties**: `system.prop` enabling MMAP exclusive where the HAL supports it (`aaudio.mmap_policy` and `aaudio.mmap_exclusive_policy`, set to the value the Android HAL guide describes for "allow exclusive, fall back to shared").
2. **Policy patch**: `customize.sh` patches the device's *own* `audio_policy_configuration.xml` at install time (so it matches the installed firmware) to expose a direct PCM output at the codec's native rates and formats, then overlays it under `system/vendor/etc/`. The module never ships a static copy of a vendor file.
3. **Restart** of the audio server on install and boot where needed.
4. **Safety**: installer refuses unknown devices unless forced; a rescue note explains disabling the module from recovery or Magisk safe mode; uninstall restores stock behavior.

First target: `citrus` (POCO M3). Result must be proven with E2 evidence before anything is called "direct".

## 9. D4 — Raw ALSA from the app (research, rooted)

Idea: with permissions relaxed by the module (`/dev/snd/*` access and SELinux rules via `sepolicy.rule`), the app itself opens the PCM device and writes samples, using `dart:ffi` against libc (`open`, `ioctl`, `mmap`) with a small ALSA PCM implementation in Dart (hardware and software parameters, prepare, write or mmap) and applying mixer routes by parsing the device's `mixer_paths*.xml` for the headphone path.

Hard problems:
- AudioFlinger and the HAL own the PCM device and routing. Taking it requires stopping their use of the device, which can break calls and notifications.
- Routing and codec controls are device-specific.
- A helper binary in C or Rust would be simpler but breaks the Dart-only rule: needs an ADR and owner approval.

**Kill criteria**: park D4 if, after a time-box of 5 working sessions on `citrus`, there is no stable playback with E2 evidence, or if safe restoration of normal audio after a crash cannot be guaranteed.

## 10. D5 — UI, safety, fallback

- Output settings page with the four modes, a clear "experimental" label, and the evidence level.
- Auto-fallback to Standard on open failure, route change or repeated errors.
- "Reset audio" button that clears preferred mixer attributes and restores the Standard backend; for root modes it also restores saved mixer state.
- Never auto-enable experimental modes; never persist them across a crash loop (disable after 2 failures in 5 minutes and tell the user).

## 11. Device matrix template

| Device | Android | Route | Level reached | Evidence | Rates tested | Notes |
|---|---|---|---|---|---|---|
| POCO M3 (`citrus`) | 16 (LineageOS 23.2) | 3.5 mm | | | 44.1, 48, 96 | |
| POCO M3 (`citrus`) | 16 | USB DAC | | | 44.1, 96, 192 | |
| second phone | 16 | USB DAC | | | | |

## 12. Legal and risk note

Modifying audio policy or device permissions can break audio or void warranties. The module README states "use at your own risk". No DRM bypass is ever implemented.
