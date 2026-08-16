import 'dart:async';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/alarm_service.dart';
import 'services/location_service.dart' as tracker;
import 'screens/dashboard_screen.dart';
import 'screens/reminder_list_screen.dart';
import 'screens/live_tracking_screen.dart';
import 'screens/daily_summary_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reminder_alert_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmService.init();
  runApp(const AcTrackerApp());
}

class AcTrackerApp extends StatelessWidget {
  const AcTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AC Field Tracker',
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  StreamSubscription? _ringSub;

  final _screens = const [
    DashboardScreen(),
    ReminderListScreen(),
    LiveTrackingScreen(),
    DailySummaryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Whenever a scheduled alarm starts ringing, jump to the full-screen
    // alert regardless of which tab is currently open.
    _ringSub = AlarmService.onRing((reminderId) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => ReminderAlertScreen(reminderId: reminderId)),
      );
    });
    _setupLocationTracking();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the initial tracker start failed (Android only allows foreground
    // service starts while the app is in the foreground), quietly retry
    // whenever the app becomes active again.
    if (state == AppLifecycleState.resumed) {
      _retryLocationTracking();
    }
  }

  Future<void> _retryLocationTracking() async {
    if (await tracker.hasLocationPermissions()) {
      await tracker.startLocationTracking();
    }
  }

  // Runs once at app launch: asks for location permission, then starts
  // the all-day background tracker. This is what makes tracking
  // "automatic" per the original requirement — the AC never has to open
  // the Track tab or press a button for it to run.
  Future<void> _setupLocationTracking() async {
    final granted = await tracker.requestLocationPermissions();
    if (granted) {
      await tracker.startLocationTracking();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Background location permission not granted — visit tracking is off. '
            'Enable "Allow all the time" in system settings, or use the Track tab to retry.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ringSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Reminders'),
          NavigationDestination(icon: Icon(Icons.location_on_outlined), selectedIcon: Icon(Icons.location_on), label: 'Track'),
          NavigationDestination(icon: Icon(Icons.summarize_outlined), selectedIcon: Icon(Icons.summarize), label: 'Summary'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
