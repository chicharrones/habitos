import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../utils/notifications_helper.dart';

class AddHabitModal extends StatefulWidget {
  final Habit? habit;

  const AddHabitModal({Key? key, this.habit}) : super(key: key);

  static Future<void> show(BuildContext context, {Habit? habit}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddHabitModal(habit: habit),
    );
  }

  @override
  _AddHabitModalState createState() => _AddHabitModalState();
}

class _AddHabitModalState extends State<AddHabitModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late int _selectedIconCodePoint;
  late int _selectedColorValue;
  late String _frequencyType;
  late List<int> _frequencyDays;
  late List<String> _alarmTimes;

  static const List<IconData> _iconList = [
    Icons.fitness_center,
    Icons.directions_run,
    Icons.directions_walk,
    Icons.water_drop,
    Icons.menu_book,
    Icons.self_improvement,
    Icons.bed,
    Icons.code,
    Icons.music_note,
    Icons.palette,
    Icons.restaurant,
    Icons.language,
    Icons.savings,
    Icons.psychology,
    Icons.favorite,
    Icons.star,
  ];

  static const List<Color> _colorList = [
    Color(0xFF009688), // Teal
    Color(0xFF2196F3), // Blue
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF4CAF50), // Green
    Color(0xFF607D8B), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.habit?.description ?? '');

    _selectedIconCodePoint = widget.habit?.iconCodePoint ?? Icons.fitness_center.codePoint;
    _selectedColorValue = widget.habit?.colorValue ?? _colorList.first.value;
    _frequencyType = widget.habit?.frequencyType ?? 'daily';
    _frequencyDays = widget.habit != null ? List<int>.from(widget.habit!.frequencyDays) : [1, 2, 3, 4, 5, 6, 7];
    _alarmTimes = widget.habit != null ? List<String>.from(widget.habit!.alarmTimes) : [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatTimeString(BuildContext context, String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final tod = TimeOfDay(hour: hour, minute: minute);
    return tod.format(context);
  }

  void _addAlarmTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      if (!_alarmTimes.contains(formatted)) {
        setState(() {
          _alarmTimes.add(formatted);
          _alarmTimes.sort();
        });
      }
    }
  }

  void _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      final provider = Provider.of<HabitProvider>(context, listen: false);

      if (widget.habit != null) {
        final updated = widget.habit!.copyWith(
          title: title,
          description: description,
          iconCodePoint: _selectedIconCodePoint,
          colorValue: _selectedColorValue,
          frequencyType: _frequencyType,
          frequencyDays: _frequencyDays,
          alarmTimes: _alarmTimes,
        );
        await provider.updateHabit(updated);
        await NotificationsHelper.scheduleHabitAlarms(updated);
      } else {
        final newHabit = Habit(
          title: title,
          description: description,
          iconCodePoint: _selectedIconCodePoint,
          colorValue: _selectedColorValue,
          frequencyType: _frequencyType,
          frequencyDays: _frequencyDays,
          alarmTimes: _alarmTimes,
        );
        final created = await provider.addHabit(newHabit);
        await NotificationsHelper.scheduleHabitAlarms(created);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.habit == null ? 'Crear Nuevo Hábito' : 'Editar Hábito',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del hábito',
                  hintText: 'Ej. Leer 20 minutos',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  hintText: 'Ej. Libro de desarrollo personal',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Icon Selector
              Text('Selecciona un Icono', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _iconList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final icon = _iconList[index];
                    final isSelected = _selectedIconCodePoint == icon.codePoint;
                    return InkWell(
                      onTap: () => setState(() => _selectedIconCodePoint = icon.codePoint),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Color(_selectedColorValue).withOpacity(0.2) : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: Color(_selectedColorValue), width: 2) : null,
                        ),
                        child: Icon(icon, color: isSelected ? Color(_selectedColorValue) : theme.iconTheme.color),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Color Selector
              Text('Selecciona un Color', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _colorList.map((color) {
                  final isSelected = _selectedColorValue == color.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorValue = color.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                            : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Frequency
              Text('Frecuencia', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos los días'),
                    selected: _frequencyType == 'daily',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _frequencyType = 'daily';
                          _frequencyDays = [1, 2, 3, 4, 5, 6, 7];
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Días específicos'),
                    selected: _frequencyType == 'specificDays',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _frequencyType = 'specificDays');
                      }
                    },
                  ),
                ],
              ),

              if (_frequencyType == 'specificDays') ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (index) {
                    final dayNumber = index + 1; // 1 = Mon, ..., 7 = Sun
                    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                    final isSelected = _frequencyDays.contains(dayNumber);
                    return FilterChip(
                      label: Text(dayLabels[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _frequencyDays.add(dayNumber);
                          } else {
                            if (_frequencyDays.length > 1) {
                              _frequencyDays.remove(dayNumber);
                            }
                          }
                          _frequencyDays.sort();
                        });
                      },
                    );
                  }),
                ),
              ],

              const SizedBox(height: 20),

              // Alarms
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recordatorios / Alarmas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    onPressed: _addAlarmTime,
                    icon: const Icon(Icons.add_alarm, size: 18),
                    label: const Text('Añadir hora'),
                  ),
                ],
              ),
              if (_alarmTimes.isEmpty)
                Text('Sin recordatorios configurados', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey))
              else
                Wrap(
                  spacing: 8,
                  children: _alarmTimes.map((time) {
                    return Chip(
                      avatar: const Icon(Icons.alarm, size: 16),
                      label: Text(_formatTimeString(context, time)),
                      onDeleted: () {
                        setState(() => _alarmTimes.remove(time));
                      },
                    );
                  }).toList(),
                ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveHabit,
                  icon: const Icon(Icons.check),
                  label: Text(
                    widget.habit == null ? 'Crear Hábito' : 'Guardar Cambios',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
