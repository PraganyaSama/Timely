import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subject.dart';
import '../services/database_helper.dart';
import '../widgets/class_card.dart';
import '../widgets/subject_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DatabaseHelper.instance;
  late Future<List<Subject>> _subjectsFuture;
  late final int todayWeekday;
  late final String todayDate;

  @override
  void initState() {
    super.initState();
    todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    todayWeekday = DateTime.now().weekday;
    _subjectsFuture = _loadSubjects();

    // Initialize Notification Service if needed (Optional)
    // NotificationService().init();
  }

  Future<List<Subject>> _loadSubjects() async {
    return db.getSubjectsByDate(todayDate);
  }

  Future<void> _refreshData() async {
    setState(() {
      _subjectsFuture = _loadSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Schedule"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: FutureBuilder<List<Subject>>(
        future: _subjectsFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }
          final subjects = snapshot.data ?? [];
          if (subjects.isEmpty) {
            return const Center(child: Text('No classes scheduled for today.'));
          }
          return Column(
            children: [
              _buildSummaryCard(subjects),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: subjects.length,
                  itemBuilder: (_, i) {
                    final subj = subjects[i];
                    return ClassCard(
                      subject: subj,
                      onStatusChanged: (subj, newStatus) {
                        return db
                          .updateSubjectStatus(subj.id!, newStatus)
                          .then((_) => _refreshData());
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final changed = await showSubjectDialog(
            context: context,
            weekday: todayWeekday,
            isHomeScreen: true, // ✅ Add subject only for today
          );
          if (changed) _refreshData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(List<Subject> subjects) {
    final total     = subjects.length;
    final scheduled = subjects.where((s) => s.status == 'Scheduled').length;
    final attended  = subjects.where((s) => s.status == 'Attended').length;
    final missed    = subjects.where((s) => s.status == 'Missed').length;
    final cancelled = subjects.where((s) => s.status == 'Cancelled').length;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('Total',     total.toString()),
            _statItem('Scheduled', scheduled.toString()),
            _statItem('Attended',  attended.toString()),
            _statItem('Missed',    missed.toString()),
            _statItem('Cancelled', cancelled.toString()),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
