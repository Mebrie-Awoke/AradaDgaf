import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce Portrait Orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final appState = AppState();

  runApp(
    AppScope(
      state: appState,
      child: const AradaDigafApp(),
    ),
  );
}

class AradaDigafApp extends StatelessWidget {
  const AradaDigafApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arada Digaf',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(isFirstLaunch: true),
    );
  }
}
