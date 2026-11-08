# DECISIONS.md — architecture decision log (ADRs)

One entry per decision. Agents: never contradict an `accepted` ADR (AGENTS.md §2). A `proposed` ADR needs the owner's sign-off before you build on it, except inside a spike, whose job is to test it. An `open` ADR has a placeholder in use and a named moment when it must be decided.

Statuses: `accepted` · `proposed` · `open` · `superseded by D-nnn`.
Blueprint approval: the owner's first instruction to an agent should say "go with the blueprint defaults" or list exceptions; the agent records that in the CHANGELOG. Until then, treat everything except the owner's explicit choices (D-002, D-003, D-015, D-023) as `proposed`.

## Index

| ID | Decision | Status | Decide by |
|---|---|---|---|
| D-001 | Name and application id | accepted | |
| D-002 | The audio engine is written in Dart | accepted | |
| D-003 | One stack: Flutter and Dart only | accepted | |
| D-004 | Native fallback through Dart build hooks (only if a spike forces it) | proposed | S1, S2 results; G0 |
| D-005 | No native-to-Dart callbacks; pumped blocking writes | accepted | |
| D-006 | One stream format at a time; reopen on change | accepted | |
| D-007 | No software volume by default | accepted | |
| D-008 | `audio_service` as a thin adapter in the UI isolate | proposed | S4; G0 |
| D-009 | Storage strategy: MediaStore, paths, fds, SAF fallback | proposed | S5; G0 |
| D-010 | Database: drift on SQLite in a shared DB isolate | accepted | |
| D-011 | Metadata reader behind an interface | open | M2.3 |
| D-012 | Android APIs through JNI bindings, no hand-written Kotlin | accepted | S5 verifies the toolchain |
| D-013 | Flavors `play` and `full` | accepted | |
| D-014 | Dart workspace with enforced package boundaries | accepted | |
| D-015 | Android first, `minSdk` 26, desktop later | accepted | |
| D-016 | Source license | open | G0; blocks M4.6 |
| D-017 | Riverpod and go_router | accepted | |
| D-018 | Skin system: tokens, baked textures, few shaders | accepted | S6 sets the budget |
| D-019 | Library UX model: lenses, Up Next, search, no feed | accepted | |
| D-020 | Direct output is a backend behind `OutputBackend` | accepted | |
| D-021 | "Bit-perfect" only with evidence | accepted | |
| D-022 | Windowed queue protocol | accepted | |
| D-023 | Unified library identity: local, remote, cached | accepted | |
| D-024 | Reference projects are UX references only | accepted | |
| D-025 | Evidence-first testing and human checks | accepted | |

## Template

```
### D-0nn — Title
Status: accepted | proposed | open · Date: YYYY-MM-DD · Decided by: owner | blueprint | agent + owner
Context: why this came up.
Decision: what we do.
Consequences / revisit when: what it costs, and what would change our mind.
```

---

### D-001 — Name and application id
Status: accepted · 2026-11-08 · owner decision
Context: the working codename was `tonearm` with the placeholder id `org.example.tonearm` (05 §1). Decided after the M0.2/M0.3 sessions.
Decision: the product name is **Gramotune**; the Android application id and namespace are `app.gramotune`. Constraint checks run on 2026-11-08 before the owner committed: the GitHub API returned 0 repositories for `gramotune`, pub.dev has no `gramotune` package (404), and web, F-Droid and trademark searches returned no entries. No Apple, iOS or iPod marks appear in the name, id or store text (05 §1). Store listing text at M4.6 must satisfy the same constraints; the id is permanent once published.

### D-002 — The audio engine is written in Dart
Status: accepted · 2026-10-31 · owner decision
Decision: decoding, DSP, timeline and output live in the Dart `engine` package. It calls AAudio and the NDK media APIs through `dart:ffi`.
Why: the owner wants no partial solutions, and a Dart engine stays portable for desktop backends.
Consequences: real-time behavior is the main technical risk (R1) and is measured in S1. Native fallbacks go through D-004 only. Rejected: Media3 or ExoPlayer and any other Kotlin player library, because they break the all-Dart goal and play through `AudioTrack`.

### D-003 — One stack: Flutter and Dart only
Status: accepted · 2026-10-31 · owner decision
Decision: the whole app is Flutter and Dart. The alternative the owner weighed, Kotlin with Compose Multiplatform, is not pursued. Hybrids (a Kotlin engine under a Flutter UI) are out.
Revisit: only if D-004 grows into a majority of native code, which would be a new ADR and an owner conversation.

### D-004 — Native fallback through Dart build hooks
Status: proposed · 2026-10-31 · blueprint
Context: the spikes may show the Dart pump glitches under load (S1) or that the platform FLAC decoder loses 24-bit depth (S2).
Decision: only if a spike records that evidence, add a small C component built with Dart build hooks (`hooks`, `code_assets`, `native_toolchain_c`) behind the existing `OutputBackend` or `Decoder` interface: a C pump and ring buffer, or a bundled FLAC decoder (candidate: dr_flac; verify its license). The Dart engine stays the driver.
Consequences: native code in the repository, a license review (D-016), owner approval each time. Nothing native is added without recorded evidence.

### D-005 — No native-to-Dart callbacks
Status: accepted · 2026-10-31 · blueprint
Context: `NativeCallable.listener` is asynchronous and cannot return values; `isolateLocal` callbacks must run on the thread that created them, which AAudio's callback thread is not.
Decision: one engine isolate pumps `AAudioStream_write` (blocking, with a timeout) and yields to the event loop between chunks. Blocking native calls are never `isLeaf: true`.
Consequences: deeper output buffers than a callback design; S1 validates the margins.

### D-006 — One stream format at a time
Status: accepted · 2026-10-31 · blueprint
Decision: an output stream has one fixed rate, channel count and encoding. A format change drains, closes and reopens it. Gapless is guaranteed only across identical formats; Signal Path explains a gap when formats differ.
Rejected: always resampling to a fixed rate (it breaks bit-transparency). An optional fixed-rate resampler is a v1.1 candidate.

### D-007 — No software volume by default
Status: accepted · 2026-10-31 · blueprint
Decision: the in-app volume slider mirrors Android's system volume. The only automatic gain is the −12 dB duck for transient focus loss (05 §6). ReplayGain and EQ apply only when the user enables them.
Consequences: the default chain stays bit-transparent, and bit-perfect modes (D-series) behave predictably.

### D-008 — `audio_service` as a thin adapter
Status: proposed · 2026-10-31 · blueprint
Decision: `audio_service` 0.18 runs its handler in the UI isolate. Our `AudioHandler` only forwards media-session commands to `PlaybackController` and mirrors state back. S4 proves the five lifecycle scenarios in 05 §5.
Fallbacks if S4 fails: a plugin fork, then a minimal Kotlin shim limited to service plumbing, each through its own ADR.

### D-009 — Storage strategy
Status: proposed · 2026-10-31 · blueprint
Decision: MediaStore is the primary index; read files by path with `READ_MEDIA_AUDIO` where S5 shows it works; use file descriptors for `content://` URIs; use SAF folders as the fallback. Folder artwork follows the S5 result.

### D-010 — Database
Status: accepted · 2026-10-31 · blueprint
Decision: drift on SQLite, queried through a shared DB isolate (`drift_flutter` `shareAcrossIsolates`). FTS5 for search if the bundled SQLite has it (checked in M2.1), otherwise indexed `LIKE` queries.

### D-011 — Metadata reader
Status: open · 2026-10-31 · agent + owner
Decision: a `MetadataReader` interface with a pure-Dart implementation. M2.3 compares `audio_metadata_reader` and `metadata_audio` on the owner's real library, picks one and keeps the other as a fallback.

### D-012 — Android APIs through JNI bindings
Status: accepted · 2026-10-31 · owner's all-Dart rule
Decision: Android APIs are called through `package:jni` with `jnigen`-generated bindings in `platform_android`. No hand-written Kotlin or Java, except the manifest, Gradle files and what the `audio_service` plugin requires. Any other exception needs its own ADR and the owner's approval.
Revisit: S5 verifies that the jnigen toolchain works on the pinned versions.

### D-013 — Flavors
Status: accepted · 2026-10-31 · blueprint
Decision: `play` is local-only, has no `INTERNET` permission and no YouTube code. `full` adds the YouTube plugin and is distributed outside Google Play. Root tooling is a separate artifact and never ships in the APK.

### D-014 — Workspace and boundaries
Status: accepted · 2026-10-31 · blueprint
Decision: a Dart workspace with the packages in ARCHITECTURE §3 and the import matrix in AGENTS §5, enforced by `tool/check_boundaries.dart` in `tool/check.sh` and CI.
Amendment (2026-11-05, owner-approved): the database and scanner package is `music_library` in `packages/music_library/`, not `library`. Dart reserves the word `library`, so pub refuses it as a package name. The directory and the package share the new name.

### D-015 — Platform scope
Status: accepted · 2026-10-31 · owner decision
Decision: Android first (the owner's DAP is a POCO M3 on LineageOS). `minSdk` 26 because AAudio starts there. `targetSdk` follows the current Play requirement, checked in M0.3. Linux and Windows come later through backends behind the same interfaces (X-series).
Amendment (2026-11-08, M0.2): the app compiles against **`compileSdk` 37** while `targetSdk` stays 36. `permission_handler_android` 14.1.1 (pulled by `permission_handler` 13.0.2) refuses to build against API 36. AGP 9.1.0 prints a "maximum recommended compile SDK" warning and the builds succeed. Revisit when `permission_handler` supports API 36 again, or when `targetSdk` moves to 37.

### D-016 — Source license
Status: open · 2026-10-31 · owner
Options: **Apache-2.0** (permissive; forks may be closed) or **GPL-3.0-or-later** (forks must stay open). The blueprint recommends GPL-3.0-or-later if any GPL or LGPL native component might ever be bundled (for example through D-004), and Apache-2.0 otherwise. No Fooyin or Audacious code is used either way (D-024). All dependencies must be compatible with the choice, and F-Droid needs buildable-from-source dependencies.
Revisit: decide at G0. M4.6 is blocked until it is decided. Until then, do not publish the repository.

### D-017 — State and routing
Status: accepted · 2026-10-31 · blueprint
Decision: `flutter_riverpod` for state and dependency injection, `go_router` for navigation. Screens get fake providers in tests.

### D-018 — Skin system
Status: accepted · 2026-10-31 · blueprint
Decision: a JSON token contract (09 §4), baked textures and nine-slice images first, shaders only inside the S6 budget. v1.0 ships Classic and Plain; user-loadable skins are v1.1.

### D-019 — Library UX model
Status: accepted · 2026-10-31 · owner's brief
Decision: the tab bar holds lenses (Fooyin Library Tree-style groupings, editable under More › Edit); an Audacious-style Up Next queue; a global search that can play, queue or save results; stop-after-current. No feed, no recommendations, no autoplay radio (01 §2).

### D-020 — Direct output as a backend
Status: accepted · 2026-10-31 · blueprint
Decision: every output path (shared, exclusive, USB bit-perfect, root direct) implements `OutputBackend` and is chosen in Settings › Output with automatic fallback to Standard. The UI and engine core never change for a new backend.

### D-021 — Honest "bit-perfect"
Status: accepted · 2026-10-31 · blueprint
Decision: the app uses the words "bit-perfect" or "direct" only with evidence at level E1 or higher (06 §3), and Signal Path shows the level next to the claim.

### D-022 — Windowed queue protocol
Status: accepted · 2026-10-31 · blueprint
Decision: `PlaybackController` owns the full queue, shuffle order and Up Next. The engine plays a window of about 500 `PlayItem`s and emits `NeedMoreItems` when 50 or fewer remain. Repeat-one and stop-after-current are native to the engine because they must be gapless-safe.

### D-023 — Unified library identity
Status: accepted · 2026-10-31 · owner decision
Decision: every track has `origin` (local, remote or cached), `local_uri` and `remote_ref` from the first schema. Downloaded online items attach to their remote row and appear in the same lenses. There is no separate Downloads view or menu item.

### D-024 — Reference projects are UX references only
Status: accepted · 2026-10-31 · blueprint
Decision: Fooyin (GPL-3.0) and Audacious (BSD-2-Clause core, plugins under mixed licenses) inform the UX. Agents read their documentation and write the behavior in their own words; they do not copy or translate source code. The official Audacious repository is `audacious-media-player/audacious`; the URL the owner pasted (`audacious-music-player/audacious-software`) is a lookalike and must not be cloned, built or depended on (docs/research-notes.md).

### D-025 — Evidence-first testing
Status: accepted · 2026-10-31 · blueprint
Decision: agents cannot hear audio or see a device screen, so every audio and timing claim needs machine evidence (hashes, counters, timeline summaries). Anything else gets a human-check file and the 🟡 status until the owner records a result (08 §12).
