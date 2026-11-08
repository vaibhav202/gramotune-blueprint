# 10 — Risk register

Status: v0.1 (2026-10-31). L = likelihood, I = impact (H/M/L). "Signal" is what tells us early. Review at every gate (G0, G1).

| ID | Risk | L | I | Mitigation | Early signal / owner item |
|---|---|---|---|---|---|
| R1 | Dart pump glitches (GC pauses, scheduling) cause xruns | M | H | Deep output buffer; short pump iterations; fixed chunk buffers; S1 soak under UI jank. Fallback: C ring buffer and pump thread built with Dart build hooks, behind the same `OutputBackend` (needs ADR) | xruns > 0 in S1 |
| R2 | Platform decoders miss formats or truncate 24-bit FLAC | M | H | S2 matrix; PCM-float request; fallback bundled C decoder via hooks (D-004, needs owner approval) | S2 hash mismatch on 24-bit fixture |
| R3 | Gapless boundaries inaccurate for MP3/AAC | M | M | Per-format trim sources; fixtures; S3 measurements; document limits | S3 boundary error > 1 frame |
| R4 | `audio_service` lifecycle with single isolate fails on Activity destroy or OEM kills | M | H | S4 scenarios; thin adapter; fallback to a fork or a minimal Kotlin shim via ADR | S4 scenario 1–3 fails |
| R5 | Storage variance: MediaStore quirks, folder art permission, Android 16 behavior | M | M | S5; SAF fallback; optional image permission | S5 loadThumbnail result |
| R6 | Skeuomorphic UI too heavy for Adreno 610-class GPU | M | M | Bake textures; limit live shaders; Plain skin; S6 budgets | S6 janky frames > 1% |
| R7 | Agents cannot hear or see the device, so audio and visual defects slip through | H | H | PCM goldens, gapless suite, soak counters; human-check files; 🟡 status rule | Owner finds defects not caught by tests |
| R8 | Scope creep: root research or YouTube delays a polished v1.0 | H | M | G1 excludes D and Y series; MILESTONES order is strict; "add feature" needs owner approval | Items outside MILESTONES appear in PRs |
| R9 | Direct output infeasible on the internal jack | M | M | D0/D1 evidence first; kill criteria; ship USB and exclusive if they work; honest UI | D1 shows no MMAP exclusive on `citrus` |
| R10 | Root tooling damages audio setup or causes boot trouble | L | H | Systemless module, patch at install, device allowlist, rescue notes, "Reset audio" | Any boot or audio failure during D3 |
| R11 | Trademark or trade-dress exposure from an iOS-6 look | L | M | Original assets, naming policy, `ASSETS.md`, no Apple marks; optional legal check before store release | Reviewer sees traced or copied art |
| R12 | YouTube ToS, legal pressure or frequent breakage | H | M | Isolated plugin, `full` flavor outside Play, no DRM, clear failure messages, no remote code | Y0 shows heavy maintenance |
| R13 | Dependency churn (Flutter 3.50 due Nov 2026, `audio_service` forks, young metadata packages) | M | M | Pin versions; wrap risky packages behind interfaces; upgrade only at gates | Analyzer or build breaks after a bump |
| R14 | Library correctness: odd tags, compilations, non-Latin sorting | H | M | Weird-files corpus; configurable album-artist grouping; honest index bucket for non-Latin; owner feedback on a real library | M2.3 evaluation findings |
| R15 | OEM battery killers on non-Lineage ROMs | M | H | Non-Lineage device test before v1.0; battery help page; S4 | Playback stops on a vendor ROM |
| R16 | GPL contamination from copying Fooyin code | L | H | AGENTS rule: UX ideas only; review for copied code; license policy D-016 | Code resembling Fooyin sources appears |
| R17 | Owner review bandwidth is the bottleneck for human checks | M | M | Batch human checks per milestone; keep items small; keep checklists short | Many items stuck at 🟡 |

## Pivot triggers

- **S1 fails** (xruns under jank): move the pump into a small C library built through Dart build hooks; the Dart engine still drives it. Requires owner approval (D-004).
- **S2 shows 24-bit loss on the platform FLAC decoder**: bundle a C FLAC decoder via hooks for FLAC only.
- **S4 fails**: evaluate the plugin fork; as a last resort, a minimal Kotlin shim limited to service plumbing, via ADR.
- **S6 fails**: ship Classic with baked textures only; keep shaders for Now Playing or drop them.
- **D1 and D4 fail on `citrus`**: ship USB bit-perfect and exclusive-where-granted; document the internal-jack limit in the device notes.
