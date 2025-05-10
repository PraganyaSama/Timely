import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/master_subject.dart';
import '../models/subject.dart';
import '../services/database_helper.dart';

Future<bool> showSubjectDialog({
  required BuildContext context,
  Subject? existing,
  bool isHomeScreen = false,
  required int weekday,
}) async {
  final db = DatabaseHelper.instance;
  final masterSubjects = await db.getAllMasterSubjects();
  final formKey = GlobalKey<FormState>();
  MasterSubject? selectedMasterSubject = existing != null
      ? masterSubjects.firstWhere((ms) => ms.name == existing.name)
      : null;

  TimeOfDay? start, end;
  if (existing != null) {
    final times = existing.time.split('-').map((t) => t.trim()).toList();
    start = TimeOfDay(
      hour: int.parse(times[0].split(':')[0]),
      minute: int.parse(times[0].split(':')[1]),
    );
    end = TimeOfDay(
      hour: int.parse(times[1].split(':')[0]),
      minute: int.parse(times[1].split(':')[1]),
    );
  }

  return await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Subject' : 'Edit Subject'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<MasterSubject>(
                  value: selectedMasterSubject,
                  items: masterSubjects
                      .map((ms) =>
                          DropdownMenuItem(value: ms, child: Text(ms.name)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedMasterSubject = val),
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (v) =>
                      v == null ? 'Please select a subject' : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(start != null
                      ? start?.format(context) ?? 'Start Time'
                      : 'Start Time'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: start ?? TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => start = picked);
                  },
                ),
                ListTile(
                  title: Text(end != null
                      ? end?.format(context) ?? 'End Time'
                      : 'End Time'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: end ?? TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => end = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate() ||
                    start == null ||
                    end == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Please complete all fields')),
                  );
                  return;
                }

                final newSubject = Subject(
                  id: existing?.id,
                  name: selectedMasterSubject!.name,
                  time: '${start!.format(context)} - ${end!.format(context)}',
                  day: isHomeScreen ? '' : weekday.toString(),
                  status: 'Scheduled',
                  date: isHomeScreen
                      ? DateFormat('yyyy-MM-dd').format(DateTime.now())
                      : '',
                );

                if (existing == null) {
                  await db.insertSubject(newSubject);
                } else {
                  await db.updateSubject(newSubject);
                }

                Navigator.of(ctx).pop(true);
              },
              child: Text(existing == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    ),
  ).then((val) => val ?? false);
}
