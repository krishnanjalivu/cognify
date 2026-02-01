import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user preferences: data source (dummy vs live sensors), reminder time, notification toggles.
class PreferencesService {
  static const _keyUseDummyData = 'use_dummy_data';
  static const _keyReminderHour = 'reminder_hour';
  static const _keyReminderMinute = 'reminder_minute';
  static const _keyTrendAlerts = 'trend_alerts_enabled';
  static const _keyPreventiveTips = 'preventive_tips_enabled';
  static const _keyVoiceReminders = 'voice_reminders_enabled';
  static const _keyTypingReminders = 'typing_reminders_enabled';
  static const _keyLastDailyReminderDate = 'last_daily_reminder_date';
  /// When true, do not auto-seed dummy data after user clears all data.
  static const _keySkipDummySeed = 'skip_dummy_seed';

  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Use dummy/simulated data when true; use live sensors when false.
  /// Default false so real step tracking is on when the app is installed.
  static Future<bool> getUseDummyData() async {
    final p = await _instance;
    return p.getBool(_keyUseDummyData) ?? false;
  }

  static Future<void> setUseDummyData(bool value) async {
    final p = await _instance;
    await p.setBool(_keyUseDummyData, value);
  }

  /// Daily reminder time (hour 0–23, minute 0–59). Default 9:00 AM.
  static Future<int> getReminderHour() async {
    final p = await _instance;
    return p.getInt(_keyReminderHour) ?? 9;
  }

  static Future<int> getReminderMinute() async {
    final p = await _instance;
    return p.getInt(_keyReminderMinute) ?? 0;
  }

  static Future<void> setReminderTime(int hour, int minute) async {
    final p = await _instance;
    await p.setInt(_keyReminderHour, hour.clamp(0, 23));
    await p.setInt(_keyReminderMinute, minute.clamp(0, 59));
  }

  static Future<bool> getTrendAlertsEnabled() async {
    final p = await _instance;
    return p.getBool(_keyTrendAlerts) ?? true;
  }

  static Future<void> setTrendAlertsEnabled(bool value) async {
    final p = await _instance;
    await p.setBool(_keyTrendAlerts, value);
  }

  static Future<bool> getPreventiveTipsEnabled() async {
    final p = await _instance;
    return p.getBool(_keyPreventiveTips) ?? true;
  }

  static Future<void> setPreventiveTipsEnabled(bool value) async {
    final p = await _instance;
    await p.setBool(_keyPreventiveTips, value);
  }

  static Future<bool> getVoiceRemindersEnabled() async {
    final p = await _instance;
    return p.getBool(_keyVoiceReminders) ?? true;
  }

  static Future<void> setVoiceRemindersEnabled(bool value) async {
    final p = await _instance;
    await p.setBool(_keyVoiceReminders, value);
  }

  static Future<bool> getTypingRemindersEnabled() async {
    final p = await _instance;
    return p.getBool(_keyTypingReminders) ?? true;
  }

  static Future<void> setTypingRemindersEnabled(bool value) async {
    final p = await _instance;
    await p.setBool(_keyTypingReminders, value);
  }

  /// Last date we showed the daily reminder (YYYY-MM-DD). Used to show at most one per day.
  static Future<DateTime?> getLastDailyReminderDate() async {
    final p = await _instance;
    final s = p.getString(_keyLastDailyReminderDate);
    if (s == null) return null;
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static Future<void> setLastDailyReminderDate(DateTime date) async {
    final p = await _instance;
    final s = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await p.setString(_keyLastDailyReminderDate, s);
  }

  /// When true, do not seed dummy data (user has cleared all data).
  static Future<bool> getSkipDummySeed() async {
    final p = await _instance;
    return p.getBool(_keySkipDummySeed) ?? false;
  }

  static Future<void> setSkipDummySeed(bool value) async {
    final p = await _instance;
    await p.setBool(_keySkipDummySeed, value);
  }
}
