import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/timetable_screen.dart';
import 'screens/history_screen.dart'; // Removed the alias here
import 'screens/subject_manager_screen.dart';
import 'services/database_helper.dart';
import 'services/notification_service.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request permission for notifications before proceeding
  await _requestNotificationPermission();

  await DatabaseHelper.instance.database;
  await NotificationService().init();
  await _scheduleTodaysNotifications();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseHelper>.value(value: DatabaseHelper.instance),
        ChangeNotifierProvider(create: (_) => MyAppState()),
      ],
      child: const MyApp(),
    ),
  );
}

// Request permission to send notifications
Future<void> _requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  if (await Permission.notification.isGranted) {
    print("Notification Permission Granted");
  } else {
    print("Notification Permission Denied");
  }
}

Future<void> _scheduleTodaysNotifications() async {
  final db = DatabaseHelper.instance;
  final notif = NotificationService();
  final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final subjects = await db.getSubjectsByDate(todayKey);

  for (var s in subjects) {
    if (s.status != 'Pending') continue;

    final parts = s.time.split('-').map((t) => t.trim()).toList();
    if (parts.length != 2) continue;

    DateTime? end;
    try {
      end = DateFormat.jm().parseLoose(parts[1]);
    } catch (_) {
      try {
        end = DateFormat('HH:mm').parseLoose(parts[1]);
      } catch (_) {
        if (kDebugMode) print('Failed to parse time for subject: ${s.name}');
        continue;
      }
    }

    final now = DateTime.now();
    final endToday = DateTime(now.year, now.month, now.day, end.hour, end.minute);
    final notifyAt = endToday.subtract(const Duration(minutes: 5));

    if (notifyAt.isAfter(now)) {
      await notif.schedulePeriodEndNotification(
        id: s.id!,
        title: 'Class Ending: ${s.name}',
        body: 'Tap to mark attendance',
        scheduledDate: notifyAt,
        payload: 'subjectId:${s.id!}',
      );
    }
  }
}

class MyAppState with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  MyAppState() {
    _loadThemeFromPrefs();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark;
    }
    _saveThemeToPrefs();
    notifyListeners();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 1;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<MyAppState>(context);

    return MaterialApp(
      title: 'Timely',
      themeMode: themeProvider.themeMode,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      builder: (context, child) {
        ThemeData theme;
        if (themeProvider.themeMode == ThemeMode.system) {
          theme = _customTheme();
        } else {
          theme = themeProvider.themeMode == ThemeMode.dark
              ? _darkTheme()
              : _lightTheme();
        }
        return Theme(
          data: theme,
          child: child!,
        );
      },
      home: const MainWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _lightTheme() {
    return ThemeData.light().copyWith(
      colorScheme: ColorScheme.light(
        primary: Colors.deepPurpleAccent,
        secondary: Colors.tealAccent[200]!,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.grey,
        selectedIconTheme: IconThemeData(size: 26),
        unselectedIconTheme: IconThemeData(size: 22),
        showUnselectedLabels: true,
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.dark(
        primary: Colors.deepPurpleAccent,
        secondary: Colors.tealAccent[200]!,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.grey,
        selectedIconTheme: IconThemeData(size: 26),
        unselectedIconTheme: IconThemeData(size: 22),
        showUnselectedLabels: true,
      ),
    );
  }

  ThemeData _customTheme() {
    return ThemeData(
      primaryColor: const Color(0xFFF1E0C6),
      scaffoldBackgroundColor: const Color(0xFFF9F3E1),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFF1E0C6),
        secondary: Color(0xFFD5B99F),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.brown.shade800),
        bodyMedium: TextStyle(color: Colors.brown.shade600),
        headlineSmall: TextStyle(color: Colors.brown.shade900),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD5B99F),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFF9F3E1),
        selectedItemColor: Color(0xFFD5B99F),
        unselectedItemColor: Colors.grey,
        selectedIconTheme: IconThemeData(size: 26),
        unselectedIconTheme: IconThemeData(size: 22),
        showUnselectedLabels: true,
      ),
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  void _refreshHomeScreen() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const AttendanceScreen(date: 'all'),
      TimetableScreen(refreshHomeScreen: _refreshHomeScreen),
      const HistoryScreen(), // No alias needed here
      const SubjectManagerScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Timetable'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Manage'),
        ],
      ),
    );
  }
}
