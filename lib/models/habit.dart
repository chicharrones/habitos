import 'dart:convert';
import 'package:flutter/material.dart';

class Habit {
  final int? id;
  final String title;
  final String description;
  final int iconCodePoint;
  final int colorValue;
  final String frequencyType; // 'daily', 'specificDays', 'timesPerWeek'
  final List<int> frequencyDays; // 1 = Mon, ..., 7 = Sun
  final int targetTimesPerWeek;
  final List<String> alarmTimes; // ['08:00', '20:00']
  final String createdAt;
  final bool isArchived;

  Habit({
    this.id,
    required this.title,
    required this.description,
    this.iconCodePoint = 0xe243, // Icons.fitness_center
    this.colorValue = 0xFF009688, // Colors.teal
    this.frequencyType = 'daily',
    this.frequencyDays = const [1, 2, 3, 4, 5, 6, 7],
    this.targetTimesPerWeek = 7,
    this.alarmTimes = const [],
    String? createdAt,
    this.isArchived = false,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String().split('T').first;

  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'frequencyType': frequencyType,
      'frequencyDays': jsonEncode(frequencyDays),
      'targetTimesPerWeek': targetTimesPerWeek,
      'alarmTimes': jsonEncode(alarmTimes),
      'createdAt': createdAt,
      'isArchived': isArchived ? 1 : 0,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    List<int> parsedDays = [1, 2, 3, 4, 5, 6, 7];
    if (map['frequencyDays'] != null && map['frequencyDays'].toString().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(map['frequencyDays']);
        parsedDays = decoded.cast<int>();
      } catch (_) {}
    }

    List<String> parsedAlarms = [];
    if (map['alarmTimes'] != null && map['alarmTimes'].toString().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(map['alarmTimes']);
        parsedAlarms = decoded.cast<String>();
      } catch (_) {
        if (map['alarmTime'] != null) {
          parsedAlarms = [map['alarmTime'].toString()];
        }
      }
    } else if (map['alarmTime'] != null) {
      parsedAlarms = [map['alarmTime'].toString()];
    }

    return Habit(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      iconCodePoint: map['iconCodePoint'] ?? 0xe243,
      colorValue: map['colorValue'] ?? 0xFF009688,
      frequencyType: map['frequencyType'] ?? 'daily',
      frequencyDays: parsedDays,
      targetTimesPerWeek: map['targetTimesPerWeek'] ?? 7,
      alarmTimes: parsedAlarms,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String().split('T').first,
      isArchived: map['isArchived'] == 1,
    );
  }

  Habit copyWith({
    int? id,
    String? title,
    String? description,
    int? iconCodePoint,
    int? colorValue,
    String? frequencyType,
    List<int>? frequencyDays,
    int? targetTimesPerWeek,
    List<String>? alarmTimes,
    String? createdAt,
    bool? isArchived,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      frequencyType: frequencyType ?? this.frequencyType,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      targetTimesPerWeek: targetTimesPerWeek ?? this.targetTimesPerWeek,
      alarmTimes: alarmTimes ?? this.alarmTimes,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
