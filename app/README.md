# app

The composition root. Owns `main()`, routing, state providers, the
`audio_service` adapter and the Android flavors.

## Boundaries

- May import everything above (AGENTS.md §5). Nothing imports `app`.
- No FFI here: engine access goes through `engine_api` only.
- Flavors: `play` (local only, no `INTERNET`) and `full` (adds the YouTube
  source; never on Google Play, D-013).

## Status

M0.2: workspace skeleton with a placeholder screen and both flavors. Screens,
routing, state and the media session arrive in M3 and M1.
