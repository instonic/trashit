import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? get _analytics => Firebase.apps.isNotEmpty ? FirebaseAnalytics.instance : null;

  // Consent toggle (GA4 Consent Mode equivalent on client)
  static Future<void> setUserConsent({required bool consent}) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.setAnalyticsCollectionEnabled(consent);
  }

  // User properties (null clears the property)
  static Future<void> setUserProperty({required String name, String? value}) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.setUserProperty(name: name, value: value);
  }

  static Future<void> logVote({
    required String postId,
    required bool isRetrash,
    String? sourceTab, // 'recent' | 'trending'
    String? category, // optional coarse category/topic
    int? hashtagsCount,
  }) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logEvent(
      name: 'vote',
      parameters: {
        'post_id': postId,
        'action': isRetrash ? 'retrash' : 'untrash',
        if (sourceTab != null) 'source_tab': sourceTab,
        if (category != null) 'category': category,
        if (hashtagsCount != null) 'hashtags_count': hashtagsCount,
      },
    );
  }

  static Future<void> logUndo({
    required String postId,
    required bool isRetrash,
    String? sourceTab,
  }) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logEvent(
      name: 'vote_undo',
      parameters: {
        'post_id': postId,
        'action': isRetrash ? 'retrash' : 'untrash',
        if (sourceTab != null) 'source_tab': sourceTab,
      },
    );
  }

  static Future<void> logFlag({required String postId, required String reason}) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logEvent(
      name: 'flag_post',
      parameters: {
        'post_id': postId,
        'reason': reason,
      },
    );
  }

  static Future<void> logShare({
    required String postId,
    String? destination, // optional: whatsapp, message, copy, etc (best-effort)
  }) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.logEvent(
      name: 'share_post',
      parameters: {
        'post_id': postId,
        if (destination != null) 'destination': destination,
      },
    );
  }
}
