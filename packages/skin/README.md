# skin

The skin system: the token contract, baked textures and shader helpers.

## Boundaries

- May import Flutter.
- Never `engine`, `engine_api`, `music_library`, `sources`, `platform_android` or the
  app (AGENTS.md §5).

## Public API

- `SkinSpacing` — the base spacing scale (M0.2).
- `Skin`, `SkinColors`, `SkinTypography`, `SkinMetrics`, the token loader and
  the texture helpers — added in M3.1 (docs/09-design-handoff.md §4).

## Status

Skeleton created in M0.2. The full token model and the Classic and Plain skins
land in M3.1.
