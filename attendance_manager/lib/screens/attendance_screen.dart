// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';

class AttendanceScreen extends StatefulWidget {
  final String date; // 'all' or 'yyyy-MM-dd'
  const AttendanceScreen({super.key, required this.date});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  void _refreshStats() {
    final db = Provider.of<DatabaseHelper>(context, listen: false);
    if (widget.date == 'all') {
      _statsFuture = db.getAttendanceStatsAll().then((list) {
        int total = 0, attended = 0, missed = 0, cancelled = 0;
        for (var row in list) {
          total += row['total'] as int;
          attended += row['attended'] as int;
          missed += row['missed'] as int;
          cancelled += row['cancelled'] as int;
        }
        return {
          'total': total,
          'attended': attended,
          'missed': missed,
          'cancelled': cancelled,
          'subjectStats': db.getSubjectWiseStats()
        };
      }).then((valueFuture) async {
        final value = valueFuture;
        value['subjectStats'] = await (value['subjectStats'] as Future<List<dynamic>>);
        return value;
      });
    } else {
      _statsFuture = db.getAttendanceStats(widget.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Statistics')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final stats = snap.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummary(stats),
                const SizedBox(height: 20),
                _buildSubjectStats(stats['subjectStats']),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary(Map<String, dynamic> s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Overall Attendance',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('Total', s['total'].toString(), Colors.blue),
                _statItem('Attended', s['attended'].toString(), Colors.green),
                _statItem('Missed', s['missed'].toString(), Colors.red),
                _statItem('Cancelled', s['cancelled'].toString(), Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Center(child: Text(value, style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  Color _getColor(double pct) {
    if (pct >= 75) return Colors.green;
    if (pct >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSubjectStats(List<dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject-wise Stats',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...stats.map((row) {
          final name = row['name'] ?? 'Unnamed';
          final total = (row['total'] ?? 0) as int;
          final attended = (row['attended'] ?? 0) as int;
          final cancelled = (row['cancelled'] ?? 0) as int;
          final percentage = (row['percentage'] ?? 0.0) as double;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Attended: $attended / $total'),
                      Text('Cancelled: $cancelled'),
                      Chip(
                        label: Text('${percentage.toStringAsFixed(1)}%'),
                        backgroundColor: _getColor(percentage).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _getColor(percentage),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}