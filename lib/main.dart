import 'package:flutter/material.dart';

import 'screens/root_screen.dart';
import 'services/repository.dart';
import 'services/widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await Repository.open();
  await WidgetService.registerCallback();
  await WidgetService.sync(
      repository.loadShifts(), repository.loadSettings().roundingMinutes);
  runApp(ShiftTrackerApp(repository: repository));
}

class ShiftTrackerApp extends StatelessWidget {
  final Repository repository;
  const ShiftTrackerApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4F46E5);
    return MaterialApp(
      title: 'Shift Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: RootScreen(repository: repository),
    );
  }
}
