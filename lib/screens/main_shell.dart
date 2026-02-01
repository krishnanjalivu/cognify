import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/notifications_service.dart';
import 'dashboard_screen.dart';
import 'gait_metrics_screen.dart';
import 'typing_metrics_screen.dart';
import 'voice_metrics_screen.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

/// Bottom navigation: Home, Gait, Typing, Voice, Reports, Alerts, Settings.
/// Modern 7-item nav matching the design.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationsService.checkAndShowDailyReminderIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationsService.checkAndShowDailyReminderIfNeeded();
    }
  }

  static const List<Widget> _screens = [
    DashboardScreen(),
    GaitMetricsScreen(),
    TypingMetricsScreen(),
    VoiceMetricsScreen(),
    ReportsScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: CogniawareTheme.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _navItem(1, Icons.show_chart_outlined, Icons.show_chart, 'Gait'),
                _navItem(2, Icons.keyboard_outlined, Icons.keyboard, 'Typing'),
                _navItem(3, Icons.mic_none_outlined, Icons.mic, 'Voice'),
                _navItem(4, Icons.description_outlined, Icons.description, 'Reports'),
                _navItem(5, Icons.notifications_outlined, Icons.notifications, 'Alerts'),
                _navItem(6, Icons.settings_outlined, Icons.settings, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData iconOutlined, IconData iconFilled, String label) {
    final selected = _index == i;
    return InkWell(
      onTap: () => setState(() => _index = i),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? iconFilled : iconOutlined,
              size: 24,
              color: selected ? CogniawareTheme.primary : CogniawareTheme.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? CogniawareTheme.primary : CogniawareTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
