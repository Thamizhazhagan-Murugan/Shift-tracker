/// A single work shift: a punch-in, an optional punch-out, and a note.
class Shift {
  final String id;
  DateTime start;
  DateTime? end; // null while the shift is still in progress
  String note;

  Shift({
    required this.id,
    required this.start,
    this.end,
    this.note = '',
  });

  bool get inProgress => end == null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'note': note,
      };

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        id: json['id'] as String,
        start: DateTime.parse(json['start'] as String),
        end: json['end'] == null ? null : DateTime.parse(json['end'] as String),
        note: (json['note'] as String?) ?? '',
      );
}
