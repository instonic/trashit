import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trashit/l10n/app_localizations_simple.dart';
import 'package:trashit/widgets/brand_logo.dart';
import 'package:trashit/screens/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Lightweight delay to show the brand; main initialization happens in main.dart
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizationsSimple.of(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TrashitCompleteLogo(height: 80),
            const SizedBox(height: 16),
            Text(
              'TRASHIT',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHigh,
              minHeight: 4,
            ),
          ],
        ),
      ),
    );
  }
}
