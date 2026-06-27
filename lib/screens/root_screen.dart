import 'dart:async';

import 'package:flutter/material.dart';

import '../models/settings.dart';
import '../models/shift.dart';
import '../services/repository.dart';
import 'calendar_tab.dart';
import 'home_tab.dart';
import 'settings_sheet.dart';
import 'shift_edit_sheet.dart';
import 'trends_tab.dart';

/// Owns the shared shift/settings state and hosts the three tabs.
class RootScreen extends StatefulWidget {
  final Repository repository;
  const RootScreen({super.key, required this.repository});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  late List<Shift> _shifts;
  late Settings _settings;
  int _periodOffset = 0;
  int _tab = 0;
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

  Future<void> _persist() => widget.repository.saveShifts(_shifts);

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
        _periodOffset = 0;
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

  /// Edit an existing shift, or add a new one ([existing] null). When [initialDay]
  /// is given (from the calendar), a new shift defaults to that day.
  Future<void> _editShift(Shift? existing, {DateTime? initialDay}) async {
    final result = await showModalBottomSheet<ShiftEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShiftEditSheet(shift: existing, initialDay: initialDay),
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

  static const _titles = ['Shift Tracker', 'Calendar', 'Trends'];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(
        shifts: _shifts,
        activeShift: _activeShift,
        settings: _settings,
        periodOffset: _periodOffset,
        onPunch: _togglePunch,
        onEditShift: (s) => _editShift(s),
        onAddShift: () => _editShift(null),
        onPrevPeriod: () => setState(() => _periodOffset--),
        onNextPeriod:
            _periodOffset < 0 ? () => setState(() => _periodOffset++) : null,
      ),
      CalendarTab(
        shifts: _shifts,
        rounding: _settings.roundingMinutes,
        onEditShift: (s) => _editShift(s),
        onAddOnDay: (day) => _editShift(null, initialDay: day),
      ),
      TrendsTab(shifts: _shifts, rounding: _settings.roundingMinutes),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(_titles[_tab],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.access_time), label: 'Track'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart), label: 'Trends'),
        ],
      ),
    );
  }
}
