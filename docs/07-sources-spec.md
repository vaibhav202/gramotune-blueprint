# 07 — Sources spec (local first, YouTube Music later)

Status: v0.1 (2026-10-31). The local source ships in v1.0. Everything YouTube-related is the Y-series: optional, isolated, and unverified until Y0.

## 1. Principles

1. **One library.** Online and local items live in the same lenses and rows. Downloaded files merge with their online entries instead of getting a separate view or menu item.
2. **No feed.** No home page of recommendations, no "mixes", no autoplay radio by default.
3. **Isolation.** A source plugin can fail, change or be removed without taking the player down. The core (`play` flavor) contains no YouTube code and no network permission.
4. **No remote code.** No downloading and executing extractor code at runtime. Fixes ship as app updates.
5. **Plain honesty.** Online features live in the `full` flavor; their legal situation is described in §9.

## 2. Interfaces (package `sources`)

```dart
abstract interface class SourceProvider {
  String get id;                                   // 'local', 'youtube'
  SourceCapabilities get capabilities;             // search, browse, resolve, download, auth
  Future<List<TrackRef>> search(SearchQuery q, {CancelToken? cancel});
  Future<BrowsePage> browse(BrowseRef ref, {String? continuation});
  Future<ResolvedMedia> resolve(TrackRef ref);     // stream location for the engine
  Stream<DownloadProgress> download(TrackRef ref, DownloadTarget target);
  Future<void> dispose();
}

final class TrackRef  { final String source, remoteId; final TrackTags tags; final Uri? thumbnail; }
final class ResolvedMedia {
  final Uri uri; final Map<String, String> headers;
  final DateTime? expiresAt; final String? mime; final int? bitrateKbps; final double? loudnessDb;
}
```

`ResolvedMedia` becomes a `PlayItem` in the app layer. Stream URLs expire; the player re-resolves on expiry or failure.

## 3. Local source

`LocalSource` wraps the library scanner behind the same interface (`resolve` returns the file URI). It exists so the app composes sources uniformly and so tests can swap in fakes.

## 4. Unified library rules

- A track row has `origin` local, remote or cached, plus `local_uri` and `remote_ref` (library spec §2 and §9).
- Remote rows exist only for items the user **adds to the library** (saved album, playlist, song). Search results are not inserted until the user acts.
- When a download finishes, the file is tagged with its remote id (custom tag) and linked to the existing remote row. It becomes `cached`. If the user later deletes the file, the row falls back to `remote`.
- A rescan that finds a file carrying a known remote id attaches it to that row instead of creating a duplicate.
- Rows look identical. Only a small glyph differs: cloud for remote-only, arrow for cached; nothing for local. Filters: "Downloaded only" and "Offline only".
- Search shows Library results first, then an **Online** section (YouTube) in the same screen. Tapping an online result plays it and offers Add to library and Download.

## 5. Remote playback path

- A loopback caching proxy (Dart `HttpServer` on `127.0.0.1`, random port) serves the decoder a plain URL, handles `Range` requests, fetches upstream with the required headers, and writes a progressive cache file. The cache state feeds the `cached` flag.
- The decoder (`AMediaExtractor`) opens `http://127.0.0.1:<port>/s/<token>` or the growing cache file. **[verify, Y3]** Android's cleartext policy for localhost: a `network_security_config.xml` allowing cleartext for `127.0.0.1` may be required; it is an XML resource, not Kotlin.
- On URL expiry the proxy transparently re-resolves and continues from the current byte offset.
- Containers: YouTube serves Opus in WebM and AAC in MP4. Android's extractor and codecs should handle both **[verify, Y3]**.

## 6. Downloads

- Target folder: user-selectable; default under the app's music folder. Files become visible to the system through a media scan; the library links them by tag and by path.
- No transcoding (no ffmpeg). Prefer AAC in M4A because the Dart tag libraries can write MP4 tags and cover art; Opus in WebM cannot be tagged by libraries we know of, so it would need a sidecar plus the database link. **[open question, Y4]**
- Tags written: title, artist, album, album artist, track, year, cover, and the custom remote-id tag. Writing uses the same `MetadataReader`-family package or a writer behind an interface.
- Queue with concurrency 2, retry with backoff, resumable, visible in a Downloads sheet under Settings (not a new tab).

## 7. YouTube plugin (`sources_youtube`, flavor `full`)

**Scope for Y1–Y5**: search (songs, albums, artists, playlists); browse album, artist and playlist pages; resolve audio stream; add to library; download. No account, no personalized content.

**Implementation candidates (all unverified; Y0 evaluates)**:
1. A pure-Dart InnerTube client for the YouTube Music web client (search and browse) combined with an existing Dart stream-resolution package such as `youtube_explode_dart`.
2. NewPipeExtractor (Java) used through jnigen-generated bindings. Adds a third-party Java dependency (needs an ADR; it is not code we write).
3. A self-hosted proxy service (Piped, Invidious). Network-dependent; not recommended.

**Y0 exit criteria**: pick one candidate, show search plus a 60 s playback plus a download on the POCO M3, document the maintenance risk, and record the license of every component.

**Breakage policy**: failures surface as "Online source unavailable" with a "Check for update" hint; local playback is unaffected. A provider health check runs only when the user opens Online search.

## 8. UX rules for online content

- Same row, same actions (Play next, Add to queue, Add to playlist, Add to library, Download).
- Album and artist pages merge local and online tracks, local ones first by availability.
- "Download album" and "Download playlist" are buttons on detail pages. There is no separate Downloads tab.
- No autoplay beyond the chosen context. When the context ends, playback stops (setting for "keep playing similar" is **not** planned).

## 9. Legal and distribution notes (not legal advice)

- YouTube's Terms of Service restrict accessing content by means other than the official apps, and restrict downloading. Open-source clients in this space exist and have faced takedown pressure in the past; the exposure is real and is the owner's to weigh.
- The `full` flavor is distributed outside Google Play. The repository does not contain Google API keys or proprietary code.
- DRM-protected content (for example Premium downloads) is never touched; no circumvention of technical protection measures.
- The README of `sources_youtube` states the above and that the plugin is for personal use.

## 10. Milestones (see MILESTONES.md)

Y0 evaluation spike → Y1 plugin skeleton and flavor → Y2 search and browse → Y3 stream resolve and playback via the proxy → Y4 downloads, tag writing and linking → Y5 unified library UX → Y6 optional sign-in (only if the owner asks).
