import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/master_subject.dart';
import '../services/database_helper.dart';
import '../widgets/add_subjects_dialog.dart';
import '../main.dart';

class SubjectManagerScreen extends StatefulWidget {
  const SubjectManagerScreen({super.key});

  @override
  State<SubjectManagerScreen> createState() => _SubjectManagerScreenState();
}

class _SubjectManagerScreenState extends State<SubjectManagerScreen> {
  List<MasterSubject> _subjects = [];

  @override
  void initState() {
    super.initState();
    _refreshSubjects();
  }

  Future<void> _refreshSubjects() async {
    final subjects = await DatabaseHelper.instance.getAllMasterSubjects();
    setState(() {
      _subjects = subjects;
    });
  }

  Future<void> _addSubject() async {
    final result = await showDialog<MasterSubject>( 
      context: context,
      builder: (_) => const AddSubjectDialog(),
    );

    if (result != null) {
      await DatabaseHelper.instance.insertMasterSubject(result);
      _refreshSubjects();
    }
  }

  Future<void> _editSubject(MasterSubject subject) async {
    final result = await showDialog<MasterSubject>(
      context: context,
      builder: (_) => AddSubjectDialog(existingSubject: subject),
    );

    if (result != null) {
      await DatabaseHelper.instance.updateMasterSubject(result);
      _refreshSubjects();
    }
  }

  Future<void> _deleteSubject(MasterSubject subject) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Remove "${subject.name}" permanently?'),
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

    if (shouldDelete == true) {
      await DatabaseHelper.instance.deleteMasterSubject(subject.id!);
      _refreshSubjects();
    }
  }

  IconData _nextThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.palette; // Switching to aesthetic mode
      case ThemeMode.dark:
        return Icons.wb_sunny; // Switching to light mode
      case ThemeMode.system:
        return Icons.nightlight_round; // Switching to dark mode
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<MyAppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        actions: [
          IconButton(
            icon: Icon(_nextThemeIcon(themeState.themeMode)),
            tooltip: 'Switch Theme',
            onPressed: () {
              themeState.toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _addSubject,
              icon: const Icon(Icons.add),
              label: const Text('Add Subject'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: _subjects.isEmpty
                ? const Center(child: Text('No subjects added yet.'))
                : ListView.builder(
                    itemCount: _subjects.length,
                    itemBuilder: (_, index) {
                      final subject = _subjects[index];
                      return Card(
                        margin:
                            const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            subject.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle:
                              Text('${subject.code} • ${subject.description}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editSubject(subject),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteSubject(subject),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
