import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Card placeholder for future features (typing metrics, language, behavioral).
class PlaceholderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const PlaceholderCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.insights,
  });

  @override
  Widget build(BuildContext context) {
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
              color: CogniawareTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: CogniawareTheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: theme.subtitle1),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.lock_outline, size: 18, color: CogniawareTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
