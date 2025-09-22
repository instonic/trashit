import 'package:shared_preferences/shared_preferences.dart';

class BlocklistService {
  BlocklistService._();

  static const _kBlockedDomains = 'blocked_domains_v1';

  static Future<Set<String>> getBlockedDomains() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kBlockedDomains) ?? <String>[];
    return list.map((e) => e.toLowerCase()).toSet();
    }

  static Future<void> addBlockedDomain(String domain) async {
    final normalized = domain.toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kBlockedDomains) ?? <String>[];
    if (!list.contains(normalized)) {
      list.add(normalized);
      await prefs.setStringList(_kBlockedDomains, list);
    }
  }

  static Future<void> removeBlockedDomain(String domain) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kBlockedDomains) ?? <String>[];
    list.removeWhere((e) => e.toLowerCase() == domain.toLowerCase());
    await prefs.setStringList(_kBlockedDomains, list);
  }

  static Future<bool> isDomainBlocked(String domain) async {
    final set = await getBlockedDomains();
    return set.contains(domain.toLowerCase());
  }
}
