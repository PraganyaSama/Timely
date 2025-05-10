// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subject.dart';
import '../services/database_helper.dart';

typedef OnStatusChanged = Future<void> Function(Subject subj, String newStatus);

class ClassCard extends StatelessWidget {
  final Subject subject;
  final OnStatusChanged onStatusChanged;

  const ClassCard({
    super.key,
    required this.subject,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            subject.name,
            style: TextStyle(
              fontSize: 16,
              decoration: subject.status == 'Cancelled'
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject.time),
              if (subject.date != DateFormat('yyyy-MM-dd').format(DateTime.now()))
                Text(
                  DateFormat('MMM dd, yyyy').format(
                    DateFormat('yyyy-MM-dd').parse(subject.date),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          trailing: _StatusIndicator(
            status: subject.status,
            onTap: () => _handleStatusChange(context),
          ),
        ),
      ),
    );
  }

  Future<void> _handleStatusChange(BuildContext context) async {
    try {
      final newStatus = await showModalBottomSheet<String>(
        context: context,
        builder: (_) =>
            _StatusSelectionSheet(currentStatus: subject.status),
      );

      if (newStatus != null && newStatus != subject.status) {
        await DatabaseHelper.instance
            .updateSubjectStatus(subject.id!, newStatus);
        await onStatusChanged(subject, newStatus);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete'),
            onTap: () async {
              Navigator.pop(ctx); // Close bottom sheet
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: const Text('Are you sure you want to delete this class?'),
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
                await DatabaseHelper.instance.deleteSubject(subject.id!);
                await onStatusChanged(subject, subject.status);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String status;
  final VoidCallback onTap;

  const _StatusIndicator({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _statusColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _statusColor),
        ),
        child: Text(
          status,
          style: TextStyle(color: _statusColor),
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (status) {
      case 'Attended':
        return Colors.green;
      case 'Missed':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}

class _StatusSelectionSheet extends StatelessWidget {
  final String currentStatus;

  const _StatusSelectionSheet({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Change Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...['Attended', 'Missed', 'Cancelled'].map((status) => ListTile(
              title: Text(status),
              trailing: status == currentStatus
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => Navigator.pop(context, status),
            )),
      ],
    );
  }
}
