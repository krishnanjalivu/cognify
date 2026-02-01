import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app_theme.dart';
import '../models/cogniaware_record.dart';
import 'preferences_service.dart';

/// Local, on-device notifications: trend alerts, preventive tips, active task reminders.
/// Non-alarming, motivational, color-coded by risk (green / yellow / orange).
class NotificationsService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'cogniaware_alerts',
    'Cogniaware Alerts',
    description: 'Trend alerts, preventive tips, and activity reminders',
    importance: Importance.low,
    playSound: false,
  );

  /// Recent in-app items (alerts, tips, reminders) for the Notifications screen.
  static final List<NotificationItem> recentItems = [];

  /// User preferences (in production, persist with SharedPreferences).
  static bool trendAlertsEnabled = true;
  static bool preventiveTipsEnabled = true;
  static bool voiceRemindersEnabled = true;
  static bool typingRemindersEnabled = true;

  /// Throttle: only evaluate trend and notify at most once per 24h.
  static DateTime? lastTrendEvalAt;
  static const Duration trendEvalThrottle = Duration(hours: 24);

  /// Initialize plugin. Call from main() after WidgetsFlutterBinding.
  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  static void _onTap(NotificationResponse response) {
    // Optional: navigate to Dashboard or specific tab when notification is tapped.
  }

  /// Request permission (iOS). Call when user enables notifications in Settings.
  static Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios == null) return true;
    final result = await ios.requestPermissions(
      alert: true,
      badge: false,
      sound: false,
    );
    return result ?? false;
  }

  /// Show a trend alert when index deviates from baseline.
  static Future<void> showTrendAlert({
    required String title,
    required String body,
    required CogniawareRiskLevel level,
  }) async {
    if (!trendAlertsEnabled) return;
    await _show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      payload: 'trend',
    );
    recentItems.insert(
      0,
      NotificationItem(
        type: NotificationType.trendAlert,
        title: title,
        body: body,
        riskLevel: level,
        at: DateTime.now(),
      ),
    );
    _trimRecent(50);
  }

  /// Show a preventive / improvement tip (walking, cognitive, voice).
  static Future<void> showPreventiveTip({
    required String title,
    required String body,
  }) async {
    if (!preventiveTipsEnabled) return;
    await _show(
      id: 1000 + DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      payload: 'tip',
    );
    recentItems.insert(
      0,
      NotificationItem(
        type: NotificationType.preventiveTip,
        title: title,
        body: body,
        riskLevel: null,
        at: DateTime.now(),
      ),
    );
    _trimRecent(50);
  }

  /// Remind user to do a voice exercise.
  static Future<void> showVoiceReminder() async {
    if (!voiceRemindersEnabled) return;
    await _show(
      id: 2000 + DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Voice exercise',
      body: 'A quick voice task can help track cognitive wellness. Tap to open.',
      payload: 'voice',
    );
    recentItems.insert(
      0,
      NotificationItem(
        type: NotificationType.voiceReminder,
        title: 'Voice exercise',
        body: 'Reminder to complete a voice task.',
        riskLevel: null,
        at: DateTime.now(),
      ),
    );
    _trimRecent(50);
  }

  /// Remind user to do a typing task.
  static Future<void> showTypingReminder() async {
    if (!typingRemindersEnabled) return;
    await _show(
      id: 3000 + DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Typing check-in',
      body: 'A short typing task helps monitor motor and rhythm patterns. Tap to open.',
      payload: 'typing',
    );
    recentItems.insert(
      0,
      NotificationItem(
        type: NotificationType.typingReminder,
        title: 'Typing check-in',
        body: 'Reminder to complete a typing task.',
        riskLevel: null,
        at: DateTime.now(),
      ),
    );
    _trimRecent(50);
  }

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const android = AndroidNotificationDetails(
      'cogniaware_alerts',
      'Cogniaware Alerts',
      channelDescription: 'Trend alerts and reminders',
      importance: Importance.low,
      priority: Priority.low,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
  }

  static void _trimRecent(int max) {
    if (recentItems.length > max) {
      recentItems.removeRange(max, recentItems.length);
    }
  }

  /// Evaluate recent records and show a trend alert if deviation from baseline.
  /// Throttled to at most once per [trendEvalThrottle].
  static Future<void> evaluateTrendAndNotify(
    List<CogniawareRecord> records,
  ) async {
    if (records.length < 3) return;
    final now = DateTime.now();
    if (lastTrendEvalAt != null &&
        now.difference(lastTrendEvalAt!).compareTo(trendEvalThrottle) < 0) {
      return;
    }
    lastTrendEvalAt = now;
    final recent = records.length >= 14
        ? records.sublist(records.length - 14)
        : records;
    final avg = recent.map((r) => r.cogniawareIndex).reduce((a, b) => a + b) /
        recent.length;
    final latest = records.last.cogniawareIndex;
    final diff = latest - avg;
    final level = CogniawareTheme.riskLevelForIndex(latest);

    if (diff < -8) {
      await showTrendAlert(
        title: 'Slight dip in Cogniaware Index',
        body: 'Your recent index is below your 2-week average. Keep up with light walking and routines—small steps help.',
        level: level,
      );
    } else if (diff > 8) {
      await showTrendAlert(
        title: 'Cogniaware Index trending up',
        body: 'Your recent index is above your average. Nice progress.',
        level: CogniawareRiskLevel.stable,
      );
    }
  }

  /// Sync in-memory toggles from persisted preferences. Call from main() after init.
  static Future<void> syncFromPreferences() async {
    trendAlertsEnabled = await PreferencesService.getTrendAlertsEnabled();
    preventiveTipsEnabled = await PreferencesService.getPreventiveTipsEnabled();
    voiceRemindersEnabled = await PreferencesService.getVoiceRemindersEnabled();
    typingRemindersEnabled = await PreferencesService.getTypingRemindersEnabled();
  }

  /// If app is opened after user's reminder time today and we haven't shown yet, show daily reminder.
  /// Call from MainShell or Dashboard when app resumes.
  static Future<void> checkAndShowDailyReminderIfNeeded() async {
    if (!voiceRemindersEnabled && !typingRemindersEnabled) return;
    final hour = await PreferencesService.getReminderHour();
    final minute = await PreferencesService.getReminderMinute();
    final lastShown = await PreferencesService.getLastDailyReminderDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (lastShown != null && lastShown == today) return;
    final reminderToday = DateTime(now.year, now.month, now.day, hour, minute);
    if (now.isBefore(reminderToday)) return;
    await PreferencesService.setLastDailyReminderDate(today);
    if (voiceRemindersEnabled) {
      await showVoiceReminder();
    } else if (typingRemindersEnabled) {
      await showTypingReminder();
    }
  }
}

enum NotificationType {
  trendAlert,
  preventiveTip,
  voiceReminder,
  typingReminder,
}

class NotificationItem {
  final NotificationType type;
  final String title;
  final String body;
  final CogniawareRiskLevel? riskLevel;
  final DateTime at;

  NotificationItem({
    required this.type,
    required this.title,
    required this.body,
    this.riskLevel,
    required this.at,
  });
}
