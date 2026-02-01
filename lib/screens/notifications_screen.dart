import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/notifications_service.dart';
import '../widgets/cogniaware_app_bar.dart';

/// Notifications hub: trend alerts, preventive tips, voice/typing reminders.
/// Toggles for each type; list of recent items. Non-alarming, motivational.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    NotificationsService.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);

    return Scaffold(
      backgroundColor: CogniawareTheme.surface,
      appBar: const CogniawareAppBar(title: 'Cogniaware'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Cogniaware sends only local notifications: trend alerts when your index changes, preventive tips, and optional reminders for voice and typing tasks. All evaluation is on-device.',
            style: theme.body,
          ),
          const SizedBox(height: 24),
          Text('Settings', style: theme.subtitle1),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await NotificationsService.showPreventiveTip(
                title: 'Stay active',
                body: 'A short walk can help maintain gait stability and cognitive wellness.',
              );
              setState(() {});
            },
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Send test tip'),
          ),
          const SizedBox(height: 16),
          _SwitchTile(
            title: 'Trend alerts',
            subtitle: 'Notify when Cogniaware Index deviates from your baseline',
            value: NotificationsService.trendAlertsEnabled,
            onChanged: (v) {
              setState(() => NotificationsService.trendAlertsEnabled = v);
            },
          ),
          _SwitchTile(
            title: 'Preventive tips',
            subtitle: 'Encourage walking, cognitive exercises, voice practice',
            value: NotificationsService.preventiveTipsEnabled,
            onChanged: (v) {
              setState(() => NotificationsService.preventiveTipsEnabled = v);
            },
          ),
          _SwitchTile(
            title: 'Voice exercise reminders',
            subtitle: 'Remind to complete scheduled voice tasks',
            value: NotificationsService.voiceRemindersEnabled,
            onChanged: (v) {
              setState(() => NotificationsService.voiceRemindersEnabled = v);
            },
          ),
          _SwitchTile(
            title: 'Typing task reminders',
            subtitle: 'Remind to complete typing check-ins',
            value: NotificationsService.typingRemindersEnabled,
            onChanged: (v) {
              setState(() => NotificationsService.typingRemindersEnabled = v);
            },
          ),
          const SizedBox(height: 24),
          Text('Preventive tips', style: theme.subtitle1),
          const SizedBox(height: 8),
          _TipCard(
            icon: Icons.directions_walk,
            title: 'Walking & exercise',
            body: 'Regular walking supports gait stability and cognitive health. Try a short walk when you see this tip.',
            color: CogniawareTheme.riskStable,
          ),
          _TipCard(
            icon: Icons.psychology,
            title: 'Cognitive exercises',
            body: 'Typing, language tasks, and puzzles can help maintain motor and language patterns.',
            color: CogniawareTheme.riskModerate,
          ),
          _TipCard(
            icon: Icons.record_voice_over,
            title: 'Voice exercises',
            body: 'Reading a short sentence or speaking a phrase when prompted helps track language and rhythm.',
            color: CogniawareTheme.riskIncreased,
          ),
          const SizedBox(height: 24),
          Text('Recent', style: theme.subtitle1),
          const SizedBox(height: 8),
          if (NotificationsService.recentItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No notifications yet. Alerts and tips will appear here and in the system tray when enabled.',
                style: theme.caption,
              ),
            )
          else
            ...NotificationsService.recentItems.take(20).map((item) =>
                _NotificationTile(item: item)),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    return Card(
      elevation: 0,
      color: CogniawareTheme.surfaceLight,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CogniawareTheme.divider),
      ),
      child: SwitchListTile(
        title: Text(title, style: theme.subtitle1),
        subtitle: Text(subtitle, style: theme.caption),
        value: value,
        onChanged: onChanged,
        activeTrackColor: CogniawareTheme.primary.withValues(alpha: 0.5),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.subtitle1?.copyWith(color: color)),
                  const SizedBox(height: 4),
                  Text(body, style: theme.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    Color? color;
    IconData icon = Icons.notifications_none;
    if (item.type == NotificationType.trendAlert && item.riskLevel != null) {
      final theme = CogniawareTheme.of(context);
      color = theme.riskColor(item.riskLevel!);
    }
    switch (item.type) {
      case NotificationType.trendAlert:
        icon = Icons.trending_up;
        break;
      case NotificationType.preventiveTip:
        icon = Icons.lightbulb_outline;
        break;
      case NotificationType.voiceReminder:
        icon = Icons.record_voice_over;
        break;
      case NotificationType.typingReminder:
        icon = Icons.keyboard;
        break;
    }
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: CogniawareTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: CogniawareTheme.divider),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? CogniawareTheme.primary, size: 24),
        title: Text(item.title, style: theme.body?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          item.body,
          style: theme.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatDate(item.at),
          style: theme.caption,
        ),
      ),
    );
  }

  String _formatDate(DateTime at) {
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${at.month}/${at.day}';
  }
}
