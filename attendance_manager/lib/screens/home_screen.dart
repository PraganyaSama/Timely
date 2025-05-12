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
    _subjectsFuture = _loadSubjects(); // Initialize here to prevent LateInitializationError
  }

  Future<List<Subject>> _loadSubjects() async {
    // Step 1: Ensure today's schedule is generated
    await db.generateTodayScheduleIfNeeded(todayDate, todayWeekday);
    // Step 2: Fetch subjects for today
    final subjects = await db.getSubjectsByDate(todayDate);

    // Step 3: Sort subjects by time
    subjects.sort((a, b) {
      final timeA = _parseTime(a.time);
      final timeB = _parseTime(b.time);
      return timeA.compareTo(timeB);
    });

    return subjects;
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
            isHomeScreen: true,
          );
          if (changed) _refreshData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(List<Subject> subjects) {
    final total = subjects.length;
    final scheduled = subjects
        .where((s) => s.status == 'Pending' || s.status == 'Scheduled')
        .length;
    final attended = subjects.where((s) => s.status == 'Attended').length;
    final missed = subjects.where((s) => s.status == 'Missed').length;
    final cancelled = subjects.where((s) => s.status == 'Cancelled').length;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('Total', total.toString()),
            _statItem('Scheduled', scheduled.toString()),
            _statItem('Attended', attended.toString()),
            _statItem('Missed', missed.toString()),
            _statItem('Cancelled', cancelled.toString()),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }

TimeOfDay _parseTime(String input) {
  try {
    final startTimeStr = input.split('-').first.trim(); // Get start time only
    final dt = DateFormat.jm().parseLoose(startTimeStr);
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  } catch (e) {
    debugPrint('Failed to parse time: $input');
    return const TimeOfDay(hour: 0, minute: 0); // Fallback time
  }
}
}
