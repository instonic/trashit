import 'package:flutter/material.dart';

/// Lightweight, build-time friendly localization without relying on gen-l10n.
/// Start with en (US). We can extend later by adding more maps.
class AppLocalizationsSimple {
  final Locale locale;
  AppLocalizationsSimple(this.locale);

  static const LocalizationsDelegate<AppLocalizationsSimple> delegate = _AppLocalizationsSimpleDelegate();

  static const supportedLocales = [
    Locale('en', 'US'),
  ];

  static AppLocalizationsSimple of(BuildContext context) {
    final l10n = Localizations.of<AppLocalizationsSimple>(context, AppLocalizationsSimple);
    assert(l10n != null, 'AppLocalizationsSimple not found in context');
    return l10n!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en_US': {
      'appTitle': 'Trashit - trashit.live',
      'tabRecent': 'Recent',
      'tabTrending': 'Trending',
      'quickComposerHint': 'Trash a link... (paste or type URL)',
      'mockPreview': 'Preview (Mock Data)',
      'addingToTrash': 'Adding to trash...'
    },
  };

  String _key(String key) {
    final tag = '${locale.languageCode}_${locale.countryCode ?? 'US'}';
    return _localizedValues[tag]?[key] ?? _localizedValues['en_US']![key] ?? key;
  }

  String get appTitle => _key('appTitle');
  String get tabRecent => _key('tabRecent');
  String get tabTrending => _key('tabTrending');
  String get quickComposerHint => _key('quickComposerHint');
  String get mockPreview => _key('mockPreview');
  String get addingToTrash => _key('addingToTrash');
}

class _AppLocalizationsSimpleDelegate extends LocalizationsDelegate<AppLocalizationsSimple> {
  const _AppLocalizationsSimpleDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizationsSimple.supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizationsSimple> load(Locale locale) async {
    // No async work required; values are in memory.
    return AppLocalizationsSimple(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizationsSimple> old) => false;
}
