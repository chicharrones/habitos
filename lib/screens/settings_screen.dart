import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/theme_provider.dart';
import '../providers/habit_provider.dart';
import '../database/db_helper.dart';
import '../models/habit.dart';
import '../models/habit_record.dart';
import '../utils/notifications_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _exportData(BuildContext context) async {
    try {
      final habits = await DBHelper.instance.getAllHabits(includeArchived: true);
      final records = await DBHelper.instance.getAllHabitRecords();

      final data = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'habits': habits.map((h) => h.toMap()).toList(),
        'records': records.map((r) => r.toMap()).toList(),
      };

      final jsonString = jsonEncode(data);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/habitos_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copia de seguridad guardada en: ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        if (data.containsKey('habits') && data.containsKey('records')) {
          final habitsList = (data['habits'] as List).cast<Map<String, dynamic>>();
          final recordsList = (data['records'] as List).cast<Map<String, dynamic>>();

          for (final hMap in habitsList) {
            final habit = Habit.fromMap(hMap);
            await DBHelper.instance.insertHabit(habit);
          }

          for (final rMap in recordsList) {
            final record = HabitRecord.fromMap(rMap);
            await DBHelper.instance.insertOrUpdateHabitRecord(record);
          }

          if (context.mounted) {
            await Provider.of<HabitProvider>(context, listen: false).fetchHabits();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Datos importados con éxito')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al importar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Apariencia', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Seguir al sistema'),
                  value: ThemeMode.system,
                  groupValue: themeProvider.themeMode,
                  onChanged: (mode) => themeProvider.setThemeMode(mode!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Tema Claro'),
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  onChanged: (mode) => themeProvider.setThemeMode(mode!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Tema Oscuro'),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  onChanged: (mode) => themeProvider.setThemeMode(mode!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('Notificaciones y Batería', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('Permisos de Notificaciones'),
                  subtitle: const Text('Solicitar o verificar permisos de notificaciones exactas'),
                  onTap: () async {
                    final granted = await NotificationsHelper.requestPermissions();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(granted ? 'Permisos concedidos' : 'Abre los ajustes para activar permisos'),
                          action: SnackBarAction(
                            label: 'Ajustes',
                            onPressed: () => openAppSettings(),
                          ),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.battery_saver),
                  title: const Text('Optimización de Batería'),
                  subtitle: const Text('Excluir la app para asegurar la llegada puntual de alarmas'),
                  onTap: () => NotificationsHelper.openBatteryOptimizationSettings(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('Datos y Copia de Seguridad', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Exportar Datos (JSON)'),
                  subtitle: const Text('Guardar una copia de tus hábitos y registros'),
                  onTap: () => _exportData(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_for_offline),
                  title: const Text('Importar Datos (JSON)'),
                  subtitle: const Text('Restaurar copia de seguridad existente'),
                  onTap: () => _importData(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('Acerca de', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Hábitos App'),
              subtitle: Text('Versión 1.0.0 • Material Design 3'),
            ),
          ),
        ],
      ),
    );
  }
}
