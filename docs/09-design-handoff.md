# 09 — Design handoff (Figma → Flutter)

Status: v0.1 (2026-10-31). The owner draws in Figma; agents implement; the owner judges the result by eye. Figma cannot author Flutter shaders, so Figma holds layout, textures, glyphs and states, and agents write the GLSL.

## 1. Division of work

| Who | Does |
|---|---|
| Owner | Figma frames, textures, glyphs, colors, states; final visual approval |
| Agent | Tokens → code, nine-slice and texture loading, widgets in `ui_kit`, GLSL shaders, golden tests, screenshots for review |
| Both | Review loop (§10) |

Agents may not see Figma unless the owner exports reference PNGs into `design/reference/` or connects a Figma MCP server. Without either, an agent must say it cannot compare and ask for exports.

## 2. Figma file structure

Pages: `00 Tokens`, `01 Components`, `02 Screens — Classic`, `03 Screens — Plain`, `04 Textures`, `05 Glyphs`, `06 Export`.
- Frame size 360 × 800 (1 unit = 1 dp). Check 412 × 915 and 600 wide variants for key screens.
- Component naming: `Component/Variant/State` (for example `NavBar/default`, `Button/glossy/pressed`).
- Every component shows the states: normal, pressed, disabled, selected (and focused where relevant).

## 3. Skin package layout

```
packages/skin/assets/classic/
  skin.json
  textures/      (seamless tiles 256² or 512²; background fabric, bar grain)
  nine_slice/    (buttons, bars, segmented control pieces, scrubber track and knob)
  glyphs/        (SVG, single color)
  shaders/       (.frag, written by agents)
packages/skin/assets/plain/skin.json   (flat; no textures)
```

Assets are declared in `pubspec.yaml`; shaders under `flutter: shaders:`. Resolution-aware images use `2.0x` and `3.0x` folders.

## 4. `skin.json` (token contract)

```json
{
  "id": "classic", "name": "Classic", "version": 1, "brightness": "light",
  "colors": { "background": "#…", "barTop": "#…", "barBottom": "#…", "accent": "#…",
              "text": "#…", "textSecondary": "#…", "separator": "#…", "rowSelected": "#…", "danger": "#…" },
  "metrics": { "navBarHeight": 44, "tabBarHeight": 49, "rowHeight": 56, "artworkRadius": 2, "gap": 8 },
  "typography": { "family": "…", "title": { "size": 17, "weight": 600 }, "body": { "size": 15, "weight": 400 },
                  "caption": { "size": 12, "weight": 400 } },
  "textures": { "background": "textures/fabric.webp" },
  "nineSlices": { "button": { "image": "nine_slice/button.png", "insets": [8, 8, 8, 8] } },
  "shaders": { "reflection": { "asset": "shaders/reflection.frag", "uniforms": { "strength": 0.35 } } }
}
```

Rules: the app reads only this file and assets it names; no literal colors or sizes in widgets; the Plain skin supplies the same keys with flat values.

## 5. Component list (`ui_kit`)

NavBar (title, back button, bar button items) · TabBar (5 items, selected glow) · SegmentedControl · ListRow (Classic, Detailed, Compact) · SectionHeader · AlphabetIndex · SearchBar with scope control · MiniPlayer · Scrubber (track, buffered, knob) · TransportButtons · VolumeSlider · ArtworkFrame (border, shadow, reflection) · StarRating · Switch · ActionSheet · Toast · ProgressStrip · EQ vertical sliders · Wheel picker (sleep timer) · PillButton · EmptyState · Badges (format, cloud, downloaded) · FlipContainer.

## 6. Glyphs and icons

- Draw glyphs once as **single-color SVG paths**. The Classic skin renders them with a gradient fill plus inner and outer shadow in code; the Plain skin renders them flat. One glyph set serves both skins and keeps the asset count low.
- Needed glyphs: back, forward, play, pause, previous, next, shuffle, repeat, repeat-one, queue, search, edit, more, star (on/off), heart (on/off), speaker (playing), cloud, downloaded arrow, folder, artist, album, song, playlist, genre, calendar, equalizer, timer, settings, close, check, drag handle.
- All glyphs are original drawings. Do not trace any platform's icon set.

## 7. Typography

Use an open-licensed family (OFL or Apache-2.0) with neutral, Helvetica-like proportions. Candidates: Inter, Arimo, a Nimbus Sans clone. Check the license before bundling and record it in `ASSETS.md`. No proprietary system fonts. Use tabular numerals for time displays. The owner picks the family in Figma.

## 8. Textures, gloss and shaders

Rule of thumb: **bake first, shade only if there is headroom.**

| Effect | Preferred implementation | Shader only if S6 shows headroom |
|---|---|---|
| Bar and button gloss | gradient defined in tokens, painted in code | `gloss.frag` with parametric highlight |
| Fabric background | seamless baked tile | `linen.frag` (procedural) |
| Brushed-metal plates and knobs | baked texture | `brushed_metal.frag` |
| Artwork reflection | mirrored image plus gradient mask in code | `reflection.frag` |

Limits (Flutter fragment shaders): GLSL `.frag` only, no vertex shaders, no UBO/SSBO, `sampler2D` only, two-argument `texture()`. Use `FlutterFragCoord()` for position, uniforms are set by index in declaration order, and `ImageFilter.shader` works only on Impeller. On OpenGLES, engine-provided textures are y-flipped.

Budget (provisional, set by S6): at most two live shader surfaces on screen, no full-screen animated shader, texture memory under ~20 MB, skin package under ~3 MB. Static shader results are rendered once to an image and cached.

## 9. App icon and launcher assets

Original design. Adaptive icon: 432 × 432 foreground with the important content inside the central 288 × 288 safe zone, a background layer, and a monochrome layer for themed icons. Avoid imitating any specific platform icon. Placeholder album art is also original.

## 10. Review loop

1. Owner exports reference PNGs of each frame (1×) into `design/reference/<screen>-<skin>.png`.
2. Agent implements, runs the golden or screenshot job, and writes `design/review/<screen>-<skin>.png`.
3. Agent lists known deviations. Tolerance: ±1 dp spacing, color difference visually negligible (ΔE < 3 where measurable).
4. Owner approves or comments; the agent records the outcome in the CHANGELOG and the human-check file.

## 11. Intellectual-property policy

- Original work only. Every asset is logged in `ASSETS.md` (author, date, source file, license).
- Reference screenshots of other products are for private study, never committed, traced or exported.
- The app name, package id and store text avoid Apple, iOS and iPod. Docs may say "iOS 6 style" descriptively.
- This is a practical policy, not legal advice. Consider a short legal check before a store release.

## 12. Per-screen handoff checklist

- [ ] Frame at 360 × 800 in Classic and Plain
- [ ] All states drawn (empty, loading, error, selected, edit mode)
- [ ] Spacing and sizes in dp annotated, tokens referenced by name
- [ ] Glyphs and textures exported to the skin folder
- [ ] Contrast of text tokens checked (Plain must reach AA)
