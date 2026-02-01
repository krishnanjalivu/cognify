import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Blue header with "Cogniaware" and "Privacy First" pill. Modern, neat.
class CogniawareAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showPrivacyPill;

  const CogniawareAppBar({
    super.key,
    this.title = 'Cogniaware',
    this.actions,
    this.showPrivacyPill = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: CogniawareTheme.headerBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        if (showPrivacyPill)
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CogniawareTheme.headerBlueDark.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'Privacy First',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ...?actions,
      ],
    );
  }
}
