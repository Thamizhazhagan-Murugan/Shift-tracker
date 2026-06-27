import 'package:flutter/material.dart';

import '../models/shift.dart';
import '../utils/format.dart';

/// A rounded dark panel used throughout the app.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const AppCard({
    super.key,
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

/// A single shift row showing its time span, optional note, and hours.
class ShiftRow extends StatelessWidget {
  final Shift shift;
  final double hours;
  final VoidCallback onTap;
  const ShiftRow({
    super.key,
    required this.shift,
    required this.hours,
    required this.onTap,
  });

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
                    Text(shift.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                            fontSize: 12)),
                  ],
                ],
              ),
            ),
            Text('${fmtHours(hours)} h',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                )),
          ],
        ),
      ),
    );
  }
}
