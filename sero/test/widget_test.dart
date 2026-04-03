import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/app/app.dart';

void main() {
  testWidgets('Splash screen branding test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We wrap in ProviderScope because SocietyApp uses Riverpod.
    await tester.pumpWidget(
      const ProviderScope(
        child: SocietyApp(),
      ),
    );

    // Verify that the splash screen shows the branded 'SERO' text.
    // Note: Splash screen has a delay and animations, so we might need pumpAndSettle if testing navigation.
    expect(find.text('SERO'), findsOneWidget);
  });
}
