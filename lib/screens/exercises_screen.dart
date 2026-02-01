import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'voice_exercise_screen.dart';
import 'typing_exercise_screen.dart';

/// List of cognitive exercises: Voice and Typing. Tap to open.
class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);

    return Scaffold(
      backgroundColor: CogniawareTheme.surface,
      appBar: AppBar(title: const Text('Exercises')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Short exercises help track language, motor, and rhythm patterns. '
            'All processing is on-device; voice audio and typed content are not stored.',
            style: theme.caption,
          ),
          const SizedBox(height: 24),
          _ExerciseCard(
            icon: Icons.record_voice_over,
            title: 'Voice exercise',
            subtitle: 'Read a sentence aloud. We measure vocabulary and rhythm only; audio is discarded.',
            color: CogniawareTheme.riskStable,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VoiceExerciseScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _ExerciseCard(
            icon: Icons.keyboard,
            title: 'Typing exercise',
            subtitle: 'Type a short phrase. Only key timing is recorded—content is never stored.',
            color: CogniawareTheme.riskModerate,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TypingExerciseScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CogniawareTheme.of(context);
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.subtitle1?.copyWith(color: color, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.caption),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
