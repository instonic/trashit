import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:trashit/theme.dart';
import 'package:trashit/screens/splash_page.dart';
import 'package:trashit/firebase_options.dart';
import 'package:trashit/services/theme_service.dart';
import 'package:trashit/screens/privacy_policy_page.dart';
import 'package:trashit/screens/about_page.dart';
import 'package:trashit/screens/preferences_page.dart';
import 'package:trashit/l10n/app_localizations_simple.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path-based URLs on the web (no #) for clean routes and better SEO.
  // Safe on Firebase Hosting because rewrites to /index.html are configured.
  setUrlStrategy(PathUrlStrategy());

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Continue with the app even if Firebase fails to initialize
    // This is expected in mock/offline mode.
    // ignore: avoid_print
    print('Firebase initialization error: $e');
  }

  // Load theme preferences before building the app
  await ThemeService.instance.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        final svc = ThemeService.instance;
        return MaterialApp(
          title: 'Trashit - trashit.live',
          debugShowCheckedModeBanner: false,
          theme: themeFor(svc.variant, Brightness.light),
          darkTheme: themeFor(svc.variant, Brightness.dark),
          themeMode: svc.mode,
          locale: const Locale('en', 'US'),
          supportedLocales: AppLocalizationsSimple.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsSimple.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Support direct web deep links like /privacy and /about
          onGenerateRoute: (settings) {
            final name = settings.name ?? '/';
            if (name == '/' || name.isEmpty) {
              return MaterialPageRoute(builder: (_) => const SplashPage(), settings: settings);
            }
            if (name == '/privacy') {
              return MaterialPageRoute(builder: (_) => const PrivacyPolicyPage(), settings: settings);
            }
            if (name == '/about') {
              return MaterialPageRoute(builder: (_) => const AboutPage(), settings: settings);
            }
            if (name == '/preferences') {
              return MaterialPageRoute(builder: (_) => const PreferencesPage(), settings: settings);
            }
            // Fallback to Splash -> Home for unknown routes
            return MaterialPageRoute(builder: (_) => const SplashPage(), settings: settings);
          },
          initialRoute: '/',
        );
      },
    );
  }
}
