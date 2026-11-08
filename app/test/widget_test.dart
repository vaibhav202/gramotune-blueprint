import 'package:flutter_test/flutter_test.dart';
import 'package:gramotune/main.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  testWidgets('app shows the placeholder screen', (tester) async {
    await tester.pumpWidget(const GramotuneApp());

    expect(find.byType(PlaceholderView), findsOneWidget);
    expect(find.text('Gramotune'), findsOneWidget);
  });
}
