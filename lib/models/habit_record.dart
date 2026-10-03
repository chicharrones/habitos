class HabitRecord {
  final int? id;
  final int habitId;
  final String date; // format YYYY-MM-DD
  final bool isCompleted;
  final String? notes;

  HabitRecord({
    this.id,
    required this.habitId,
    required this.date,
    required this.isCompleted,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date,
      'isCompleted': isCompleted ? 1 : 0,
      'notes': notes,
    };
  }

  factory HabitRecord.fromMap(Map<String, dynamic> map) {
    return HabitRecord(
      id: map['id'],
      habitId: map['habitId'],
      date: map['date'],
      isCompleted: map['isCompleted'] == 1,
      notes: map['notes'],
    );
  }
}
