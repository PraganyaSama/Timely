import 'package:flutter/material.dart';
import '../models/master_subject.dart';
import '../models/subject.dart';
import '../services/database_helper.dart';
import 'package:intl/intl.dart';
import '../widgets/timetable_subject_dialog.dart'; // Import the new dialog function

class TimetableScreen extends StatefulWidget {
  final void Function() refreshHomeScreen; // Callback for refreshing home screen

  const TimetableScreen({super.key, required this.refreshHomeScreen});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final db = DatabaseHelper.instance;
  int selectedWeekday = DateTime.now().weekday;
  late Future<List<Subject>> _subjectsFuture;
  late Future<List<MasterSubject>> _masterSubjectsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _subjectsFuture = db.getSubjectsForDay(selectedWeekday.toString());
      _masterSubjectsFuture = db.getAllMasterSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const soothingTeal = Color(0xFF008080);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Timetable'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (_, i) {
                final wd = i + 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ChoiceChip(
                    label: Text(
                      days[i],
                      style: TextStyle(
                        color: selectedWeekday == wd ? Colors.white : Colors.black,
                      ),
                    ),
                    selected: selectedWeekday == wd,
                    onSelected: (_) {
                      setState(() => selectedWeekday = wd);
                      _loadData();
                    },
                    selectedColor: soothingTeal,
                    backgroundColor: Colors.grey[300],
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Subject>>(
              future: _subjectsFuture,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading subjects:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final subjects = snapshot.data ?? [];
                return _buildSubjectsList(subjects, soothingTeal);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubjectDialog(),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubjectsList(List<Subject> subjects, Color soothingTeal) {
    if (subjects.isEmpty) {
      return const Center(child: Text('No subjects added.'));
    }

    // ✅ Sort by parsed start time
    subjects.sort((a, b) {
      final timeA = _parseTime(a.time.split('-').first.trim());
      final timeB = _parseTime(b.time.split('-').first.trim());
      return (timeA.hour * 60 + timeA.minute).compareTo(timeB.hour * 60 + timeB.minute);
    });

    return FutureBuilder<List<MasterSubject>>(
      future: _masterSubjectsFuture,
      builder: (ctx, masterSubjectSnapshot) {
        if (!masterSubjectSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final masterSubjects = masterSubjectSnapshot.data!;

        return ListView.builder(
          itemCount: subjects.length,
          itemBuilder: (_, i) {
            final s = subjects[i];
            final masterSubject = masterSubjects.firstWhere(
              (ms) => ms.name == s.name,
              orElse: () => MasterSubject(name: 'Unknown', code: '', description: ''),
            );

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    masterSubject.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    _convertTo12HourRange(s.time),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  trailing: Icon(Icons.edit, color: soothingTeal),
                  onTap: () => _showSubjectDialog(existing: s),
                  onLongPress: () => _showDeleteConfirmation(s),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSubjectDialog({Subject? existing}) async {
    final didChange = await showTimetableSubjectDialog(
      context: context,
      existing: existing,
      weekday: selectedWeekday,
      refreshHomeScreen: widget.refreshHomeScreen,
    );
    if (didChange) {
      widget.refreshHomeScreen();
      _loadData();
    }
  }

  void _showDeleteConfirmation(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this period?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.deleteSubject(subject.id!);
      widget.refreshHomeScreen();
      _loadData();
    }
  }

  TimeOfDay _parseTime(String input) {
    try {
      final dt = DateFormat.jm().parseLoose(input.trim());
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (e) {
      debugPrint('Failed to parse time: $input');
      return const TimeOfDay(hour: 0, minute: 0); // Fallback
    }
  }

  String _convertTo12HourRange(String timeRange) {
    final parts = timeRange.split('-');
    if (parts.length != 2) return timeRange;

    final start = _parseTime(parts[0].trim());
    final end = _parseTime(parts[1].trim());

    return '${start.format(context)} - ${end.format(context)}';
  }
}
