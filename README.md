# Gramotune — project blueprint

An offline-first Android music player for people who own their music files. It has a classic library-style interface — lenses, a real playback queue and instant search — a look inspired by classic audio hardware, and an audio engine written entirely in Flutter and Dart. Later tracks add direct hardware output (USB bit-perfect, then root for the internal jack) and an optional YouTube Music source that shares one library with your downloads.

**Status:** blueprint v0.1, written 2026-10-31. M0.1 (toolchain), M0.2 (workspace, packages, tool scripts) and M0.3 (Android baseline, merged-manifest guard) are complete. The next task is **M0.4** (CI; needs the repository) in `MILESTONES.md`.

## Read in this order

| File | What it is |
|---|---|
| `AGENTS.md` | The rules every coding agent follows (canonical; `CLAUDE.md` and `GEMINI.md` point to it) |
| `MILESTONES.md` | The build plan with checkboxes, time-boxes and acceptance criteria. **Live.** |
| `CHANGELOG.md` | Engineering log, one entry per agent session. **Live.** |
| `DECISIONS.md` | ADRs D-001…D-025 with status. **Live.** |
| `ARCHITECTURE.md` | Packages, isolates, data flow, dependencies |
| `docs/01-product-spec.md` | Requirements P-01…P-23, quality targets Q-1…Q-8, non-goals |
| `docs/02-ux-spec.md` | Information architecture, the interaction model and screens U-01…U-20 |
| `docs/03-engine-spec.md` | Dart audio engine: API, pump loop, decoding, gapless, DSP, errors |
| `docs/04-library-spec.md` | Database, scanner, queries, search, playlists |
| `docs/05-android-platform-spec.md` | Permissions, service, focus, intents, lifecycle |
| `docs/06-direct-output-spec.md` | Direct output levels, evidence ladder, USB, Magisk, ALSA (research-grade) |
| `docs/07-sources-spec.md` | Source plugins, unified library, YouTube plugin plan |
| `docs/08-testing-spec.md` | Test layers, fixtures, golden tests, soak, human checks |
| `docs/09-design-handoff.md` | Figma to Flutter: skin contract, shaders, assets |
| `docs/10-risks.md` | Risk register and pivot triggers |
| `docs/research-notes.md` | What was studied, with sources, and the lookalike-repository warning |
| `ASSETS.md` | Asset and font log (original work only) |
| `docs/human-checks/TEMPLATE.md` | Template for things only the owner can judge |

## The plan on one screen

| Phase | Goal | Rough size |
|---|---|---|
| M0 | Repository, tooling, CI, synthetic fixtures | 4–6 sessions |
| S1–S7 | Time-boxed spikes that prove or kill the risky ideas (Dart pump, decoders, gapless, service lifecycle, storage, skin cost, device probe) | ≤16 sessions |
| G0 | Owner reviews the spike results and decides the name and license | gate |
| M1 | Playback core: engine, gapless, DSP, background service | 12–16 |
| M2 | Library: scanner, tags, lenses, search, playlists | 12–16 |
| M3 | App and skins: every screen, Plain and Classic | 20–28 |
| M4 | Polish: accessibility, performance, reliability, release | 10–14 |
| G1 | **v1.0** for an average user | gate |
| D1–D5 | Direct output (the D0 probe is spike S7): exclusive, USB bit-perfect, Magisk, raw ALSA research | after v1.0 |
| Y0–Y6 | YouTube Music source with a unified library | after v1.0 |

A "session" is one focused agent run; calendar time depends mostly on how fast the owner can review human checks (R17). The spikes are the part most likely to change the estimate.

## Starting an agent

First session (any agent that reads `AGENTS.md`):

```
Read README.md, AGENTS.md, MILESTONES.md, DECISIONS.md and the three newest entries of CHANGELOG.md.
Go with the blueprint defaults, except: <your exceptions, or "none">.
Do the first unchecked item in MILESTONES.md and nothing else.
Finish with the Definition of Done in AGENTS.md §12, and tell me what I need to check.
```

Next sessions: `Continue with the next unchecked item.` After you test something by hand: `Here is the result of docs/human-checks/<file>: <your notes>. Record it, then continue.`

## What the owner decides

- **D-016** license. It blocks the release step (M4.6). D-001 (name and application id) is decided: Gramotune, `app.gramotune`.
- Whether the agent can reach the POCO M3 over `adb` (otherwise on-device steps become paste-back commands).
- The inputs listed at the end of `MILESTONES.md` (Figma exports, a sample library, a borrowed phone on another ROM, root approval).
- Approvals the rules require: native dependencies, copyleft licenses, new permissions, new features, anything in `android-module/` or the YouTube track.

## Ground rules in four lines

Flutter and Dart only, engine included (D-002, D-003). All code and artwork are original; no third-party player's code is copied, and its marks stay out of the name, package id and user-visible strings (D-024). Nothing audible or visual counts as done until evidence or a recorded human check says so (D-025).
