import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gramotune/main.dart' as app;

/// The flavor the launcher is expected to have built, passed with
/// `--dart-define=EXPECTED_FLAVOR=<flavor>`. Empty means "do not check".
const String expectedFlavor = String.fromEnvironment('EXPECTED_FLAVOR');

/// M0.2 acceptance: the app launches on a device in a flavor and shows the
/// placeholder with that flavor name in the subtitle.
///
/// Run once per flavor:
///   `flutter test integration_test -d <device> --flavor play \`
///   `  --dart-define=EXPECTED_FLAVOR=play`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('placeholder renders with the active flavor', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(
      appFlavor,
      isNotNull,
      reason: 'the launcher must pass --flavor so appFlavor is set',
    );
    if (expectedFlavor.isNotEmpty) {
      expect(appFlavor, expectedFlavor);
    }

    expect(find.text('Gramotune'), findsOneWidget);
    expect(find.text('M0.2 placeholder · $appFlavor flavor'), findsOneWidget);
  });
}
