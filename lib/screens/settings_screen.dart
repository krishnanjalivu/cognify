import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/storage_service.dart';
import '../services/preferences_service.dart';
import '../services/notifications_service.dart';
import '../services/report_service.dart';
import '../widgets/cogniaware_app_bar.dart';

/// Settings: Data source (live vs dummy), Notifications, Data Management, About.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final _storage = StorageService();
  bool _useDummyData = true;
  int _reminderHour = 9;
  int _reminderMinute = 0;
  bool _trendAlerts = true;
  bool _preventiveTips = true;
  bool _voiceReminders = true;
  bool _typingReminders = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final useDummy = await PreferencesService.getUseDummyData();
    final hour = await PreferencesService.getReminderHour();
    final minute = await PreferencesService.getReminderMinute();
    final trend = await PreferencesService.getTrendAlertsEnabled();
    final tips = await PreferencesService.getPreventiveTipsEnabled();
    final voice = await PreferencesService.getVoiceRemindersEnabled();
    final typing = await PreferencesService.getTypingRemindersEnabled();
    if (mounted) {
      setState(() {
        _useDummyData = useDummy;
        _reminderHour = hour;
        _reminderMinute = minute;
        _trendAlerts = trend;
        _preventiveTips = tips;
        _voiceReminders = voice;
        _typingReminders = typing;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CogniawareTheme.surface,
      appBar: const CogniawareAppBar(title: 'Cogniaware'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SectionTitle(title: 'Data source'),
                _dataSourceCard(),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Notifications'),
                _notificationsCard(),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Data Management'),
                _dataManagementCard(),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Privacy'),
                _privacyCard(),
                const SizedBox(height: 24),
                _SectionTitle(title: 'About'),
                _aboutCard(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _dataSourceCard() {
    final theme = CogniawareTheme.of(context);
    return Card(
      elevation: 0,
      color: CogniawareTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CogniawareTheme.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: CogniawareTheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Use live sensors', style: theme.body?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        _useDummyData
                            ? 'Currently using simulated data for demo.'
                            : 'Using accelerometer & gyroscope for real step and gait data.',
                        style: theme.caption,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: !_useDummyData,
                  onChanged: (v) async {
                    await PreferencesService.setUseDummyData(!v);
                    if (!v) await PreferencesService.setSkipDummySeed(false);
                    if (!mounted) return;
                    setState(() => _useDummyData = !v);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(v
                            ? 'Live sensor mode on. Walk with your phone to see real steps.'
                            : 'Using demo data. Dummy data can be re-seeded if needed.'),
                      ),
                    );
                  },
                  activeTrackColor: CogniawareTheme.primary.withValues(alpha: 0.5),
                  activeThumbColor: CogniawareTheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationsCard() {
    final theme = CogniawareTheme.of(context);
    return Card(
      elevation: 0,
      color: CogniawareTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CogniawareTheme.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_outlined, color: CogniawareTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications', style: theme.subtitle1),
                      Text('Customize alert preferences.', style: theme.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _notificationSwitch('Trend Alerts', 'Pattern change notifications.', _trendAlerts, (v) async {
              await PreferencesService.setTrendAlertsEnabled(v);
              NotificationsService.trendAlertsEnabled = v;
              if (mounted) setState(() => _trendAlerts = v);
            }),
            _notificationSwitch('Daily Tips', 'Preventive health suggestions.', _preventiveTips, (v) async {
              await PreferencesService.setPreventiveTipsEnabled(v);
              NotificationsService.preventiveTipsEnabled = v;
              if (mounted) setState(() => _preventiveTips = v);
            }),
            _notificationSwitch('Exercise Reminders', 'Voice exercise prompts.', _voiceReminders, (v) async {
              await PreferencesService.setVoiceRemindersEnabled(v);
              NotificationsService.voiceRemindersEnabled = v;
              if (mounted) setState(() => _voiceReminders = v);
            }),
            _notificationSwitch('Typing Reminders', 'Typing check-in prompts.', _typingReminders, (v) async {
              await PreferencesService.setTypingRemindersEnabled(v);
              NotificationsService.typingRemindersEnabled = v;
              if (mounted) setState(() => _typingReminders = v);
            }),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Reminder Time', style: theme.body),
              trailing: Text(
                '${_reminderHour > 12 ? _reminderHour - 12 : _reminderHour == 0 ? 12 : _reminderHour}:${_reminderMinute.toString().padLeft(2, '0')} ${_reminderHour >= 12 ? 'PM' : 'AM'}',
                style: theme.subtitle1,
              ),
              onTap: () => _pickReminderTime(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    final theme = CogniawareTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.body?.copyWith(fontWeight: FontWeight.w500)),
                Text(subtitle, style: theme.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: CogniawareTheme.primary.withValues(alpha: 0.5),
            activeThumbColor: CogniawareTheme.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (picked == null) return;
    await PreferencesService.setReminderTime(picked.hour, picked.minute);
    if (!mounted) return;
    setState(() {
      _reminderHour = picked.hour;
      _reminderMinute = picked.minute;
    });
    final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    messenger.showSnackBar(
      SnackBar(content: Text('Daily reminder set for $timeStr')),
    );
  }

  Widget _dataManagementCard() {
    final theme = CogniawareTheme.of(context);
    return Card(
      elevation: 0,
      color: CogniawareTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CogniawareTheme.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage_outlined, color: CogniawareTheme.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data Management', style: theme.subtitle1),
                    Text('Control your stored information.', style: theme.caption),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export All Data'),
              onTap: () => _exportData(context),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: CogniawareTheme.riskIncreased),
              title: Text('Clear all data', style: TextStyle(color: CogniawareTheme.riskIncreased)),
              onTap: () => _showClearDataDialog(context),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: CogniawareTheme.riskIncreased),
              title: Text('Delete All Data', style: TextStyle(color: CogniawareTheme.riskIncreased)),
              onTap: () => _showDeleteAllDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final records = await _storage.getRecordsForDays(90);
      final result = await ReportService.generateReport(records: records, days: 90);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved to ${result.pdfPath}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Widget _privacyCard() {
    return Card(
      elevation: 0,
      color: CogniawareTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CogniawareTheme.divider),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PrivacyItem(
              icon: Icons.phone_android,
              title: 'On-device only',
              subtitle: 'All sensor and gait data is processed on your device. Raw data never leaves the phone.',
            ),
            _PrivacyItem(
              icon: Icons.storage,
              title: 'Local storage',
              subtitle: 'Only computed indices and trends are stored locally. No cloud sync.',
            ),
            _PrivacyItem(
              icon: Icons.psychology,
              title: 'ML on device',
              subtitle: 'Any future ML models (e.g. TensorFlow Lite) run locally. No server inference.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutCard() {
    return Card(
      elevation: 0,
      color: CogniawareTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CogniawareTheme.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Cogniaware'),
              subtitle: const Text('Version 1.0.0 · Last updated Feb 2026'),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Documentation'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will permanently delete all stored Cogniaware Index and trend history. '
          'The app will use only real sensor data from now on. Pull down on Home to refresh.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _storage.clearAll();
              await PreferencesService.setSkipDummySeed(true);
              await PreferencesService.setUseDummyData(false);
              if (context.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                await _loadPrefs();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared. Using real sensors only. Pull down on Home to refresh.'),
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'This will permanently delete all stored data. The app will use only real sensor data.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _storage.clearAll();
              await PreferencesService.setSkipDummySeed(true);
              await PreferencesService.setUseDummyData(false);
              if (context.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                await _loadPrefs();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared. Using real sensors only.')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: CogniawareTheme.riskIncreased)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: theme.subtitle1),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: CogniawareTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.body?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
