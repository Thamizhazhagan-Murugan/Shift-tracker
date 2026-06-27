import 'package:flutter/material.dart';

import '../models/shift.dart';
import '../utils/format.dart';

/// Result returned from the edit sheet.
class ShiftEditResult {
  final DateTime start;
  final DateTime? end;
  final String note;
  final bool deleted;
  ShiftEditResult({
    required this.start,
    required this.end,
    required this.note,
    this.deleted = false,
  });

  factory ShiftEditResult.delete() =>
      ShiftEditResult(start: DateTime.now(), end: null, note: '', deleted: true);
}

/// Bottom sheet to add or edit a shift.
class ShiftEditSheet extends StatefulWidget {
  final Shift? shift; // null = adding a new shift
  const ShiftEditSheet({super.key, this.shift});

  @override
  State<ShiftEditSheet> createState() => _ShiftEditSheetState();
}

class _ShiftEditSheetState extends State<ShiftEditSheet> {
  late DateTime _start;
  DateTime? _end;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final s = widget.shift;
    if (s != null) {
      _start = s.start;
      _end = s.end;
      _noteController = TextEditingController(text: s.note);
    } else {
      final now = DateTime.now();
      _start = DateTime(now.year, now.month, now.day, now.hour);
      _end = _start.add(const Duration(hours: 8));
      _noteController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _save() {
    if (_end != null && _end!.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }
    Navigator.pop(
      context,
      ShiftEditResult(
        start: _start,
        end: _end,
        note: _noteController.text.trim(),
      ),
    );
  }

  String _fmt(DateTime d) => '${fmtLongDay(d)}  •  ${fmtClock(d)}';

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.shift != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEditing ? 'Edit Shift' : 'Add Shift',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _DateTimeField(
            label: 'Start',
            value: _fmt(_start),
            onTap: () async {
              final picked = await _pickDateTime(_start);
              if (picked != null) setState(() => _start = picked);
            },
          ),
          const SizedBox(height: 14),
          _DateTimeField(
            label: 'End',
            value: _end == null ? 'In progress (tap to set)' : _fmt(_end!),
            onTap: () async {
              final picked = await _pickDateTime(_end ?? _start);
              if (picked != null) setState(() => _end = picked);
            },
            trailing: _end != null
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Mark in progress',
                    onPressed: () => setState(() => _end = null),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (isEditing)
                TextButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, ShiftEditResult.delete()),
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFFDC2626)),
                  label: const Text('Delete',
                      style: TextStyle(color: Color(0xFFDC2626))),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: trailing,
        ),
        child: Text(value, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}
