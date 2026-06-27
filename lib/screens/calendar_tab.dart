import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/shift.dart';
import '../utils/format.dart';
import '../utils/time_utils.dart';
import 'widgets.dart';

/// Interactive month calendar: each day shows hours worked; tap a day to see
/// and edit that day's shifts.
class CalendarTab extends StatefulWidget {
  final List<Shift> shifts;
  final int rounding;
  final void Function(Shift) onEditShift;
  final void Function(DateTime day) onAddOnDay;

  const CalendarTab({
    super.key,
    required this.shifts,
    required this.rounding,
    required this.onEditShift,
    required this.onAddOnDay,
  });

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = dayKey(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final byDay = hoursByDay(widget.shifts, widget.rounding);
    final accent = Theme.of(context).colorScheme.primary;

    final dayShifts = widget.shifts
        .where((s) => dayKey(s.start) == dayKey(_selectedDay))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final dayTotal = hoursOnDay(widget.shifts, _selectedDay, widget.rounding);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        AppCard(
          padding: const EdgeInsets.all(8),
          child: TableCalendar<double>(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            currentDay: dayKey(DateTime.now()),
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            startingDayOfWeek: StartingDayOfWeek.sunday,
            eventLoader: (day) {
              final h = byDay[dayKey(day)];
              return h != null && h > 0 ? [h] : const [];
            },
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = dayKey(selected);
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) => _focusedDay = focused,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              weekendStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: const TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              todayDecoration: BoxDecoration(
                color: accent.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders<double>(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 1,
                  child: Text(
                    fmtHours(events.first),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF34D399),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fmtLongDay(_selectedDay),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${fmtHours(dayTotal)} h',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (dayShifts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('No shifts on this day.',
                      style:
                          TextStyle(color: Colors.white.withOpacity(0.5))),
                )
              else
                for (final s in dayShifts) ...[
                  ShiftRow(
                    shift: s,
                    hours: shiftHours(s, widget.rounding),
                    onTap: () => widget.onEditShift(s),
                  ),
                  const SizedBox(height: 8),
                ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => widget.onAddOnDay(_selectedDay),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add shift on this day'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
