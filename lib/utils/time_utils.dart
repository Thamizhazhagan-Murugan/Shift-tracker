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

/// Midnight of the given moment's local calendar day.
DateTime dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// Total rounded hours worked on [day] (shifts attributed by their start date).
double hoursOnDay(List<Shift> shifts, DateTime day, int rounding,
    {DateTime? now}) {
  final key = dayKey(day);
  var total = 0.0;
  for (final s in shifts) {
    if (dayKey(s.start) == key) {
      total += shiftHours(s, rounding, now: now);
    }
  }
  return total;
}

/// Map of calendar day -> total rounded hours, for every day that has a shift.
Map<DateTime, double> hoursByDay(List<Shift> shifts, int rounding,
    {DateTime? now}) {
  final map = <DateTime, double>{};
  for (final s in shifts) {
    final key = dayKey(s.start);
    map[key] = (map[key] ?? 0) + shiftHours(s, rounding, now: now);
  }
  return map;
}

/// Sunday on or before [d] — the start of [d]'s calendar week.
DateTime weekStart(DateTime d) {
  final k = dayKey(d);
  return k.subtract(Duration(days: k.weekday % 7));
}

/// First day of [d]'s calendar month.
DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);

/// Total rounded hours for shifts whose start is in [start, end).
double hoursInRange(
    List<Shift> shifts, DateTime start, DateTime end, int rounding,
    {DateTime? now}) {
  var total = 0.0;
  for (final s in shifts) {
    if (!s.start.isBefore(start) && s.start.isBefore(end)) {
      total += shiftHours(s, rounding, now: now);
    }
  }
  return total;
}
