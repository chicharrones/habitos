import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/habit.dart';
import '../models/habit_record.dart';

class HabitProvider with ChangeNotifier {
  List<Habit> _habits = [];
  List<Habit> _archivedHabits = [];
  List<HabitRecord> _todayRecords = [];
  List<HabitRecord> _allRecords = [];
  String _today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  Habit? _recentlyDeletedHabit;
  List<HabitRecord> _recentlyDeletedRecords = [];

  List<Habit> get habits => _habits;
  List<Habit> get archivedHabits => _archivedHabits;
  List<HabitRecord> get todayRecords => _todayRecords;
  List<HabitRecord> get allRecords => _allRecords;
  String get todayDate => _today;

  Future<void> fetchHabits() async {
    _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final allHabits = await DBHelper.instance.getAllHabits(includeArchived: true);
    _habits = allHabits.where((h) => !h.isArchived).toList();
    _archivedHabits = allHabits.where((h) => h.isArchived).toList();

    _todayRecords = await DBHelper.instance.getHabitRecordsForDate(_today);
    _allRecords = await DBHelper.instance.getAllHabitRecords();
    notifyListeners();
  }

  Future<Habit> addHabit(Habit habit) async {
    final newHabit = await DBHelper.instance.insertHabit(habit);
    await fetchHabits();
    return newHabit;
  }

  Future<void> updateHabit(Habit habit) async {
    await DBHelper.instance.updateHabit(habit);
    await fetchHabits();
  }

  Future<void> archiveHabit(int id, bool archive) async {
    await DBHelper.instance.archiveHabit(id, archive);
    await fetchHabits();
  }

  Future<void> deleteHabit(int id) async {
    _recentlyDeletedHabit = _habits.firstWhere((h) => h.id == id, orElse: () => _archivedHabits.firstWhere((h) => h.id == id));
    _recentlyDeletedRecords = _allRecords.where((r) => r.habitId == id).toList();

    await DBHelper.instance.deleteHabit(id);
    await fetchHabits();
  }

  Future<void> undoDeleteHabit() async {
    if (_recentlyDeletedHabit != null) {
      final restored = await DBHelper.instance.insertHabit(_recentlyDeletedHabit!);
      if (restored.id != null) {
        for (final rec in _recentlyDeletedRecords) {
          await DBHelper.instance.insertOrUpdateHabitRecord(
            HabitRecord(
              habitId: restored.id!,
              date: rec.date,
              isCompleted: rec.isCompleted,
              notes: rec.notes,
            ),
          );
        }
      }
      _recentlyDeletedHabit = null;
      _recentlyDeletedRecords = [];
      await fetchHabits();
    }
  }

  bool isHabitCompletedToday(int habitId) {
    try {
      final record = _todayRecords.firstWhere((element) => element.habitId == habitId);
      return record.isCompleted;
    } catch (_) {
      return false;
    }
  }

  bool isHabitCompletedOnDate(int habitId, String dateStr) {
    try {
      final record = _allRecords.firstWhere((element) => element.habitId == habitId && element.date == dateStr);
      return record.isCompleted;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleHabitCompletion(int habitId, {String? dateStr}) async {
    final targetDate = dateStr ?? _today;
    bool isCompleted = isHabitCompletedOnDate(habitId, targetDate);

    final record = HabitRecord(
      habitId: habitId,
      date: targetDate,
      isCompleted: !isCompleted,
    );

    await DBHelper.instance.insertOrUpdateHabitRecord(record);
    await fetchHabits();
  }

  double getTodayCompletionPercentage() {
    if (_habits.isEmpty) return 0.0;
    int completedCount = 0;
    for (final habit in _habits) {
      if (isHabitCompletedToday(habit.id!)) {
        completedCount++;
      }
    }
    return completedCount / _habits.length;
  }

  int getCurrentStreak(int habitId) {
    int streak = 0;
    DateTime date = DateTime.now();

    // Check today first, if not completed check if yesterday was completed
    String todayStr = DateFormat('yyyy-MM-dd').format(date);
    bool completedToday = isHabitCompletedOnDate(habitId, todayStr);

    if (!completedToday) {
      date = date.subtract(const Duration(days: 1));
    }

    while (true) {
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      if (isHabitCompletedOnDate(habitId, dateStr)) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  int getBestStreak(int habitId) {
    final habitRecords = _allRecords.where((r) => r.habitId == habitId && r.isCompleted).toList();
    if (habitRecords.isEmpty) return 0;

    habitRecords.sort((a, b) => a.date.compareTo(b.date));

    int bestStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    for (final rec in habitRecords) {
      final recDate = DateTime.tryParse(rec.date);
      if (recDate == null) continue;

      if (lastDate == null) {
        currentStreak = 1;
      } else {
        final diff = recDate.difference(lastDate).inDays;
        if (diff == 1) {
          currentStreak++;
        } else if (diff > 1) {
          currentStreak = 1;
        }
      }
      if (currentStreak > bestStreak) {
        bestStreak = currentStreak;
      }
      lastDate = recDate;
    }

    return bestStreak;
  }
}
