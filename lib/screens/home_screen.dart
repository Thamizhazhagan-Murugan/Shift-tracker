import 'dart:async';

import 'package:flutter/material.dart';

import '../models/settings.dart';
import '../models/shift.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../utils/time_utils.dart';
import 'settings_sheet.dart';
import 'shift_edit_sheet.dart';

class HomeScreen extends StatefulWidget {
  final Repository repository;
  const HomeScreen({super.key, required this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Shift> _shifts;
  late Settings _settings;
  int _periodOffset = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _shifts = widget.repository.loadShifts();
    _settings = widget.repository.loadSettings();
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Shift? get _activeShift {
    for (final s in _shifts) {
      if (s.inProgress) return s;
    }
    return null;
  }

  /// Run a 1-second ticker only while a shift is in progress.
  void _syncTicker() {
    if (_activeShift != null) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> _persist() async {
    await widget.repository.saveShifts(_shifts);
  }

  void _togglePunch() {
    setState(() {
      final active = _activeShift;
      if (active != null) {
        active.end = DateTime.now();
      } else {
        _shifts.add(Shift(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          start: DateTime.now(),
        ));
        _periodOffset = 0; // jump back to current period
      }
      _syncTicker();
    });
    _persist();
  }

  Future<void> _openSettings() async {
    final updated = await showModalBottomSheet<Settings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SettingsSheet(settings: _settings),
    );
    if (updated != null) {
      setState(() {
        _settings = updated;
        _periodOffset = 0;
      });
      await widget.repository.saveSettings(updated);
    }
  }

  Future<void> _editShift(Shift? existing) async {
    final result = await showModalBottomSheet<ShiftEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShiftEditSheet(shift: existing),
    );
    if (result == null) return;
    setState(() {
      if (result.deleted) {
        _shifts.removeWhere((s) => s.id == existing!.id);
      } else if (existing != null) {
        existing
          ..start = result.start
          ..end = result.end
          ..note = result.note;
      } else {
        _shifts.add(Shift(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          start: result.start,
          end: result.end,
          note: result.note,
        ));
      }
      _syncTicker();
    });
    _persist();
  }

  List<Shift> _shiftsIn(PayPeriod period) {
    final list = _shifts
        .where((s) =>
            !s.start.isBefore(period.start) && s.start.isBefore(period.end))
        .toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final period = viewedPeriod(_settings.periodStart, _periodOffset);
    final inPeriod = _shiftsIn(period);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Shift Tracker',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _PunchCard(
            activeShift: _activeShift,
            onPressed: _togglePunch,
          ),
          const SizedBox(height: 16),
          _PeriodCard(
            period: period,
            shifts: inPeriod,
            rounding: _settings.roundingMinutes,
            isCurrent: _periodOffset == 0,
            onPrev: () => setState(() => _periodOffset--),
            onNext: _periodOffset < 0
                ? () => setState(() => _periodOffset++)
                : null,
          ),
          const SizedBox(height: 16),
          _ShiftListCard(
            shifts: inPeriod,
            rounding: _settings.roundingMinutes,
            onAdd: () => _editShift(null),
            onTap: _editShift,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
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
    final elapsed = active
        ? DateTime.now().difference(activeShift!.start).inSeconds
        : 0;

    return _Card(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
      child: Column(
        children: [
          Text(
            'STATUS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            active ? 'Punched in' : 'Punched out',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (active)
            Text(
              fmtElapsed(elapsed),
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
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
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                active ? 'Punch Out' : 'Punch In',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (active) ...[
            const SizedBox(height: 10),
            Text(
              'Since ${fmtClock(activeShift!.start)}',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
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

    return _Card(
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
                  icon: const Icon(Icons.chevron_left),
                  onPressed: onPrev,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onNext,
                ),
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
              Text(
                fmtHours(total),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Text('hrs',
                  style: TextStyle(color: Colors.white.withOpacity(0.55))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _WeekBox(
                  label: 'Week 1 (${fmtShortDate(period.start)})',
                  hours: week1),
              const SizedBox(width: 10),
              _WeekBox(
                  label: 'Week 2 (${fmtShortDate(mid)})', hours: week2),
            ],
          ),
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
                    color: Colors.white.withOpacity(0.55), fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              fmtHours(hours),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
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
    return _Card(
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
                    style: TextStyle(color: Colors.white.withOpacity(0.5))),
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
    final now = DateTime.now();
    for (final s in shifts) {
      final dayKey = '${s.start.year}-${s.start.month}-${s.start.day}';
      if (dayKey != lastDay) {
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4, left: 2),
          child: Text(
            fmtLongDay(s.start).toUpperCase(),
            style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 12,
                letterSpacing: 0.6),
          ),
        ));
        lastDay = dayKey;
      }
      rows.add(_ShiftRow(
        shift: s,
        hours: shiftHours(s, rounding, now: now),
        onTap: () => onTap(s),
      ));
      rows.add(const SizedBox(height: 8));
    }
    return rows;
  }
}

class _ShiftRow extends StatelessWidget {
  final Shift shift;
  final double hours;
  final VoidCallback onTap;
  const _ShiftRow(
      {required this.shift, required this.hours, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeStr = shift.inProgress
        ? '${fmtClock(shift.start)} – in progress'
        : '${fmtClock(shift.start)} – ${fmtClock(shift.end!)}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(12),
          border: shift.inProgress
              ? Border.all(color: const Color(0xFF16A34A), width: 2)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timeStr,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (shift.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      shift.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                          fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${fmtHours(hours)} h',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
