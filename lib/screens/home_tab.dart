import 'package:flutter/material.dart';

import '../models/settings.dart';
import '../models/shift.dart';
import '../utils/format.dart';
import '../utils/time_utils.dart';
import 'widgets.dart';

/// The "Track" tab: punch button, current pay-period summary, shift list.
class HomeTab extends StatelessWidget {
  final List<Shift> shifts;
  final Shift? activeShift;
  final Settings settings;
  final int periodOffset;
  final VoidCallback onPunch;
  final void Function(Shift) onEditShift;
  final VoidCallback onAddShift;
  final VoidCallback onPrevPeriod;
  final VoidCallback? onNextPeriod;

  const HomeTab({
    super.key,
    required this.shifts,
    required this.activeShift,
    required this.settings,
    required this.periodOffset,
    required this.onPunch,
    required this.onEditShift,
    required this.onAddShift,
    required this.onPrevPeriod,
    required this.onNextPeriod,
  });

  List<Shift> _shiftsIn(PayPeriod period) {
    final list = shifts
        .where((s) =>
            !s.start.isBefore(period.start) && s.start.isBefore(period.end))
        .toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final period = viewedPeriod(settings.periodStart, periodOffset);
    final inPeriod = _shiftsIn(period);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _PunchCard(activeShift: activeShift, onPressed: onPunch),
        const SizedBox(height: 16),
        _PeriodCard(
          period: period,
          shifts: inPeriod,
          rounding: settings.roundingMinutes,
          isCurrent: periodOffset == 0,
          onPrev: onPrevPeriod,
          onNext: onNextPeriod,
        ),
        const SizedBox(height: 16),
        _ShiftListCard(
          shifts: inPeriod,
          rounding: settings.roundingMinutes,
          onAdd: onAddShift,
          onTap: onEditShift,
        ),
      ],
    );
  }
}

class _PunchCard extends StatelessWidget {
  final Shift? activeShift;
  final VoidCallback onPressed;
  const _PunchCard({required this.activeShift, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final active = activeShift != null;
    final elapsed =
        active ? DateTime.now().difference(activeShift!.start).inSeconds : 0;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
      child: Column(
        children: [
          Text('STATUS',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  letterSpacing: 1.4)),
          const SizedBox(height: 6),
          Text(active ? 'Punched in' : 'Punched out',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (active)
            Text(fmtElapsed(elapsed),
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                )),
          if (active) const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor:
                    active ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              ),
              child: Text(active ? 'Punch Out' : 'Punch In',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          if (active) ...[
            const SizedBox(height: 10),
            Text('Since ${fmtClock(activeShift!.start)}',
                style:
                    TextStyle(color: Colors.white.withOpacity(0.5))),
          ],
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final PayPeriod period;
  final List<Shift> shifts;
  final int rounding;
  final bool isCurrent;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _PeriodCard({
    required this.period,
    required this.shifts,
    required this.rounding,
    required this.isCurrent,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    double total = 0, week1 = 0, week2 = 0;
    final mid = period.midpoint;
    for (final s in shifts) {
      final h = shiftHours(s, rounding, now: now);
      total += h;
      if (s.start.isBefore(mid)) {
        week1 += h;
      } else {
        week2 += h;
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('This Pay Period',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left), onPressed: onPrev),
                IconButton(
                    icon: const Icon(Icons.chevron_right), onPressed: onNext),
              ]),
            ],
          ),
          Text(
            '${fmtShortDate(period.start)} – ${fmtShortDate(period.lastDay)}'
            '${isCurrent ? '  (current)' : ''}',
            style: TextStyle(
                color: Colors.white.withOpacity(0.55), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(fmtHours(total),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  )),
              const SizedBox(width: 6),
              Text('hrs',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55))),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            _WeekBox(
                label: 'Week 1 (${fmtShortDate(period.start)})',
                hours: week1),
            const SizedBox(width: 10),
            _WeekBox(label: 'Week 2 (${fmtShortDate(mid)})', hours: week2),
          ]),
        ],
      ),
    );
  }
}

class _WeekBox extends StatelessWidget {
  final String label;
  final double hours;
  const _WeekBox({required this.label, required this.hours});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12)),
            const SizedBox(height: 2),
            Text(fmtHours(hours),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                )),
          ],
        ),
      ),
    );
  }
}

class _ShiftListCard extends StatelessWidget {
  final List<Shift> shifts;
  final int rounding;
  final VoidCallback onAdd;
  final void Function(Shift) onTap;

  const _ShiftListCard({
    required this.shifts,
    required this.rounding,
    required this.onAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shifts',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          if (shifts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No shifts in this period yet.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5))),
              ),
            )
          else
            ..._buildGroupedRows(),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedRows() {
    final rows = <Widget>[];
    String? lastDay;
    for (final s in shifts) {
      final key = '${s.start.year}-${s.start.month}-${s.start.day}';
      if (key != lastDay) {
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4, left: 2),
          child: Text(fmtLongDay(s.start).toUpperCase(),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                  letterSpacing: 0.6)),
        ));
        lastDay = key;
      }
      rows.add(ShiftRow(
        shift: s,
        hours: shiftHours(s, rounding),
        onTap: () => onTap(s),
      ));
      rows.add(const SizedBox(height: 8));
    }
    return rows;
  }
}
