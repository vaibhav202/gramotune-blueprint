# sources

Source providers. The local provider ships in v1.0; the YouTube Music provider
is a separate package in the Y-series and only the `full` flavor imports it.

## Boundaries

- May import `music_library`, `engine_api` and Dart libraries.
- Never Flutter widgets, `engine` or the app (AGENTS.md §5).
- Only the local provider is part of the `play` flavor (D-013).

## Public API

Added in M2 (docs/07-sources-spec.md): `SourceProvider`, `LocalSourceProvider`
and the download/import hooks used by the Y-series.

## Status

Skeleton created in M0.2.
