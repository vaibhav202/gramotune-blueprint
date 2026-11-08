# 01 — Product spec

Status: v0.1 (2026-10-31). Requirement IDs (`P-nn`) are referenced from MILESTONES.md.

## 1. Vision

A classic-feeling music player for people who own their music. It looks like an iOS-6-era player, organises music like Audacious and Fooyin (library lenses, playlists, a real queue, instant search), and treats audio honestly (shows the signal path, never claims "bit-perfect" without evidence). Offline and private by default. Open source.

## 2. Principles

1. **Library, not feed.** No recommendations, no autoplay radio, no "for you" rows. Ever.
2. **Lists are the UI.** Every list uses the same row and the same actions, so the app is learnable in minutes.
3. **Honest audio.** The Signal Path screen reports what the engine actually does.
4. **Offline and private.** The core build has no network permission and no analytics.
5. **Looks like a classic, works like a tool.** Skeuomorphism is a skin; the structure must remain fully usable with the Plain skin.
6. **Two taps to music.** From launch, resuming or starting playback takes at most two taps.

## 3. Users

| Persona | Needs | Priority |
|---|---|---|
| **Everyday listener** | Pick a song, it plays; headset buttons work; no setup | v1.0 must work |
| **Audiophile / DAP user** | FLAC and hi-res, gapless, ReplayGain, EQ, signal path, later bit-perfect | v1.0 playback quality; direct output after |
| **Library keeper** | Folder and tag structure respected, playlists, queue, fast search | v1.0 core |

The owner is both an audiophile and a library keeper, and uses a phone as a DAP with wired IEMs.

## 4. v1.0 scope — MUST

| ID | Requirement | Notes |
|---|---|---|
| P-01 | Local playback of MP3, AAC/M4A, FLAC, Ogg Vorbis, Opus, WAV | Final list is whatever S2 proves on target devices |
| P-02 | Gapless playback between tracks of the same format | Sample-accurate where container metadata allows (S3) |
| P-03 | Background playback: foreground service, notification, lock screen, headset and Bluetooth buttons, audio focus, pause on unplug | |
| P-04 | Library scan from MediaStore; incremental rescans; stale-file cleanup; folder fallback | Fooyin-style rescan behavior |
| P-05 | Lenses: Playlists, Artists, Songs, Albums (tab bar) plus Genres, Years, Folders, Recently Added in More; alphabet index; artist and album detail | Details in 02 |
| P-06 | Playlists: create, rename, delete, add, remove, reorder; M3U/M3U8 import and export; built-ins Recently Played, Most Played, Loved | |
| P-07 | Up Next queue: play next, add to queue, reorder, clear; persisted | Audacious-style queue |
| P-08 | Instant search over artist, album, title, genre with scope control and actionable results | Audacious Search Tool idea |
| P-09 | Now Playing: artwork, accurate scrubber, transport, shuffle, repeat all/one, stop after current, flip to track list with star rating | |
| P-10 | 10-band equalizer with preamp and presets; ReplayGain (track/album, preamp, clipping protection) | Float DSP in the engine |
| P-11 | Track Info sheet and Signal Path screen | Format, rate, depth, bitrate, path, decoder, backend |
| P-12 | Sleep timer (minutes, end of track) | |
| P-13 | Restore queue and position after process restart | |
| P-14 | Skins: Classic (iOS-6 style) and Plain (flat, high contrast) | Original artwork only |
| P-15 | Settings: library folders, playback, appearance, about and licenses, diagnostics | |
| P-16 | Onboarding, permission flow, empty and error states | First playback in ≤60 s |
| P-17 | Accessibility baseline: TalkBack, 200% font scale, AA contrast in Plain skin | |
| P-18 | `play` flavor declares no `INTERNET` permission and has no analytics | |
| P-19 | "Open with" from file managers and other apps (`audio/*` intents) | `content://` handled via file descriptor |

## 5. v1.0 scope — SHOULD (drop to v1.1 if it threatens quality)

- P-20 Row format presets: Classic, Detailed, Compact.
- P-21 Format badges on rows (for example "FLAC 24/96").
- P-22 Landscape layouts that are usable but not redesigned.
- P-23 Per-lens sort options remembered.

## 6. v1.1 candidates (not in v1.0)

Autoplaylists with a rule editor (Fooyin), CUE sheets, lyrics (.lrc and embedded), tablet and foldable two-pane layout, user-loadable skins, Cover Flow-style landscape browse, crossfade, custom row-format strings, A–B repeat, ReplayGain scanner, optional fixed-rate resampler, ListenBrainz scrobbling, tag editing, Android Auto.

## 7. Later tracks (separate plans)

- **D-series**: direct output (USB bit-perfect, AAudio exclusive/MMAP probe, Magisk module, root ALSA). See `docs/06-direct-output-spec.md`.
- **Y-series**: YouTube Music source with unified library (downloaded and online tracks in the same lists). See `docs/07-sources-spec.md`.
- **X-series**: Linux and Windows backends (roadmap only).

## 8. Non-goals

Streaming services in v1.0, social or feed features, podcasts and audiobooks, video, cloud sync, iOS and web targets, DRM content, an in-app store.

## 9. Quality bar for "polished, ready for an average user"

These numbers are **provisional targets**; M1 and M2 record baselines, then the owner confirms or adjusts them.

| ID | Criterion | How measured |
|---|---|---|
| Q-1 | 0 crashes and ANRs during a 7-day dogfood on two devices | owner log + local crash log |
| Q-2 | 30-minute screen-off soak: 0 xruns, memory within ±5%, no audible glitches | engine counters + human check |
| Q-3 | First interactive frame ≤1.5 s on POCO M3-class hardware; ≤1% janky frames scrolling a 20k-track list | `flutter drive --profile` timeline summary |
| Q-4 | Initial scan of 20k tracks ≤3 min; unchanged rescan ≤5 s | scanner benchmark |
| Q-5 | Screen-off battery drain ≤1.5× a reference player on the same device | `dumpsys batterystats`, one-hour runs |
| Q-6 | First run to first playback ≤60 s including permissions | human check with a fresh install |
| Q-7 | Every flow works with TalkBack; no clipping at 200% font scale | human check |
| Q-8 | Gapless pairs pass for FLAC, MP3, AAC and Opus fixtures | automated gapless suite |

## 10. Distribution and licensing

- Core (`play` flavor): GitHub releases and F-Droid-compatible; Play Store possible because it is local-only.
- `full` flavor (YouTube plugin): distributed outside Play.
- Source license: open decision D-016. The blueprint recommends GPL-3.0-or-later if any GPL/LGPL native components may be bundled, otherwise Apache-2.0.
- Name: open decision D-001. Do not use Apple marks (Apple, iOS, iPod) in the name, package id or store listing.
