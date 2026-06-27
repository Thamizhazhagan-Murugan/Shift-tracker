import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/shift.dart';
import '../utils/format.dart';
import '../utils/time_utils.dart';
import 'widgets.dart';

enum TrendMode { day, week, month }

class _Bucket {
  final String label;
  final double hours;
  final String fullLabel;
  _Bucket(this.label, this.hours, this.fullLabel);
}

/// Interactive bar-chart trends of hours worked by day, week, or month.
class TrendsTab extends StatefulWidget {
  final List<Shift> shifts;
  final int rounding;
  const TrendsTab({super.key, required this.shifts, required this.rounding});

  @override
  State<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> {
  TrendMode _mode = TrendMode.day;
  int? _touched;

  List<_Bucket> _buckets() {
    final now = DateTime.now();
    switch (_mode) {
      case TrendMode.day:
        final today = dayKey(now);
        return List.generate(14, (i) {
          final day = today.subtract(Duration(days: 13 - i));
          final h = hoursInRange(widget.shifts, day,
              day.add(const Duration(days: 1)), widget.rounding,
              now: now);
          return _Bucket('${day.day}', h, fmtLongDay(day));
        });
      case TrendMode.week:
        final thisWeek = weekStart(now);
        return List.generate(8, (i) {
          final ws = thisWeek.subtract(Duration(days: 7 * (7 - i)));
          final we = ws.add(const Duration(days: 7));
          final h = hoursInRange(widget.shifts, ws, we, widget.rounding,
              now: now);
          return _Bucket('${ws.month}/${ws.day}', h,
              'Week of ${fmtShortDate(ws)}');
        });
      case TrendMode.month:
        return List.generate(6, (i) {
          final ms = DateTime(now.year, now.month - (5 - i), 1);
          final me = DateTime(ms.year, ms.month + 1, 1);
          final h = hoursInRange(widget.shifts, ms, me, widget.rounding,
              now: now);
          return _Bucket(_monthAbbrev(ms.month), h,
              '${_monthAbbrev(ms.month)} ${ms.year}');
        });
    }
  }

  static String _monthAbbrev(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];

  String get _unitLabel => switch (_mode) {
        TrendMode.day => 'day',
        TrendMode.week => 'week',
        TrendMode.month => 'month',
      };

  @override
  Widget build(BuildContext context) {
    final buckets = _buckets();
    final accent = Theme.of(context).colorScheme.primary;
    final maxHours = buckets.fold<double>(0, (m, b) => math.max(m, b.hours));
    final maxY = math.max(2.0, (maxHours / 2).ceil() * 2.0);

    final current = buckets.isNotEmpty ? buckets.last.hours : 0.0;
    final worked = buckets.where((b) => b.hours > 0).toList();
    final avg = worked.isEmpty
        ? 0.0
        : worked.fold<double>(0, (s, b) => s + b.hours) / worked.length;
    final total = buckets.fold<double>(0, (s, b) => s + b.hours);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        SegmentedButton<TrendMode>(
          segments: const [
            ButtonSegment(value: TrendMode.day, label: Text('Day')),
            ButtonSegment(value: TrendMode.week, label: Text('Week')),
            ButtonSegment(value: TrendMode.month, label: Text('Month')),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() {
            _mode = s.first;
            _touched = null;
          }),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Row(
            children: [
              _Stat(
                  label: 'This $_unitLabel',
                  value: fmtHours(current),
                  accent: accent),
              _Stat(label: 'Avg / $_unitLabel', value: fmtHours(avg)),
              _Stat(label: 'Total shown', value: fmtHours(total)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hours per $_unitLabel',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Tap a bar for details',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 12)),
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: BarChart(_chartData(buckets, maxY, accent)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BarChartData _chartData(
      List<_Bucket> buckets, double maxY, Color accent) {
    return BarChartData(
      maxY: maxY,
      alignment: BarChartAlignment.spaceAround,
      barTouchData: BarTouchData(
        touchCallback: (event, response) {
          if (!event.isInterestedForInteractions ||
              response == null ||
              response.spot == null) {
            setState(() => _touched = null);
            return;
          }
          setState(() =>
              _touched = response.spot!.touchedBarGroupIndex);
        },
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF0F172A),
          tooltipRoundedRadius: 8,
          getTooltipItem: (group, _, rod, __) {
            final b = buckets[group.x];
            return BarTooltipItem(
              '${b.fullLabel}\n',
              const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
              children: [
                TextSpan(
                  text: '${fmtHours(rod.toY)} h',
                  style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: maxY / 2,
            getTitlesWidget: (value, meta) => Text(
              value % 1 == 0 ? value.toInt().toString() : '',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= buckets.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(buckets[i].label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 9)),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 2,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: Colors.white.withOpacity(0.07), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (var i = 0; i < buckets.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: buckets[i].hours,
                width: _mode == TrendMode.day ? 12 : 18,
                color: _touched == i ? const Color(0xFF34D399) : accent,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ],
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;
  const _Stat({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 12)),
        ],
      ),
    );
  }
}
