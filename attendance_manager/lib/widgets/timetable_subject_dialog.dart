import 'package:flutter/material.dart';
import '../models/master_subject.dart';
import '../models/subject.dart';
import '../services/database_helper.dart';

Future<bool> showTimetableSubjectDialog({
  required BuildContext context,
  Subject? existing,
  required int weekday,
  required VoidCallback refreshHomeScreen, // This is to trigger a refresh in the Home Screen
}) async {
  final db = DatabaseHelper.instance;
  final masterSubjects = await db.getAllMasterSubjects();
  final formKey = GlobalKey<FormState>();

  MasterSubject? selectedMasterSubject = existing != null
      ? masterSubjects.firstWhere(
          (ms) => ms.name == existing.name,
          orElse: () => masterSubjects.first,
        )
      : null;

  TimeOfDay? start, end;

  if (existing != null && existing.time.contains('-')) {
    try {
      final times = existing.time.split('-').map((t) => t.trim()).toList();
      final startParts = times[0].split(':');
      final endParts = times[1].split(':');

      start = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
      end = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
    } catch (e) {
      debugPrint('Error parsing time string "${existing.time}": $e');
    }
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
                // Dropdown for selecting Master Subject
                DropdownButtonFormField<MasterSubject>(
                  value: selectedMasterSubject,
                  items: masterSubjects
                      .map((ms) => DropdownMenuItem(
                            value: ms,
                            child: Text(ms.name),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedMasterSubject = val),
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (v) =>
                      v == null ? 'Please select a subject' : null,
                ),
                const SizedBox(height: 12),
                // Start Time Picker
                ListTile(
                  title: Text(start != null
                      ? 'Start: ${start!.format(context)}'
                      : 'Select Start Time'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: start ?? TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => start = picked);
                  },
                ),
                // End Time Picker
                ListTile(
                  title: Text(end != null
                      ? 'End: ${end!.format(context)}'
                      : 'Select End Time'),
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
                // Validation: check if the form is valid and both start and end times are selected
                if (!formKey.currentState!.validate() || start == null || end == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please complete all fields')),
                  );
                  return;
                }

                // Prepare the Subject object
                final subject = Subject(
                  id: existing?.id,
                  name: selectedMasterSubject!.name,
                  time: '${start!.format(context)} - ${end!.format(context)}',
                  day: weekday.toString(),
                  status: 'Scheduled',
                  date: '', // For timetable date
                );

                if (existing == null) {
                  // Insert new subject if none exists
                  await db.insertSubject(subject);
                } else {
                  // Update existing subject if it's an edit
                  await db.updateSubject(subject);
                }

                // Optionally add to today’s home screen if it’s today
                final today = DateTime.now();
                if (weekday == today.weekday && existing == null) {
                  final todaySubject = Subject(
                    id: null,
                    name: subject.name,
                    time: subject.time,
                    day: '',
                    status: 'Scheduled',
                    date: '${today.year.toString().padLeft(4, '0')}-'
                          '${today.month.toString().padLeft(2, '0')}-'
                          '${today.day.toString().padLeft(2, '0')}',
                  );
                  await db.insertSubject(todaySubject);
                }

                // Trigger a refresh for the home screen
                refreshHomeScreen();

                // Close the dialog with success
                Navigator.of(ctx).pop(true);
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    ),
  ).then((val) => val ?? false);
}
