import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashit/services/analytics_service.dart';

class UserProfileService {
  UserProfileService._();

  // Keys
  static const _kConsentAnalytics = 'consent_analytics';
  static const _kConsentDemographics = 'consent_demographics';
  static const _kAgeBand = 'profile_age_band';
  static const _kGender = 'profile_gender';
  static const _kRegion = 'profile_region';

  // Model
  static Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      analyticsConsent: prefs.getBool(_kConsentAnalytics) ?? false,
      demographicsConsent: prefs.getBool(_kConsentDemographics) ?? false,
      ageBand: prefs.getString(_kAgeBand),
      gender: prefs.getString(_kGender),
      region: prefs.getString(_kRegion),
    );
  }

  static Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kConsentAnalytics, profile.analyticsConsent);
    await prefs.setBool(_kConsentDemographics, profile.demographicsConsent);
    if (profile.ageBand?.isNotEmpty == true) {
      await prefs.setString(_kAgeBand, profile.ageBand!);
    } else {
      await prefs.remove(_kAgeBand);
    }
    if (profile.gender?.isNotEmpty == true) {
      await prefs.setString(_kGender, profile.gender!);
    } else {
      await prefs.remove(_kGender);
    }
    if (profile.region?.isNotEmpty == true) {
      await prefs.setString(_kRegion, profile.region!);
    } else {
      await prefs.remove(_kRegion);
    }

    // Push to analytics if available and consented
    await applyToAnalytics(profile);
  }

  static Future<void> applyToAnalytics(UserProfile profile) async {
    // Set consent as a user property to allow GA4 consent mode filters
    await AnalyticsService.setUserConsent(consent: profile.analyticsConsent);

    if (profile.analyticsConsent) {
      await AnalyticsService.setUserProperty(name: 'age_band', value: profile.demographicsConsent ? profile.ageBand : null);
      await AnalyticsService.setUserProperty(name: 'gender', value: profile.demographicsConsent ? profile.gender : null);
      await AnalyticsService.setUserProperty(name: 'region', value: profile.demographicsConsent ? profile.region : null);
    } else {
      // Clear properties if consent revoked
      await AnalyticsService.setUserProperty(name: 'age_band', value: null);
      await AnalyticsService.setUserProperty(name: 'gender', value: null);
      await AnalyticsService.setUserProperty(name: 'region', value: null);
    }
  }
}

class UserProfile {
  final bool analyticsConsent;
  final bool demographicsConsent;
  final String? ageBand; // e.g., '18-24', '25-34', 'Prefer not to say'
  final String? gender;  // e.g., 'female', 'male', 'nonbinary', 'other', 'prefer_not'
  final String? region;  // e.g., 'US', 'IN', 'EU', coarse only

  const UserProfile({
    required this.analyticsConsent,
    required this.demographicsConsent,
    this.ageBand,
    this.gender,
    this.region,
  });

  UserProfile copyWith({
    bool? analyticsConsent,
    bool? demographicsConsent,
    String? ageBand,
    String? gender,
    String? region,
  }) => UserProfile(
        analyticsConsent: analyticsConsent ?? this.analyticsConsent,
        demographicsConsent: demographicsConsent ?? this.demographicsConsent,
        ageBand: ageBand ?? this.ageBand,
        gender: gender ?? this.gender,
        region: region ?? this.region,
      );
}
