import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../widgets/add_habit_modal.dart';

class AddHabitScreen extends StatelessWidget {
  final Habit? habit;

  const AddHabitScreen({Key? key, this.habit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(habit == null ? 'Crear Hábito' : 'Editar Hábito'),
      ),
      body: AddHabitModal(habit: habit),
    );
  }
}
