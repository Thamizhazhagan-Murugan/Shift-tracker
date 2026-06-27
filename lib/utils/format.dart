// Lightweight date/time formatting (no intl dependency).

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String two(int n) => n.toString().padLeft(2, '0');

/// e.g. "Jun 27"
String fmtShortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

/// e.g. "Sat, Jun 27"
String fmtLongDay(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';

/// e.g. "9:05 AM"
String fmtClock(DateTime d) {
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '$hour12:${two(d.minute)} $ampm';
}

/// Seconds -> "HH:MM:SS"
String fmtElapsed(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  return '${two(h)}:${two(m)}:${two(s)}';
}

String fmtHours(double h) => h.toStringAsFixed(2);
