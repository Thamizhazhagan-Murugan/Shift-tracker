import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:shift_tracker/main.dart';
import 'package:shift_tracker/services/repository.dart';

void main() {
  testWidgets('punch in then punch out records a shift',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = await Repository.open();
    await tester.pumpWidget(ShiftTrackerApp(repository: repo));

    // Starts clocked out.
    expect(find.text('Clocked out'), findsOneWidget);
    expect(find.text('Punch In'), findsOneWidget);

    // Punch in.
    await tester.tap(find.text('Punch In'));
    await tester.pump();
    expect(find.text('Clocked in'), findsOneWidget);
    expect(find.text('Punch Out'), findsOneWidget);

    // Punch out.
    await tester.tap(find.text('Punch Out'));
    await tester.pump();
    expect(find.text('Clocked out'), findsOneWidget);

    // One shift now appears in the list (shows "in progress"? no — completed).
    expect(repo.loadShifts().length, 1);
  });

  testWidgets('calendar and trends tabs render', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = await Repository.open();
    await tester.pumpWidget(ShiftTrackerApp(repository: repo));

    // Calendar tab shows an interactive month calendar.
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.byType(TableCalendar<double>), findsOneWidget);

    // Trends tab shows the bar chart and mode switcher.
    await tester.tap(find.text('Trends'));
    await tester.pumpAndSettle();
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Hours per day'), findsOneWidget);

    // Switching to Week mode re-renders without error.
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text('Hours per week'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });
}
