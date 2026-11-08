/// The base spacing scale, in logical pixels.
///
/// Metric literals belong in token files like this one, not in widgets
/// (AGENTS.md §8). The full skin contract (colors, typography, textures) is
/// added in M3.1.
abstract final class SkinSpacing {
  /// Extra-small gap: 4 dp.
  static const double xs = 4;

  /// Small gap: 8 dp.
  static const double sm = 8;

  /// Medium gap: 16 dp.
  static const double md = 16;

  /// Large gap: 24 dp.
  static const double lg = 24;

  /// Extra-large gap: 32 dp.
  static const double xl = 32;
}
