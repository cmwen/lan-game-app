import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:min_flutter_template/main.dart';

void main() {
  testWidgets('App renders splash screen with title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PartyPocketApp()));
    await tester.pump();

    expect(find.textContaining('Party Pocket'), findsOneWidget);

    // Flush the splash screen's auto-navigation timer
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
