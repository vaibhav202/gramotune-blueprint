# 02 — UX spec

Status: v0.1 (2026-10-31). Screen IDs (`U-nn`) are referenced from MILESTONES.md.

## 1. What we borrow, and how it adapts to a phone

Sources studied: Fooyin (customisable Qt desktop player, GPL-3.0) and Audacious (BSD-2 core; GTK/Qt/Winamp-skin UIs). UX ideas only; no code is reused (AGENTS.md §10, D-024). The structure below follows D-019.

| Source concept | Where it comes from | Mobile adaptation | ID |
|---|---|---|---|
| Library tree with configurable groupings | Fooyin Library Tree | **Lenses**: Artists, Albums, Songs, Genres, Years, Folders; the user chooses which lenses sit in the tab bar | P-05 |
| Directory browser | Fooyin Directory Browser, Audacious file browser plugin | **Folders** lens: browse by path, "Play folder" | P-05 |
| Filters on any field | Fooyin Filters | Per-lens sort and a scope control in search; filter chips for format and downloaded state (v1.1) | P-08 |
| Search that makes a playlist | Audacious Search Tool | Instant global search; results can be played, queued, or **saved as a playlist** | P-08 |
| Jump to song, then Play/Queue | Audacious (Ctrl+J, Alt+Q) | Search results long-press: Play, Play next, Add to queue | P-08 |
| Separate play queue | Audacious Queue Manager, Fooyin queue | **Up Next** list that plays before the rest of the context | P-07 |
| "Stop after current" | Audacious Ctrl+M | Toggle in Now Playing menu and notification action (later) | P-09 |
| Playlist tabs and manager | Audacious, Fooyin Playlist Organiser | **Playlists** lens with a list of playlists; "Now Playing" is just the active context | P-06 |
| Autoplaylists | Fooyin | Built-in smart lists in v1.0 (Recently Played, Most Played, Loved); rule editor in v1.1 | P-06 |
| Configurable columns / row formats | Fooyin FooScript, Audacious tuple formats | Three row-format presets in v1.0; editable format string in v1.1 | P-20 |
| Song Info / Selection Info | Audacious Ctrl+I, Fooyin | **Track Info** sheet and **Signal Path** screen | P-11 |
| Ratings, play counts, loved | Fooyin | Stars in the flipped Now Playing, play counts, a Loved list | P-09 |
| Layout presets | Fooyin | Skins and (v1.1) tablet two-pane presets | P-14 |
| Skins | Audacious Winamp-skin interface | Skin system with Classic and Plain skins | P-14 |

## 2. Information architecture

```
Tab bar:  Playlists | Artists | Songs | Albums | More
More:     Genres · Years · Folders · Recently Added · Recently Played · Most Played · Loved
          Settings · Equalizer · Sleep timer · Diagnostics
          [Edit] lets the user drag lenses into the tab bar (4 slots + More)
Global:   mini-player above the tab bar (tap = Now Playing, swipe up = Now Playing)
Search:   pull-down search field at the top of every list, always global, with scope [All | Artists | Albums | Songs]
```

The tab bar mirrors the classic iPod-style layout and doubles as the lens switcher. The mini-player is a deliberate modern deviation from iOS 6.

## 3. Screen inventory

| ID | Screen | Notes |
|---|---|---|
| U-01 | Welcome and permission explainer | One screen; explains why audio access is needed; no dark patterns |
| U-02 | Library setup | Scan progress, choose extra folders |
| U-03 | Lens list (Artists, Songs, Albums, Genres, Years, Folders) | Alphabet index; list or grid toggle for Albums |
| U-04 | Artist detail | Albums, then top songs; Play / Shuffle header |
| U-05 | Album detail | Disc headers; Play / Shuffle; total time |
| U-06 | Playlists list | Built-in smart lists pinned at top |
| U-07 | Playlist detail and edit | Edit mode: reorder, delete, multi-select |
| U-08 | Now Playing | See §5 |
| U-09 | Now Playing flipped (track list and rating) | Flip animation |
| U-10 | Up Next queue | Reorder, remove, clear, "Save as playlist" |
| U-11 | Search | Grouped results with scope control |
| U-12 | Track Info sheet | Tags, format, path, ReplayGain, counts |
| U-13 | Signal Path | Decoder → DSP → output, rate, depth, backend, xruns; later "bit-perfect" evidence |
| U-14 | Equalizer | 10 bands, preamp, presets, on/off |
| U-15 | Settings | Library, Playback, Output, Appearance, About |
| U-16 | Sleep timer sheet | |
| U-17 | More | Lens list plus Edit |
| U-18 | Diagnostics | Engine state, logs export |
| U-19 | Add to playlist sheet | Create new inline |
| U-20 | Track action sheet | See §4 |

## 4. Interaction model (identical in every track list)

**Row anatomy**: artwork (optional), primary line, secondary line, right-aligned duration, optional badges. Playing row shows a speaker glyph and an accent color.

**Tap**: start the **context** (the list exactly as displayed, including any search filter) at the tapped item. Setting: "Tap a song plays: this list from here (default) / only this song".

**Long-press**: track action sheet with Play next, Add to queue, Add to playlist, Go to artist, Go to album, Love / Unlove, Rate, Track info, Share (v1.1), Delete from device (v1.1, confirmation).

**Edit button** (list nav bar): shows reorder handles and delete controls where applicable; multi-select applies the sheet actions to many tracks.

**Headers**: Play and Shuffle buttons on album, artist, playlist, folder.

**Alphabet index**: right-edge scrubber on sorted lists; touch-drag jumps sections; includes a magnifier at the top that focuses search.

**Queue semantics**: Up Next always plays before the remainder of the context. "Play next" inserts at the top of Up Next; "Add to queue" appends. Starting a new context never clears Up Next unless the user chooses "Clear".

**Stop after current**: toggle in the Now Playing menu; shown as a small badge on the transport.

## 5. Now Playing (U-08, U-09)

Portrait layout, top to bottom:
1. Nav bar: Back, "3 of 12", flip button.
2. Artwork (square, with optional reflection effect in the Classic skin).
3. Scrubber: elapsed, remaining, draggable knob; accurate to the presented position (AGENTS §6.9).
4. Title, artist, album.
5. Transport: previous, play/pause, next (long-press = seek).
6. System volume slider (mirrors Android volume; no software gain).
7. Strip: repeat (off/all/one), shuffle, Up Next, equalizer shortcut.

Tap artwork to flip to the track list of the current context, with a star-rating row for the playing track and tap-to-jump. Swipe down dismisses. Landscape in v1.0: same elements in two columns; Cover Flow-style browse is a v1.1 candidate.

## 6. Row format presets (P-20)

| Preset | Line 1 | Line 2 | Right |
|---|---|---|---|
| Classic | Title | Artist — Album | duration |
| Detailed | Title | Artist — Album · FLAC 24/96 | duration |
| Compact | `01. Title` | (none) | duration |

Token names used in code and later in user formats: `%title%`, `%artist%`, `%albumartist%`, `%album%`, `%track%`, `%disc%`, `%year%`, `%genre%`, `%codec%`, `%samplerate%`, `%bitdepth%`, `%bitrate%`, `%duration%`.

## 7. States

| Situation | Behavior |
|---|---|
| No permission | U-01 explainer; "Open settings" if permanently denied; the app is usable for "Open with" files |
| Empty library | Illustration-free message plus "Choose folders" and "Rescan" |
| Scanning | Thin non-blocking progress strip under the nav bar; lists fill in progressively |
| Missing file | Row greyed with "File not found"; auto-skip during playback with a toast |
| Unsupported format | Skip with a toast; entry flagged in Diagnostics |
| Output lost (unplug, route change) | Pause, then resume only on explicit play (headphone unplug) |
| Notification permission denied | Playback works; show a one-time hint in Settings |

## 8. Visual language (original artwork only; see `docs/09-design-handoff.md`)

Classic skin: fabric-like background texture, glossy gradient bars, embossed labels, inset segmented controls, chrome-style scrubber knob and glossy buttons, subtle row separators with disclosure chevrons, sticky section headers, an alphabet index with a pressed state. Plain skin: flat surfaces, high contrast, no textures.

Everything is drawn from scratch in Figma. Reference screenshots of any product are for private study only and must not be traced or exported.

## 9. Motion and haptics

Push and pop transitions, the flip (Y-axis rotation with perspective), scrubber press scale, and a light haptic tick on index-section changes. Respect "remove animations" (`MediaQuery.disableAnimations`) by replacing the flip with a cross-fade.

## 10. Accessibility

- Semantics labels on all controls; scrubber exposes value and increments.
- Minimum 48 dp targets; layouts verified at 200% font scale.
- Plain skin meets WCAG AA text contrast (4.5:1). Classic skin is checked and any failing text uses a higher-contrast override.
- Never rely on color alone for state (playing, loved, downloaded).

## 11. Responsive rules

Phone portrait is the design target for v1.0. Layout code uses breakpoints from day one: below 600 dp single pane; from 600 dp (v1.1) two panes (lens list and detail, Fooyin-style) with a persistent Now Playing bar.

## 12. UX acceptance checklist (for human checks)

- [ ] From a fresh install, music plays within 60 s.
- [ ] Every list opens in <300 ms with 20k tracks and scrolls without visible stutter.
- [ ] Alphabet index jumps correctly for Latin, digits and non-Latin titles.
- [ ] Tapping a song in a search result plays the result list from that song.
- [ ] Up Next survives app restart and plays before the context.
- [ ] Flip animation is smooth; reduce-motion replaces it with a fade.
- [ ] Notification, lock screen and headset buttons match in-app state.
