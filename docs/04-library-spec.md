# 04 — Library spec

Status: v0.1 (2026-10-31). Package: `music_library` (drift on SQLite). The package was planned as `library`, but that is a Dart reserved word, so the owner approved `music_library` on 2026-11-05. Scanner sources are provided by `platform_android` through interfaces defined here.

## 1. Goals

- Fast, incremental, deletion-aware indexing of 50k+ tracks.
- Old-school library semantics: lenses over one flat track table, playlists, a persistent queue, instant search.
- Identity that already supports local, remote and cached versions of the same track (Y-series), without schema redesign later.

## 2. Schema (drift tables; names are normative, column details may be refined in M2.1)

**tracks**
- Identity: `id` PK; `origin` (`local` | `remote` | `cached`); `local_uri` (unique, nullable); `local_path` (nullable); `media_store_id` (nullable); `remote_source` and `remote_id` (nullable, unique together); `root_id` (FK scan_roots).
- Tags: `title`, `title_sort`, `artist`, `artist_sort`, `album_artist`, `album_artist_sort`, `album`, `album_sort`, `composer`, `track_no`, `track_total`, `disc_no`, `disc_total`, `year`, `compilation`.
- Technical: `container`, `codec`, `sample_rate`, `bit_depth`, `channels`, `bitrate_kbps`, `is_lossless`, `duration_ms`, `size_bytes`, `mtime_ms`.
- ReplayGain: `rg_track_gain_db`, `rg_track_peak`, `rg_album_gain_db`, `rg_album_peak`.
- Artwork: `art_key` (hash of embedded art or path of folder art), `has_embedded_art`.
- Stats: `added_at`, `last_played_at`, `play_count`, `skip_count`, `rating` (0–5), `loved`.
- Segment (v1.1 CUE): `seg_start_ms`, `seg_end_ms` (null for whole files).
- State: `missing`, `unsupported`, `scan_generation`, `search_key`.

**albums**: `id`, `album_artist`, `album`, sort fields, `year`, `track_count`, `disc_count`, `duration_ms`, `art_key`, `added_at`, `is_compilation`, `album_key` (normalized album artist + album, with the directory as tie-break when album artist is missing).

**artists**: `id`, `name`, `name_sort`, `album_count`, `track_count`. v1.0 groups by album artist, falling back to artist. Multi-valued artist splitting (`track_artists`) is deferred to v1.1 and added by migration.

**genres** and **track_genres**: normalized genre names; ID3v1 numeric genres and `(17)` forms are mapped to names; multiple values split on `;`.

**playlists** (`id`, `name`, `kind` user|smart, `smart_key`, timestamps) and **playlist_items** (`playlist_id`, `track_id`, dense integer `position`, `added_at`).

**play_context** (single row: kind, ref, shuffle seed, index, position_ms, repeat, shuffle, stop_after_current) and **up_next_items** (`position`, `track_id`).

**history** (`track_id`, `played_at`, `played_ms`, `completed`).

**scan_roots** (`id`, `kind` mediastore|saf, `uri`, `enabled`, `last_scan_at`, `last_generation`).

User preferences live in `shared_preferences`, not in the database.

## 3. Scanner

Runs in its own isolate. Batches of ~200 rows per transaction; never holds a write lock longer than ~50 ms.

**Sources** (interface `MediaScanSource`, implemented in `platform_android`):
1. `MediaStoreSource` (primary): queries `MediaStore.Audio.Media` with columns for id, path, display name, title, artist, album, album artist, genre, track, disc, year, duration, size, date added, date modified, mime type, relative path, volume name, and generation values **[verify availability per API level]**. Excludes ringtones, alarms, notifications; podcasts and audiobooks excluded by default (setting). Minimum duration default 10 s (setting).
2. `SafSource` (fallback, SHOULD): recursive walk of a user-granted document tree for folders MediaStore does not index; files are opened by file descriptor.

**Stages**
1. *Fast index*: upsert rows from MediaStore columns so the library appears immediately.
2. *Enrich*: for new or changed files (mtime or size differs), read tags with the `MetadataReader` (codec, bit depth, ReplayGain, embedded-art flag, sort tags, multi-genre). Files are opened by direct path when readable, otherwise by file descriptor.
3. *Artwork*: extract embedded cover once per `art_key` to `art/orig/`, else find folder art (`cover`, `folder`, `front`, `album` with jpg/png; case-insensitive).
4. *Derive*: rebuild affected `albums`, `artists`, `genres`, section offsets.

**Incremental rules**
- Prefer the MediaStore generation values when present (API 30+ **[verify]**); otherwise compare `date_modified` and size.
- Tracks not seen in a scan are marked `missing` and hidden. They are purged after 30 days **unless their volume is unmounted** (SD cards): never purge when the volume is offline.
- Play counts and ratings survive a file reappearing at the same path.
- A manual "Rescan" and pull-to-refresh trigger a delta scan; "Rebuild library" clears derived data and rescans.

**Metadata reader** (`MetadataReader` interface). Candidates, all pure Dart: `audio_metadata_reader`, `metadata_audio`. M2.3 evaluates them on a real library (accuracy, speed, memory, odd tags), picks one, and keeps the other as a fallback behind the interface. The reader never loads whole files.

**Normalization** (pure Dart, unit-tested): trim; collapse whitespace; sort keys that lowercase, strip diacritics, optionally strip leading articles (setting), and compare digit runs numerically ("Track 2" before "Track 10"). Dart has no locale-aware collation, so non-Latin scripts sort by code point in v1.0 and get the `…` bucket in the alphabet index. Letters A–Z, `#` and `…` are the index sections.

## 4. Queries and paging

Lists use `LensQuery { Future<int> count(); Future<List<Row>> slice(int offset, int limit); Future<List<SectionOffset>> sections(); }`. The UI reads only the visible window plus a margin (pages of ~200), so a 50k-track lens never materializes fully in the UI isolate.

| Lens | Query shape |
|---|---|
| Songs | tracks ordered by `title_sort` (or chosen sort) |
| Artists | artists ordered by `name_sort`; detail lists that artist's albums, then songs |
| Albums | albums ordered by `album_sort` or album artist; detail lists tracks by disc and track number |
| Genres | genres; detail lists albums, then songs |
| Years | years descending; detail lists albums |
| Folders | path tree from `local_path`; directories derived by prefix queries with an index on `local_path` |
| Recently Added / Played / Most Played / Loved | smart queries over `added_at`, `history`, `play_count`, `loved` |

Indices (minimum): `title_sort`, `album_key`, `album_artist_sort`, `added_at`, `local_path`, `last_played_at`, `play_count`, `missing`. M2.1 verifies with `EXPLAIN QUERY PLAN` and a 50k-row synthetic library.

## 5. Search

- Preferred: SQLite FTS5 virtual table `track_fts(title, artist, album, genre)` using the `unicode61 remove_diacritics 2` tokenizer with prefix indexes, kept in sync by triggers. drift ships FTS5 bindings; **[verify]** that the bundled SQLite has FTS5 enabled.
- Fallback: `LIKE` on the normalized `search_key` column. Fast enough for tens of thousands of rows if FTS5 is missing.
- Query: split into tokens, each treated as a prefix (`tok*`), AND semantics; rank with bm25 using weights title 3, artist 2, album 2, genre 1.
- Results grouped Artists, Albums, Songs (top 5 each for scope "All"); debounce 80 ms; target <50 ms at 50k tracks.
- "Save results as playlist" creates a normal playlist from the current Songs result list.

## 6. Playlists

- Operations: create, rename, delete, add (single or multiple), remove, reorder (rewrite the affected position range in one transaction), duplicate.
- Built-in smart lists are computed views, not stored rows: Recently Added (last 30 days), Recently Played, Most Played (top 100), Loved.
- **M3U/M3U8 import**: resolve each entry by normalized path (absolute, or relative to the playlist file); report how many entries could not be matched; unmatched entries are skipped.
- **Export**: UTF-8 M3U8 with `#EXTM3U` and `#EXTINF` lines; relative paths when the playlist file shares a root with the tracks, otherwise absolute.
- Autoplaylists with a rule editor are v1.1.

## 7. Queue and context persistence

`play_context` and `up_next_items` are written on every structural change (debounced 500 ms) and on position checkpoints every 10 s during playback. On launch the controller restores them and loads a window into the engine **paused**, never auto-playing.

## 8. Play statistics

A track counts as played at 50% of its duration or 240 s, whichever comes first (the usual scrobbling rule). On count: `play_count += 1`, `last_played_at` updated, a `history` row inserted. A skip before 30 s increments `skip_count`. Nothing leaves the device.

## 9. Remote and cached identity (forward compatibility, Y-series)

- A logical track can have a local file, a remote reference, or both. The row's `origin` is `local`, `remote` or `cached`; `availability` (local, remote, both) is derived.
- A downloaded file embeds its remote id in a custom tag. The scanner attaches a file carrying that tag to the existing remote row instead of creating a new track. This is what makes downloaded and online items show up together in every lens (D-023).
- Lenses never branch on origin. A "downloaded" badge and an "offline only" filter are the only differences users see.

## 10. Migrations and tests

- drift schema versioning with generated schema snapshots; every migration has an upgrade test from each previous version.
- `tool/gen_library.dart` generates a synthetic 50k-track library for benchmarks.
- Unit tests: sort-key generation, genre mapping, album grouping, M3U parsing, play-count rule, stale-file purge with unmounted volumes.
- Benchmarks (reported in the CHANGELOG): lens first-page latency, search latency, initial scan, unchanged rescan.

## 11. Privacy

The database lives in app-private storage. "Clear library data" deletes it and the artwork cache. There is no export of play history unless the user explicitly adds it later.
