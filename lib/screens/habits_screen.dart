import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/add_habit_modal.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({Key? key}) : super(key: key);

  @override
  _HabitsScreenState createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos los Hábitos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activos'),
            Tab(text: 'Archivados'),
          ],
        ),
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          final activeHabits = provider.habits.where((h) {
            return h.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                h.description.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          final archivedHabits = provider.archivedHabits.where((h) {
            return h.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                h.description.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar hábito...',
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHabitList(context, activeHabits, isArchivedList: false),
                    _buildHabitList(context, archivedHabits, isArchivedList: true),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => AddHabitModal.show(context),
      ),
    );
  }

  Widget _buildHabitList(BuildContext context, List habits, {required bool isArchivedList}) {
    final theme = Theme.of(context);
    final provider = Provider.of<HabitProvider>(context, listen: false);

    if (habits.isEmpty) {
      return Center(
        child: Text(
          isArchivedList ? 'No hay hábitos archivados' : 'No se encontraron hábitos',
          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final bestStreak = provider.getBestStreak(habit.id!);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: habit.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(habit.icon, color: habit.color),
            ),
            title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${habit.description.isNotEmpty ? '${habit.description}\n' : ''}Mejor racha: 🏆 $bestStreak días',
            ),
            isThreeLine: habit.description.isNotEmpty,
            trailing: PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'edit') {
                  AddHabitModal.show(context, habit: habit);
                } else if (val == 'archive') {
                  await provider.archiveHabit(habit.id!, !isArchivedList);
                } else if (val == 'delete') {
                  await provider.deleteHabit(habit.id!);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Editar')])),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(children: [
                    Icon(isArchivedList ? Icons.unarchive : Icons.archive, size: 20),
                    const SizedBox(width: 8),
                    Text(isArchivedList ? 'Desarchivar' : 'Archivar'),
                  ]),
                ),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ),
        );
      },
    );
  }
}
