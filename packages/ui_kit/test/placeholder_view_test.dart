import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  testWidgets('PlaceholderView shows its title and optional subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlaceholderView(title: 'Gramotune', subtitle: 'M0.2'),
        ),
      ),
    );

    expect(find.text('Gramotune'), findsOneWidget);
    expect(find.text('M0.2'), findsOneWidget);
  });

  testWidgets('PlaceholderView hides the subtitle when it is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PlaceholderView(title: 'Gramotune')),
      ),
    );

    expect(find.text('Gramotune'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });
}
