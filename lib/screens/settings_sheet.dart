import 'package:flutter/material.dart';

import '../models/settings.dart';
import '../utils/format.dart';

/// Bottom sheet for editing the pay-period anchor and rounding.
class SettingsSheet extends StatefulWidget {
  final Settings settings;
  const SettingsSheet({super.key, required this.settings});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late DateTime _periodStart;
  late int _rounding;

  static const _roundingOptions = {
    1: 'No rounding',
    5: '5 min',
    6: '6 min (1/10 hr)',
    15: '15 min',
  };

  @override
  void initState() {
    super.initState();
    _periodStart = widget.settings.periodStart;
    _rounding = widget.settings.roundingMinutes;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodStart,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Pay period start date',
    );
    if (picked != null) {
      setState(() => _periodStart =
          DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const Text('Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Pay period start date'),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
                '${fmtLongDay(_periodStart)}, ${_periodStart.year}'),
          ),
          const SizedBox(height: 4),
          Text(
            'Anchor for biweekly periods — pick the start of any real pay period.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
          const SizedBox(height: 20),
          const Text('Round each shift to nearest'),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: _rounding,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: _roundingOptions.entries
                .map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _rounding = v ?? 1),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  Settings(
                      periodStart: _periodStart, roundingMinutes: _rounding),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
