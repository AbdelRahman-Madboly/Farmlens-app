import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Small visual delay so the splash is visible
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Wait for SettingsProvider to finish loading from SharedPreferences.
    // main.dart calls loadFromPrefs() at construction, but it's async —
    // we must not navigate until it resolves or the deviceBaseUrl will be
    // empty even when a URL was previously saved, causing the dashboard
    // to get stuck on the loading spinner forever.
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    // Poll up to 3 seconds for prefs to load (usually <50ms)
    int waited = 0;
    while (!settings.isConfigured && settings.deviceBaseUrl.isEmpty && waited < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited++;
      if (!mounted) return;
    }

    if (!mounted) return;

    if (settings.deviceBaseUrl.isNotEmpty) {
      // Previously saved URL found — go straight to dashboard
      context.go('/main');
    } else {
      // No saved URL — go to connection screen
      context.go('/connect');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: FarmLensColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_rounded,
              size: 72,
              color: FarmLensColors.primary,
            ),
            SizedBox(height: 16),
            Text(
              'FarmLens',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: FarmLensColors.primary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Edge AI Crop Monitoring',
              style: TextStyle(
                fontSize: 14,
                color: FarmLensColors.textSecondary,
              ),
            ),
            SizedBox(height: 40),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: FarmLensColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}