import 'package:flutter/material.dart';
import '../core/painters.dart';
import '../core/theme.dart';
import '../state/app_scope.dart';
import 'language_select_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool isFirstLaunch;

  const SplashScreen({super.key, this.isFirstLaunch = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final appState = AppScope.of(context);
    if (appState.currentUser != null) {
      // Already logged in
      return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, anim, secondaryAnim) => widget.isFirstLaunch
            ? const LanguageSelectScreen()
            : const LoginScreen(),
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Logo
            const Center(
              child: HeadsetScreenLogo(size: 96),
            ),
            const SizedBox(height: 20),
            // App Title bilingual
            Text(
              s.get('app_name'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            Text(
              s.getOther('app_name'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            Text(
              'Report. Track. Resolve.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withAlpha(200),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(flex: 2),
            // Circular progress spinner
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            // Addis Ababa Landmark Skyline at bottom
            const AddisSkyline(height: 150, showBottomWave: true),
          ],
        ),
      ),
    );
  }
}

