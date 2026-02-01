import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'screens/main_shell.dart';
import 'services/notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationsService.initialize();
  await NotificationsService.syncFromPreferences();
  runApp(const CogniawareApp());
}

class CogniawareApp extends StatelessWidget {
  const CogniawareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cogniaware',
      theme: getCogniawareMaterialTheme(),
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}
