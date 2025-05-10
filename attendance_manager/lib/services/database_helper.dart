import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subject.dart';
import '../models/master_subject.dart';

class DatabaseHelper {
  static const _databaseName = 'attendance.db';
  static const _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    return await openDatabase(path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(''' 
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        day TEXT NOT NULL,
        time TEXT NOT NULL,
        status TEXT NOT NULL,
        date TEXT NOT NULL
      );
    ''');

    await db.execute(''' 
      CREATE TABLE master_subjects (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT NOT NULL
      );
    ''');
  }

  // ---------------- Subjects ----------------

  Future<int> insertSubject(Subject subject) async {
    final db = await database;
    return db.insert('subjects', subject.toMap());
  }

  Future<int> updateSubjectStatus(int id, String newStatus) async {
    final db = await database;
    return db.update(
      'subjects',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Subject>> getSubjectsForDay(String weekday) async {
    final db = await database;
    final result = await db.query(
      'subjects',
      where: 'day = ?',
      whereArgs: [weekday],
    );
    return result.map((e) => Subject.fromMap(e)).toList();
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await database;
    return db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<int> deleteSubject(int id) async {
    final db = await database;
    return db.delete(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Subject>> getAllSubjects() async {
    final db = await database;
    final maps = await db.query('subjects');
    return maps.map((m) => Subject.fromMap(m)).toList();
  }

  Future<List<Subject>> getSubjectsByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'subjects',
      where: 'date = ?',
      whereArgs: [date],
    );
    return maps.map((m) => Subject.fromMap(m)).toList();
  }

  Future<Subject?> getSubjectById(int id) async {
    final db = await database;
    final maps = await db.query(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Subject.fromMap(maps.first);
    } else {
      return null;
    }
  }

  /// ✅ FIXED: Cancelling no longer increases total count
  Future<List<Map<String, dynamic>>> getSubjectWiseStats() async {
    final db = await database;
    final rows = await db.rawQuery(''' 
      SELECT name,
             SUM(CASE WHEN status IN ('Attended', 'Missed') THEN 1 ELSE 0 END) as total,
             SUM(CASE WHEN status = 'Attended' THEN 1 ELSE 0 END) as attended,
             SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) as cancelled
      FROM subjects
      WHERE status IN ('Attended', 'Missed', 'Cancelled') AND date IS NOT NULL AND date != ''
      GROUP BY name
    ''');

    return rows.map((row) {
      final total = row['total'] as int;
      final attended = row['attended'] as int;
      final cancelled = row['cancelled'] as int? ?? 0;
      final percentage = total == 0 ? 0.0 : (attended / total) * 100;
      return {
        'name': row['name'],
        'total': total,
        'attended': attended,
        'cancelled': cancelled,
        'percentage': percentage,
      };
    }).toList();
  }

  // ---------------- Master Subjects ----------------

  Future<int> insertMasterSubject(MasterSubject ms) async {
    final db = await database;
    return db.insert('master_subjects', ms.toMap());
  }

  Future<List<MasterSubject>> getAllMasterSubjects() async {
    final db = await database;
    final maps = await db.query('master_subjects');
    return maps.map((m) => MasterSubject.fromMap(m)).toList();
  }

  Future<int> updateMasterSubject(MasterSubject ms) async {
    final db = await database;
    return db.update(
      'master_subjects',
      ms.toMap(),
      where: 'id = ?',
      whereArgs: [ms.id],
    );
  }

  Future<int> deleteMasterSubject(int id) async {
    final db = await database;
    return db.delete(
      'master_subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- Daily Schedule ----------------

  Future<void> generateTodayScheduleIfNeeded(String todayDate, int weekday) async {
    final db = await database;
    final existing = await db.query(
      'subjects',
      where: 'date = ?',
      whereArgs: [todayDate],
    );
    if (existing.isNotEmpty) return;

    final todayDay = _getDayFromWeekday(weekday);
    final masters = await db.query(
      'master_subjects',
    );

    final batch = db.batch();
    for (var m in masters) {
      final master = MasterSubject.fromMap(m);
      final subjectDay = master.description.trim().split('|').first;
      final subjectTime = master.description.trim().split('|').last;
      if (subjectDay == todayDay) {
        batch.insert('subjects', {
          'name': master.name,
          'day': subjectDay,
          'time': subjectTime,
          'status': 'Pending',
          'date': todayDate,
        });
      }
    }
    await batch.commit();
  }

  String _getDayFromWeekday(int w) {
    switch (w) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  // ---------------- Missed Classes ----------------

  Future<void> autoMarkMissedClasses(String date) async {
    final db = await database;
    final rows = await db.query(
      'subjects',
      where: 'date < ? AND status = ?',
      whereArgs: [date, 'Pending'],
    );
    for (var row in rows) {
      await updateSubjectStatus(row['id'] as int, 'Missed');
    }
  }

  Future<void> autoMarkMissedClassesAll() async {
    final db = await database;
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await db.query(
      'subjects',
      where: 'date < ? AND status = ?',
      whereArgs: [todayKey, 'Pending'],
    );
    for (var row in rows) {
      await updateSubjectStatus(row['id'] as int, 'Missed');
    }
  }

  // ---------------- Attendance Stats ----------------

  /// ✅ FIXED: Stats now EXCLUDE 'Cancelled' from total and percentage
  Future<Map<String, dynamic>> getAttendanceStats(String date) async {
    final db = await database;

    final attendedCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM subjects WHERE date = ? AND status = ?',
      [date, 'Attended'],
    ))!;
    final missedCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM subjects WHERE date = ? AND status = ?',
      [date, 'Missed'],
    ))!;
    final cancelledCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM subjects WHERE date = ? AND status = ?',
      [date, 'Cancelled'],
    ))!;
    final totalCount = attendedCount + missedCount;

    final rows = await db.rawQuery(''' 
      SELECT name,
             SUM(CASE WHEN status IN ('Attended', 'Missed') THEN 1 ELSE 0 END) as total,
             SUM(CASE WHEN status='Attended' THEN 1 ELSE 0 END) as attended
      FROM subjects
      WHERE date = ? AND status IN ('Attended','Missed','Cancelled')
      GROUP BY name
    ''', [date]);

    final subjectStats = rows.map((r) {
      final t = r['total'] as int;
      final a = r['attended'] as int;
      final pct = t == 0 ? 0.0 : (a / t) * 100;
      return {'name': r['name'], 'total': t, 'attended': a, 'percentage': pct};
    }).toList();

    return {
      'total': totalCount,
      'attended': attendedCount,
      'missed': missedCount,
      'cancelled': cancelledCount,
      'subjectStats': subjectStats,
    };
  }

  /// ✅ FIXED: Excludes 'Cancelled' from total in overall stats
  Future<List<Map<String, dynamic>>> getAttendanceStatsAll() async {
    final db = await database;
    final rows = await db.rawQuery(''' 
      SELECT
        date,
        SUM(CASE WHEN status = 'Attended' THEN 1 ELSE 0 END) AS attended,
        SUM(CASE WHEN status = 'Missed' THEN 1 ELSE 0 END) AS missed,
        SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled
      FROM subjects
      WHERE status IN ('Attended', 'Missed', 'Cancelled')
      GROUP BY date
      ORDER BY date DESC
    ''');

    return rows.map((r) {
      final attended = r['attended'] as int? ?? 0;
      final missed = r['missed'] as int? ?? 0;
      final cancelled = r['cancelled'] as int? ?? 0;
      final total = attended + missed;
      return {
        'date': r['date'],
        'total': total,
        'attended': attended,
        'missed': missed,
        'cancelled': cancelled,
      };
    }).toList();
  }
}
