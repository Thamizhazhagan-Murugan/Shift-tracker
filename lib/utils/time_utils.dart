import '../models/shift.dart';

/// A half-open time range [start, end).
class PayPeriod {
  final DateTime start;
  final DateTime end;
  final int index;
  const PayPeriod(this.start, this.end, this.index);

  DateTime get midpoint => DateTime(start.year, start.month, start.day + 7);
  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);
}

/// Duration of a shift in hours, rounded to [roundingMinutes].
/// An in-progress shift (no end) is measured up to [now].
double shiftHours(Shift shift, int roundingMinutes, {DateTime? now}) {
  final end = shift.end ?? (now ?? DateTime.now());
  var minutes = end.difference(shift.start).inSeconds / 60.0;
  if (minutes < 0) minutes = 0;
  if (roundingMinutes > 1) {
    minutes = (minutes / roundingMinutes).round() * roundingMinutes.toDouble();
  }
  return minutes / 60.0;
}

/// Boundaries of the pay period [index] periods away from the anchor.
/// Uses calendar-date math so periods stay on local midnight across DST.
PayPeriod periodBounds(DateTime anchor, int index) {
  final start = DateTime(anchor.year, anchor.month, anchor.day + 14 * index);
  final end = DateTime(anchor.year, anchor.month, anchor.day + 14 * (index + 1));
  return PayPeriod(start, end, index);
}

/// Index of the pay period containing [moment].
int periodIndexFor(DateTime anchor, DateTime moment) {
  var idx = (moment.difference(anchor).inDays / 14).floor();
  // Correct for any DST / truncation drift.
  while (moment.isBefore(periodBounds(anchor, idx).start)) {
    idx--;
  }
  while (!moment.isBefore(periodBounds(anchor, idx).end)) {
    idx++;
  }
  return idx;
}

/// The pay period being viewed: current period shifted by [offset]
/// (0 = current, -1 = previous, …). [offset] is never positive in practice.
PayPeriod viewedPeriod(DateTime anchor, int offset, {DateTime? now}) {
  final current = periodIndexFor(anchor, now ?? DateTime.now());
  return periodBounds(anchor, current + offset);
}
