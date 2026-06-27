import 'package:flutter_test/flutter_test.dart';
import 'package:shift_tracker/models/shift.dart';
import 'package:shift_tracker/utils/time_utils.dart';

void main() {
  group('shiftHours', () {
    test('computes plain duration in hours', () {
      final s = Shift(
        id: '1',
        start: DateTime(2026, 1, 1, 9, 0),
        end: DateTime(2026, 1, 1, 17, 30),
      );
      expect(shiftHours(s, 1), closeTo(8.5, 1e-9));
    });

    test('rounds to nearest 15 minutes', () {
      final s = Shift(
        id: '1',
        start: DateTime(2026, 1, 1, 9, 0),
        end: DateTime(2026, 1, 1, 17, 7), // 8h7m -> rounds to 8h00m
      );
      expect(shiftHours(s, 15), closeTo(8.0, 1e-9));
    });

    test('in-progress shift measured up to now', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final s = Shift(id: '1', start: DateTime(2026, 1, 1, 10, 0));
      expect(shiftHours(s, 1, now: now), closeTo(2.0, 1e-9));
    });
  });

  group('pay periods', () {
    final anchor = DateTime(2026, 1, 4); // a Sunday

    test('14-day boundaries from anchor', () {
      final p0 = periodBounds(anchor, 0);
      expect(p0.start, DateTime(2026, 1, 4));
      expect(p0.end, DateTime(2026, 1, 18));
      expect(p0.lastDay, DateTime(2026, 1, 17));
      expect(p0.midpoint, DateTime(2026, 1, 11));
    });

    test('periodIndexFor finds the containing period', () {
      expect(periodIndexFor(anchor, DateTime(2026, 1, 4)), 0);
      expect(periodIndexFor(anchor, DateTime(2026, 1, 17, 23, 59)), 0);
      expect(periodIndexFor(anchor, DateTime(2026, 1, 18)), 1);
      expect(periodIndexFor(anchor, DateTime(2026, 1, 3, 23, 59)), -1);
    });

    test('viewedPeriod offset shifts backward', () {
      final now = DateTime(2026, 1, 20); // period index 1
      final current = viewedPeriod(anchor, 0, now: now);
      final prev = viewedPeriod(anchor, -1, now: now);
      expect(current.index, 1);
      expect(prev.index, 0);
    });
  });
}
