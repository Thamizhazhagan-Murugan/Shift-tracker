/// User preferences: the biweekly pay-period anchor and time rounding.
class Settings {
  /// Local date (time component ignored) that anchors the 14-day pay periods.
  DateTime periodStart;

  /// Round each shift's duration to the nearest N minutes (1 = no rounding).
  int roundingMinutes;

  Settings({required this.periodStart, this.roundingMinutes = 1});

  Map<String, dynamic> toJson() => {
        'periodStart': periodStart.toIso8601String(),
        'roundingMinutes': roundingMinutes,
      };

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
        periodStart: DateTime.parse(json['periodStart'] as String),
        roundingMinutes: (json['roundingMinutes'] as int?) ?? 1,
      );

  /// Default anchor: the most recent Sunday, so periods start on a Sunday.
  factory Settings.defaults() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sunday = today.subtract(Duration(days: today.weekday % 7));
    return Settings(periodStart: sunday, roundingMinutes: 1);
  }
}
