import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/db_helper.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int totalHabits = 0;
  int completedHabits = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final allRecords = await DBHelper.instance.getAllHabitRecords();
    setState(() {
      totalHabits = allRecords.length;
      completedHabits = allRecords.where((r) => r.isCompleted).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    double completionRate = totalHabits == 0 ? 0 : (completedHabits / totalHabits) * 100;

    return Scaffold(
      appBar: AppBar(title: Text('Informe de Hábitos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Tasa Histórica de Cumplimiento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: completedHabits.toDouble(),
                      title: '${completionRate.toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.redAccent,
                      value: (totalHabits - completedHabits).toDouble(),
                      title: '',
                      radius: 50,
                    ),
                  ],
                ),
              ),
            ),
            Text('Total registros: $totalHabits'),
            Text('Completados: $completedHabits'),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
