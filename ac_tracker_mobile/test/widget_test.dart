import 'package:flutter_test/flutter_test.dart';

import 'package:ac_tracker_mobile/main.dart';

void main() {
  testWidgets('App renders reminders screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AcTrackerApp());
    await tester.pump();

    expect(find.text('Reminders'), findsOneWidget);

    // initState triggers location/notification permission requests which are
    // not available in the test environment; consume the exception so it does
    // not fail the test.
    tester.takeException();
  });
}
