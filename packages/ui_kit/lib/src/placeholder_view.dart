import 'package:flutter/material.dart';
import 'package:skin/skin.dart';

/// A centered title and optional subtitle shown while a screen is not built.
///
/// Presentational only. The caller supplies the strings and wraps it in a
/// `Scaffold` and any chrome it needs.
class PlaceholderView extends StatelessWidget {
  /// Creates a placeholder with a required [title] and an optional [subtitle].
  const PlaceholderView({required this.title, this.subtitle, super.key});

  /// The main line, normally the screen or app name.
  final String title;

  /// A secondary line, normally the milestone or flavor.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SkinSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: SkinSpacing.sm),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
