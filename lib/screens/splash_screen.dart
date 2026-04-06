import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
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
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(FarmLensConstants.prefKeyBaseUrl) ?? '';
    if (!mounted) return;
    if (url.isNotEmpty) {
      context.go('/main');
    } else {
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