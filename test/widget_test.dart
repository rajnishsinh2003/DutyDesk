import 'package:flutter_test/flutter_test.dart';
import 'package:duty_desk/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Splash screen branding smoke test', (WidgetTester tester) async {
    // Build our app under ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: DutyDeskApp()));

    // Verify that the splash screen text exists.
    expect(find.text('DutyDesk'), findsOneWidget);
    expect(find.text('Exam Invigilation Management'), findsOneWidget);

    // Advance virtual clock by 3 seconds to trigger the delayed navigation timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}


