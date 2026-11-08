# ui_kit

The skeuomorphic widget kit. Presentational only: widgets take data and
callbacks, never an engine or a database (AGENTS.md §5, §8).

## Boundaries

- May import Flutter and `skin`.
- Never `engine`, `engine_api`, `music_library`, `sources`, `platform_android` or the
  app (AGENTS.md §5).

## Public API

- `PlaceholderView` — centered title and subtitle for unfinished screens (M0.2).
- Nav bar, tab bar, segmented control, scrubber, knob and the rest — M3.2.

## Status

Skeleton created in M0.2. Every widget gets a golden test in M3.2.
