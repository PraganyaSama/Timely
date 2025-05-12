// ignore_for_file: unused_field, unused_local_variable

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../models/subject.dart';
import '../models/master_subject.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;
  List<Subject> _allSubjects = [];
  List<MasterSubject> _masterSubjects = [];
  bool _isFiltered = false;
  String? _filteredSubjectName;
  List<Subject> _filteredClasses = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadSubjects();
    _loadMasterSubjects();
  }

  void _loadHistory() {
    final db = Provider.of<DatabaseHelper>(context, listen: false);
    _historyFuture = db.getAttendanceStatsAll();
  }

  void _loadSubjects() async {
    final db = Provider.of<DatabaseHelper>(context, listen: false);
    final subjects = await db.getAllSubjects();
    setState(() {
      _allSubjects = subjects;
    });
  }

  void _loadMasterSubjects() async {
    final db = Provider.of<DatabaseHelper>(context, listen: false);
    final subjects = await db.getAllMasterSubjects();
    setState(() {
      _masterSubjects = subjects;
    });
  }

  void _filterBySubject(String subjectName) async {
    final db = Provider.of<DatabaseHelper>(context, listen: false);
    final allClasses = await db.getAllSubjects();
    final filtered = allClasses
        .where((s) =>
            s.name.toLowerCase() == subjectName.toLowerCase() &&
            ['Attended', 'Missed', 'Cancelled', 'Scheduled'].contains(s.status))
        .toList();

    setState(() {
      _filteredSubjectName = subjectName;
      _filteredClasses = filtered;
      _isFiltered = true;
    });
  }

  void _clearFilter() {
    setState(() {
      _isFiltered = false;
      _filteredSubjectName = null;
      _filteredClasses.clear();
    });
  }

  void _showSubjectFilterDialog() {
    showDialog(
      context: context,
      builder: (_) {
        List<MasterSubject> filteredSubjects = List.from(_masterSubjects);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Filter by Subject', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                filteredSubjects.isEmpty
                    ? const Center(child: Text('No subjects found.'))
                    : Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredSubjects.length,
                          itemBuilder: (context, index) {
                            final subject = filteredSubjects[index];
                            return ListTile(
                              leading: const Icon(Icons.book),
                              title: Text(subject.name),
                              onTap: () {
                                Navigator.pop(context);
                                _filterBySubject(subject.name);
                              },
                            );
                          },
                        ),
                      ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearFilter();
                      },
                      child: const Text('Clear Filter'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('EEE, MMM d, yyyy').format(parsed);
    } catch (_) {
      return date;
    }
  }

  void _showClassesForDate(String date) async {
    final db = Provider.of<DatabaseHelper>(context, listen: false);
    final classes = await db.getSubjectsByDate(date);

    final filteredClasses = classes
        .where((subject) =>
            ['Attended', 'Missed', 'Cancelled', 'Scheduled']
                .contains(subject.status))
        .toList();

    if (filteredClasses.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No Classes'),
          content: const Text('No classes with relevant status on this day.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDate(date),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...filteredClasses.map((subject) {
              final allStatuses = ['Attended', 'Missed', 'Cancelled', 'Scheduled'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(subject.name),
                  subtitle: Text('${subject.time} - ${subject.status}'),
                  trailing: DropdownButton<String>(
                    value: subject.status,
                    items: allStatuses
                        .map((status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(
                                status,
                                style: TextStyle(color: _getStatusColor(status)),
                              ),
                            ))
                        .toList(),
                    onChanged: (newStatus) async {
                      if (newStatus != null && newStatus != subject.status) {
                        await db.updateSubjectStatus(subject.id!, newStatus);
                        setState(() => _loadHistory());
                        Navigator.pop(context);
                        _showClassesForDate(date);
                      }
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showSubjectFilterDialog,
          ),
        ],
      ),
      body: _isFiltered
          ? _filteredClasses.isEmpty
              ? const Center(child: Text('No classes found for this subject.'))
              : SingleChildScrollView(
                  child: Column(
                    children: _filteredClasses.map((s) {
                      return Card(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        child: ListTile(
                          title: Text(
                            '${_formatDate(s.date)} - ${s.time}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Status: ${s.status}'),
                          onTap: () {
                            _showClassesForDate(s.date);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                )
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final history = snapshot.data!;
                if (history.isEmpty) {
                  return const Center(child: Text('No history available.'));
                }

                history.sort((a, b) {
                  final dateA = DateTime.parse(a['date']);
                  final dateB = DateTime.parse(b['date']);
                  return dateB.compareTo(dateA);
                });

                Map<String, List<Map<String, dynamic>>> groupedHistory = {};
                for (var item in history) {
                  final date = item['date']?.toString() ?? '';
                  if (groupedHistory.containsKey(date)) {
                    groupedHistory[date]?.add(item);
                  } else {
                    groupedHistory[date] = [item];
                  }
                }

                return SingleChildScrollView(
                  child: Column(
                    children: groupedHistory.entries.map((entry) {
                      final date = entry.key;
                      final classes = entry.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            ...classes.map((classItem) {
                              final attended = classItem['attended'] ?? 0;
                              final missed = classItem['missed'] ?? 0;
                              final cancelled = classItem['cancelled'] ?? 0;
                              final total = classItem['total'] ?? 0;
                              final percentage =
                                  total == 0 ? 0.0 : (attended / total) * 100;

                              final subjectName =
                                  classItem['name'] ?? "Unknown Subject";
                              final subjectTime = classItem['time'] ?? "No Time";
                              final displayTitle =
                                  (subjectName == "Unknown Subject" &&
                                          subjectTime == "No Time")
                                      ? _formatDate(classItem['date'] ?? '')
                                      : '$subjectName - $subjectTime';

                              final isScheduled = classItem['status'] == 'Scheduled';
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 1),
                                color: isScheduled ? Colors.blue.withOpacity(0.2) : null,
                                child: ListTile(
                                  title: Text(
                                    displayTitle,
                                    style: subjectName == "Unknown Subject"
                                        ? const TextStyle(
                                            fontWeight: FontWeight.bold)
                                        : null,
                                  ),
                                  subtitle: Text(
                                      'Attended: $attended, Missed: $missed, Cancelled: $cancelled'),
                                  trailing: Chip(
                                    label: Text(
                                        '${percentage.toStringAsFixed(1)}%'),
                                    backgroundColor:
                                        _getColor(percentage).withOpacity(0.2),
                                    labelStyle: TextStyle(
                                      color: _getColor(percentage),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () {
                                    if (classItem['date'] != null) {
                                      _showClassesForDate(classItem['date']);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Invalid or missing date.'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Attended':
        return Colors.green;
      case 'Missed':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      case 'Scheduled':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  Color _getColor(double pct) {
    if (pct >= 75) return Colors.green;
    if (pct >= 50) return Colors.orange;
    return Colors.red;
  }
}