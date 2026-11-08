# music_library

The database and everything that fills it: drift schema, scanner, queries,
lenses, playlists and the artwork cache.

The blueprint called this package `library`, but that is a Dart reserved word
and pub rejects it. The owner approved `music_library` on 2026-11-05
(D-014 amendment).

## Boundaries

- May import `drift`, `sqlite3`, `path` and Dart libraries.
- Never Flutter widgets, `engine`, `engine_api`, `sources` or the app
  (AGENTS.md §5). Enforced by `tool/check_boundaries.dart`.

## Public API

Added in M2 (docs/04-library-spec.md): `GramotuneDatabase` and its tables, the
scanner, lens queries, search, playlist commands and the artwork cache.

## Status

Skeleton created in M0.2. Schema and scanner land in M2.1–M2.2.
