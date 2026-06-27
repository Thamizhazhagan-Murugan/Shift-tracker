import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart';

import '../models/shift.dart';
import '../utils/format.dart';
import '../utils/time_utils.dart';
import 'repository.dart';

Shift? _activeIn(List<Shift> shifts) {
  for (final s in shifts) {
    if (s.inProgress) return s;
  }
  return null;
}

/// Bridges app state to the Android home-screen widget and handles taps on it.
class WidgetService {
  // Must match the fully-qualified Kotlin provider class name.
  static const _androidProvider =
      'com.shifttracker.shift_tracker.ShiftWidgetProvider';

  /// Push the current punch state to the home-screen widget.
  static Future<void> sync(List<Shift> shifts, int rounding) async {
    if (!Platform.isAndroid) return;
    try {
      final now = DateTime.now();
      final active = _activeIn(shifts);
      final today = hoursOnDay(shifts, now, rounding, now: now);

      await HomeWidget.saveWidgetData<bool>('clocked_in', active != null);
      await HomeWidget.saveWidgetData<String>(
          'status',
          active != null
              ? 'Clocked in at ${fmtClock(active.start)}'
              : 'Clocked out');
      await HomeWidget.saveWidgetData<String>(
          'action_label', active != null ? 'Punch Out' : 'Punch In');
      await HomeWidget.saveWidgetData<String>(
          'today', 'Today: ${fmtHours(today)} h');
      await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);
    } catch (_) {
      // Widget unavailable (e.g. not added yet) — ignore.
    }
  }

  /// Register the background tap handler. Safe to call on any platform.
  static Future<void> registerCallback() async {
    if (!Platform.isAndroid) return;
    try {
      await HomeWidget.registerInteractivityCallback(shiftWidgetCallback);
    } catch (_) {}
  }
}

/// Invoked (in a background isolate) when the widget's punch button is tapped.
@pragma('vm:entry-point')
Future<void> shiftWidgetCallback(Uri? uri) async {
  if (uri?.host != 'toggle') return;

  final repo = await Repository.open();
  final shifts = repo.loadShifts();
  final active = _activeIn(shifts);
  if (active != null) {
    active.end = DateTime.now();
  } else {
    shifts.add(Shift(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      start: DateTime.now(),
    ));
  }
  await repo.saveShifts(shifts);

  final settings = repo.loadSettings();
  await WidgetService.sync(shifts, settings.roundingMinutes);
}
