// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import '../models/master_subject.dart';

class AddSubjectDialog extends StatefulWidget {
  final MasterSubject? existingSubject;

  const AddSubjectDialog({this.existingSubject, super.key});

  @override
  _AddSubjectDialogState createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<AddSubjectDialog> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingSubject != null) {
      _nameCtrl.text = widget.existingSubject!.name;
      _codeCtrl.text = widget.existingSubject!.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingSubject == null ? 'Add Subject' : 'Edit Subject'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Subject Name'),
          ),
          TextField(
            controller: _codeCtrl,
            decoration: const InputDecoration(labelText: 'Subject Code'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final code = _codeCtrl.text.trim();

            if (name.isEmpty || code.isEmpty) return;

            final subject = MasterSubject(
              id: widget.existingSubject?.id, // Preserve ID if editing
              name: name,
              code: code,
              description: '', // Empty description since it's no longer used
            );

            Navigator.of(context).pop(subject);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
