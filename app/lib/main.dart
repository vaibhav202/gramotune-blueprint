import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:ui_kit/ui_kit.dart';

// Milestone reference for the missing pieces in this placeholder:
// M3.1 adds the skin, M3.2 the real screens, M3.3 routing and state.
// Strings move to ARB files when the first real screen lands (M3.2).

void main() {
  runApp(const GramotuneApp());
}

/// The composition root.
///
/// The only package allowed to import every other package (AGENTS.md §5).
class GramotuneApp extends StatelessWidget {
  /// Creates the app shell.
  const GramotuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gramotune',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: PlaceholderView(
            title: 'Gramotune',
            subtitle: 'M0.2 placeholder · ${appFlavor ?? 'unflavored'} flavor',
          ),
        ),
      ),
    );
  }
}
