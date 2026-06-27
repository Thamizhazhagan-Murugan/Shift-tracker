import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shift_tracker/main.dart';
import 'package:shift_tracker/services/repository.dart';

void main() {
  testWidgets('punch in then punch out records a shift',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = await Repository.open();
    await tester.pumpWidget(ShiftTrackerApp(repository: repo));

    // Starts punched out.
    expect(find.text('Punched out'), findsOneWidget);
    expect(find.text('Punch In'), findsOneWidget);

    // Punch in.
    await tester.tap(find.text('Punch In'));
    await tester.pump();
    expect(find.text('Punched in'), findsOneWidget);
    expect(find.text('Punch Out'), findsOneWidget);

    // Punch out.
    await tester.tap(find.text('Punch Out'));
    await tester.pump();
    expect(find.text('Punched out'), findsOneWidget);

    // One shift now appears in the list (shows "in progress"? no — completed).
    expect(repo.loadShifts().length, 1);
  });
}
