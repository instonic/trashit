import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trashit/models/trash_post.dart';
import 'package:trashit/services/firestore_service.dart';
import 'package:trashit/services/device_service.dart';
import 'package:trashit/services/sample_data_service.dart';
import 'package:trashit/widgets/trash_post_card.dart';
import 'package:trashit/widgets/floating_share_button.dart';
import 'package:share_handler/share_handler.dart';
import 'package:trashit/services/url_metadata_service.dart';
import 'package:trashit/services/sample_data_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trashit/screens/privacy_policy_page.dart';
import 'package:trashit/screens/about_page.dart';
import 'package:trashit/widgets/trash_url_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trashit/services/analytics_service.dart';
import 'package:trashit/services/user_profile_service.dart';
import 'package:trashit/services/ads_service.dart';
import 'package:trashit/widgets/ad_banner.dart';
import 'package:trashit/screens/preferences_page.dart';
import 'package:trashit/services/blocklist_service.dart';
import 'package:trashit/l10n/app_localizations_simple.dart';
import 'package:trashit/widgets/brand_logo.dart';
import 'package:trashit/widgets/ad_banner.dart';
import 'package:trashit/services/ads_service.dart';

const bool kEnableAds = false;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _deviceId;
  bool _firebaseInitialized = false;
  String? _firebaseError;
  StreamSubscription<SharedMedia>? _shareMediaSub;
  bool _clipboardPromptShown = false;
  bool _initialShareHandled = false;
  bool _webShareHandled = false;
  Set<String> _blockedDomains = {};

  // Desktop header search/composer state
  final TextEditingController _headerFieldCtrl = TextEditingController();
  final FocusNode _headerFieldFocus = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkFirebaseAndInitialize();
    _handleSharedContent();
  }

  Future<void> _checkFirebaseAndInitialize() async {
    try {
      // Rely on initialization performed in main.dart
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase is not configured yet. Please connect the app to a Firebase project.');
      }
      _firebaseInitialized = true;
      await _initializeApp();
      setState(() {});
    } catch (e) {
      _firebaseError = e.toString();
      // Still initialize app for mock mode
      await _initializeApp();
      setState(() {});
    }
  }

  Future<void> _initializeApp() async {
    _deviceId = await DeviceService.getDeviceId();
    // Ensure mock data is available for preview when Firebase is not connected
    await SampleDataService.ensureMockDataLoaded();

    // Apply stored privacy + demographics preferences to analytics (no-op if Firebase not connected)
    final profile = await UserProfileService.load();
    await UserProfileService.applyToAnalytics(profile);
    
    // Load blocklist
    _blockedDomains = await BlocklistService.getBlockedDomains();

    setState(() {});

    // Handle Web Share Target if present (PWA install on Android Chrome)
    await _maybeHandleWebShareTarget();
  }

  void _handleSharedContent() {
    // On web, skip share_handler (not supported) and only use clipboard prompt + web share target
    if (kIsWeb) {
      _maybePromptClipboard();
      return;
    }

    // Listen for shared media/text from other apps (mobile platforms)
    final handler = ShareHandlerPlatform.instance;

    // Stream for shares while the app is running
    _shareMediaSub = handler.sharedMediaStream.listen((SharedMedia media) {
      final sharedText = (media.content ?? '').trim();
      if (sharedText.isNotEmpty) {
        _processSharedUrl(sharedText);
      }
    }, onError: (e) {
      debugPrint('sharedMediaStream error: $e');
    });

    // Handle an initial share that launched the app
    handler.getInitialSharedMedia().then((media) {
      final sharedText = (media?.content ?? '').trim();
      if (sharedText.isNotEmpty) {
        _initialShareHandled = true;
        _processSharedUrl(sharedText);
      } else {
        _maybePromptClipboard();
      }
    }).catchError((e) {
      debugPrint('getInitialSharedMedia error: $e');
      _maybePromptClipboard();
    });
  }

  Future<void> _maybeHandleWebShareTarget() async {
    if (!kIsWeb || _webShareHandled) return;

    final params = Uri.base.queryParameters;
    if (params['share_target'] == '1') {
      _webShareHandled = true;
      _initialShareHandled = true; // prevent clipboard prompt

      final title = (params['title'] ?? '').trim();
      final text = (params['text'] ?? '').trim();
      final sharedUrl = (params['url'] ?? '').trim();

      // Build a simple signature to dedupe across reloads
      final signature = [title, text, sharedUrl].where((e) => e.isNotEmpty).join('|');

      try {
        // Persist signature so refresh does not reprocess the same share
        // Works on web via shared_preferences (localStorage under the hood)
        final prefs = await SharedPreferences.getInstance();
        final lastSig = prefs.getString('last_web_share_signature');
        if (lastSig == signature && signature.isNotEmpty) {
          return; // already handled
        }

        final parts = <String>[];
        if (title.isNotEmpty) parts.add(title);
        if (text.isNotEmpty) parts.add(text);
        if (sharedUrl.isNotEmpty) parts.add(sharedUrl);
        final combined = parts.join(' ').trim();

        if (combined.isNotEmpty) {
          await _processSharedUrl(combined);
          await prefs.setString('last_web_share_signature', signature);
        }
      } catch (e) {
        // If prefs fail, we still try to process once
        final combined = [title, text, sharedUrl].where((e) => e.isNotEmpty).join(' ');
        if (combined.isNotEmpty) {
          await _processSharedUrl(combined);
        }
      }
    }
  }

  Future<void> _processSharedUrl(String sharedText) async {
    if (_deviceId == null) return;

    try {
      // Extract URL from shared text
      final urlRegex = RegExp(r'https?://[^\s]+');
      final match = urlRegex.firstMatch(sharedText);
      if (match == null) return;

      final url = match.group(0)!;
      // ignore: avoid_print
      print('[UI] _processSharedUrl start url=$url device=${_deviceId}');

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(AppLocalizationsSimple.of(context).addingToTrash),
              ],
            ),
          ),
        );
      }

      // Extract metadata and create or update post
      final metadata = await UrlMetadataService.extractMetadata(url);
      // ignore: avoid_print
      print('[UI] metadata extracted -> title="${metadata.title}" imageUrl=${metadata.imageUrl} hashtags=${metadata.hashtags}');

      await FirestoreService.createTrashPost(
        url: url,
        title: metadata.title,
        hashtags: metadata.hashtags,
        deviceId: _deviceId!,
        imageUrl: metadata.imageUrl,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        // ignore: avoid_print
        print('[UI] createTrashPost success for url=$url');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content trashed successfully! 🗑️'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog and show error
      // ignore: avoid_print
      print('[UI] _processSharedUrl error: $e');
      if (mounted) {
        Navigator.of(context).pop();
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty ? message : 'Failed to trash content'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Auto-open the Trash dialog if clipboard contains a valid URL
  Future<void> _maybePromptClipboard() async {
    if (_clipboardPromptShown) return;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null && text.isNotEmpty && _isValidUrlLocal(text)) {
        if (!mounted) return;
        _clipboardPromptShown = true;
        // Open the dialog directly, it will prefill from clipboard
        await showTrashUrlDialog(context: context, onSubmit: _processSharedUrl);
      }
    } catch (_) {
      // ignore clipboard errors
    }
  }

  bool _isValidUrlLocal(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  void _onHeaderSubmit(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    if (_isValidUrlLocal(text)) {
      // Treat as URL -> open composer dialog
      showTrashUrlDialog(context: context, onSubmit: _processSharedUrl);
      return;
    }
    setState(() {
      _searchQuery = text.toLowerCase();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _headerFieldCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Instead of blocking the UI, show a subtle banner when running in mock mode
    final isMock = !_firebaseInitialized;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWidth = screenWidth >= 1000;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isDesktopWidth ? 72 : 64,
        titleSpacing: 12, // add slight leading spacing to avoid edge cropping
        title: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Row(
              children: [
                TrashitHeaderLogo(height: isDesktopWidth ? 44 : 40),
                if (isDesktopWidth) ...[
                  const SizedBox(width: 24),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _headerFieldCtrl,
                              focusNode: _headerFieldFocus,
                              onSubmitted: _onHeaderSubmit,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'Search titles or #hashtags',
                                isDense: true,
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)),
                                suffixIcon: _searchQuery.isNotEmpty || _headerFieldCtrl.text.isNotEmpty
                                    ? IconButton(
                                        tooltip: 'Clear',
                                        onPressed: _clearSearch,
                                        icon: const Icon(Icons.clear),
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            icon: const Icon(Icons.add_link),
                            label: const Text('trashit'),
                            onPressed: () {
                              showTrashUrlDialog(context: context, onSubmit: _processSharedUrl);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (isMock) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizationsSimple.of(context).mockPreview,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onPrimary),
            onSelected: (value) async {
              if (value == 'privacy') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                );
              } else if (value == 'about') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutPage()),
                );
              } else if (value == 'reset_device') {
                await DeviceService.clearDeviceId();
                final newId = await DeviceService.getDeviceId();
                setState(() {
                  _deviceId = newId;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test device ID reset')),
                  );
                }
              } else if (value == 'preferences') {
                if (mounted) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PreferencesPage()),
                  );
                  // Re-apply any changed preferences on return
                  final updated = await UserProfileService.load();
                  await UserProfileService.applyToAnalytics(updated);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'privacy', child: Text('Privacy Policy')),
              const PopupMenuItem(value: 'about', child: Text('About')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'preferences', child: Text('Preferences & Privacy')),
              const PopupMenuItem(value: 'reset_device', child: Text('Reset test device ID (debug)')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                indicatorColor: Theme.of(context).colorScheme.onPrimary,
                tabs: [
                  Tab(text: AppLocalizationsSimple.of(context).tabRecent, icon: const Icon(Icons.access_time)),
                  Tab(text: AppLocalizationsSimple.of(context).tabTrending, icon: const Icon(Icons.trending_up)),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _deviceId == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1000;
                final isUltraWide = constraints.maxWidth >= 1400;
                final feed = TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTrashFeed(trending: false),
                    _buildTrashFeed(trending: true),
                  ],
                );

                // Add leaderboard ad for wide screens
                final mainContent = isWide
                    ? Column(
                        children: [
                          if (kEnableAds)
                            // Header leaderboard ad
                            Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 1200),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: AdBanner(
                              ad: AdsService.getLeaderboardAd(),
                              height: 80,
                              isLeaderboard: true,
                            ),
                          ),
                          Expanded(child: feed),
                        ],
                      )
                    : feed;

                if (!isWide) {
                  return mainContent;
                }

                // Wide desktop: show label nav; Ultra-wide: collapse sidebar to icons only
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isUltraWide ? 72 : 260,
                      padding: EdgeInsets.all(isUltraWide ? 8 : 16),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      child: isUltraWide
                          ? _DesktopRailIcons(
                              currentIndex: _tabController.index,
                              onSelectTab: (i) => _tabController.index = i,
                            )
                          : _DesktopNav(onSelectTab: (i) => _tabController.index = i, currentIndex: _tabController.index),
                    ),
                    Expanded(
                      flex: 3,
                      child: Builder(
                        builder: (context) {
                          const double adRailWidth = 220;
                          final hasAdRails = kEnableAds && constraints.maxWidth >= 1600; // show ad rails on ultra-wide only
                          if (!hasAdRails) {
                            return feed; // regular feed
                          }
                          // Ultra-wide: left and right ad rails flanking the centered feed
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: adRailWidth,
                                child: AdRail(ads: AdsService.leftRailAds(), width: adRailWidth),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: mainContent),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: adRailWidth,
                                child: AdRail(ads: AdsService.rightRailAds(), width: adRailWidth),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Container(
                      width: 380,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      child: _buildSideRail(),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: isDesktopWidth
          ? null
          : FloatingShareButton(
              onSharedUrl: _processSharedUrl,
            ),
    );
  }

  Widget _buildTrashFeed({required bool trending}) {
    final feed = StreamBuilder<List<TrashPost>>(
      stream: FirestoreService.getTrashPosts(trending: trending),
      builder: (context, snapshot) {
        // While Firestore is loading, render mock content so the UI is never empty in preview
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMockFallback(trending: trending);
        }

        // Fallback to mock feed on error
        if (snapshot.hasError) {
          return _buildMockFallback(trending: trending);
        }

        var posts = snapshot.data ?? [];

        // If there are no live posts yet, show sample content to preview UX
        if (posts.isEmpty) {
          return _buildMockFallback(trending: trending);
        }

        // Client-side search filtering (title, hashtags, url host)
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery;
          posts = posts.where((p) {
            final title = p.title.toLowerCase();
            final tags = p.hashtags.map((e) => e.toLowerCase()).toList();
            final host = Uri.tryParse(p.url)?.host.toLowerCase() ?? '';
            return title.contains(q) || host.contains(q) || tags.any((t) => t.contains(q) || ('#$t').contains(q));
          }).toList();
        }

        return _buildPostList(posts: posts, trending: trending);
      },
    );

    if (!trending) return feed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _trendingNeutralNote(),
        const SizedBox(height: 4),
        Expanded(child: feed),
      ],
    );
  }

  Widget _trendingNeutralNote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(Icons.balance, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'We don\'t create content — Trending shows what people are reacting to on the web. Reactions are opinions, not endorsements.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockFallback({required bool trending}) {
    return StreamBuilder<List<TrashPost>>(
      stream: SampleDataService.watchMockPosts(trending: trending),
      builder: (context, mockSnap) {
        if (mockSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var mockPosts = mockSnap.data ?? [];

        // Apply search filter to mock as well
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery;
          mockPosts = mockPosts.where((p) {
            final title = p.title.toLowerCase();
            final tags = p.hashtags.map((e) => e.toLowerCase()).toList();
            final host = Uri.tryParse(p.url)?.host.toLowerCase() ?? '';
            return title.contains(q) || host.contains(q) || tags.any((t) => t.contains(q) || ('#$t').contains(q));
          }).toList();
        }

        if (mockPosts.isEmpty) {
          // Friendly empty state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  trending ? 'No trending trash yet!' : 'No trash found!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  trending
                      ? 'Share some content to get the trash flowing!'
                      : 'Be the first to trash something!',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return _buildPostList(
          posts: mockPosts,
          bannerText: 'Showing sample content for preview',
          trending: trending,
        );
      },
    );
  }

  final Set<String> _inlineUndoUsed = {};

  Widget _buildPostList({required List<TrashPost> posts, String? bannerText, required bool trending}) {
    // Apply per-device domain blocklist
    final filteredPosts = posts.where((p) {
      final host = Uri.tryParse(p.url)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? '';
      return !_blockedDomains.contains(host);
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh is handled by the underlying streams. Add a tiny delay for the indicator UX.
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredPosts.length + 1 + (bannerText != null ? 1 : 0), // +1 for composer, +1 optional banner
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _QuickComposerCard(onTap: () {
                  showTrashUrlDialog(context: context, onSubmit: _processSharedUrl);
                });
              }

              final hasBanner = bannerText != null;
              if (hasBanner && index == 1) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bannerText!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final offset = 1 + (hasBanner ? 1 : 0);
              final post = filteredPosts[index - offset];
              return TrashPostCard(
                post: post,
                deviceId: _deviceId!,
                trending: trending,
                onVote: (postId, isRetrash) async {
                  bool undone = false; // one-time undo guard per vote action
                  try {
                    // Check if this is sample/mock data by post ID prefix
                    if (postId.startsWith('mock_')) {
                      await SampleDataService.voteOnMockPost(postId, _deviceId!, isRetrash);
                    } else {
                      await FirestoreService.voteOnPost(postId, _deviceId!, isRetrash);
                    }

                    // Analytics
                    // ignore: unawaited_futures
                    AnalyticsService.logVote(
                      postId: postId,
                      isRetrash: isRetrash,
                      sourceTab: trending ? 'trending' : 'recent',
                      hashtagsCount: post.hashtags.length,
                    );
                    
                    if (mounted) {
                      final snack = SnackBar(
                        content: Text(isRetrash ? 'Re-trashed! 🗑️' : 'Un-trashed! ♻️'),
                        backgroundColor: isRetrash
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.secondary,
                        action: SnackBarAction(
                          label: 'Undo',
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          onPressed: () async {
                            if (undone) return; // limit to once per snackbar
                            undone = true;
                            try {
                              if (postId.startsWith('mock_')) {
                                await SampleDataService.undoVoteOnMockPost(postId, _deviceId!, isRetrash);
                              } else {
                                await FirestoreService.undoVoteOnPost(postId, _deviceId!, isRetrash);
                              }
                              // ignore: unawaited_futures
                              AnalyticsService.logUndo(
                                postId: postId,
                                isRetrash: isRetrash,
                                sourceTab: trending ? 'trending' : 'recent',
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vote reverted')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to undo: ${e.toString().replaceFirst('Exception: ', '')}')),
                                );
                              }
                            }
                          },
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snack);
                    }
                  } catch (e) {
                    if (mounted) {
                      final message = e.toString().replaceFirst('Exception: ', '');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                onUndo: (postId, isRetrash) async {
                  final key = postId; // per-post one-time inline undo guard
                  if (_inlineUndoUsed.contains(key)) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Undo already used for this post')),
                      );
                    }
                    return;
                  }
                  try {
                    if (postId.startsWith('mock_')) {
                      await SampleDataService.undoVoteOnMockPost(postId, _deviceId!, isRetrash);
                    } else {
                      await FirestoreService.undoVoteOnPost(postId, _deviceId!, isRetrash);
                    }
                    _inlineUndoUsed.add(key);
                    // ignore: unawaited_futures
                    AnalyticsService.logUndo(
                      postId: postId,
                      isRetrash: isRetrash,
                      sourceTab: trending ? 'trending' : 'recent',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vote reverted')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      final message = e.toString().replaceFirst('Exception: ', '');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to undo: $message')),
                      );
                    }
                  }
                },
                onDelete: (postId) async {
                  try {
                    // Check if this is sample/mock data by post ID prefix
                    if (postId.startsWith('mock_')) {
                      await SampleDataService.deleteMockPost(postId: postId, deviceId: _deviceId!);
                    } else {
                      await FirestoreService.deletePost(postId: postId, deviceId: _deviceId!);
                    }
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Post deleted'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      final message = e.toString().replaceFirst('Exception: ', '');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                onReport: (postId, reason) async {
                  try {
                    // Log analytics
                    // ignore: unawaited_futures
                    AnalyticsService.logFlag(postId: postId, reason: reason);
                    if (!postId.startsWith('mock_')) {
                      await FirestoreService.reportPost(postId: postId, deviceId: _deviceId!, reason: reason);
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report submitted. Thank you.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      final message = e.toString().replaceFirst('Exception: ', '');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to report: $message')),
                      );
                    }
                  }
                },
                onBlockDomain: (domain) async {
                  await BlocklistService.addBlockedDomain(domain);
                  _blockedDomains = await BlocklistService.getBlockedDomains();
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Blocked $domain')),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSideRail() {
    final scheme = Theme.of(context).colorScheme;
    final onMuted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            'Top Hashtags',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<TrashPost>>(
            stream: FirestoreService.getTrashPosts(trending: true),
            builder: (context, snapshot) {
              final posts = snapshot.data ?? [];
              final counts = <String, int>{};
              for (final p in posts) {
                for (final h in p.hashtags) {
                  counts[h] = (counts[h] ?? 0) + 1;
                }
              }
              final sorted = counts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final top = sorted.take(10).toList();

              if (top.isEmpty) {
                return Text(
                  'No hashtags yet. Start trashing to see trends!',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in top)
                    Chip(
                      label: Text('#${e.key} (${e.value})'),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Suggested Topics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _TopicChip(label: '#clickbait'),
              _TopicChip(label: '#pseudo-science'),
              _TopicChip(label: '#spam'),
              _TopicChip(label: '#astroturf'),
              _TopicChip(label: '#deepfake'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Community Highlights',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _MiniCard(
            icon: Icons.star,
            color: scheme.primary,
            title: 'Weekly spotlight',
            subtitle: 'Top trashed domain of the week',
          ),
          const SizedBox(height: 8),
          _MiniCard(
            icon: Icons.emoji_events,
            color: Colors.amber,
            title: 'Leaderboards',
            subtitle: 'Most active topics this month',
          ),
          const SizedBox(height: 8),
          _MiniCard(
            icon: Icons.shield_outlined,
            color: scheme.secondary,
            title: 'Safety tips',
            subtitle: 'Recognize common misinformation patterns',
          ),
          const SizedBox(height: 24),
          Text(
            'FAQ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _FaqTile(
            question: 'How does voting work?',
            answer: 'Retrash = agree it\'s trash. Untrash = disagree. Posts are removed only if Untrash beats Retrash by 2+ votes and there are at least 5 total votes.'
          ),
          _FaqTile(
            question: 'Can I add any link?',
            answer: 'Yes, any public web URL. Please avoid personal attacks; focus on content.'
          ),
          _FaqTile(
            question: 'What\'s the search for?',
            answer: 'Search filters the current feed by title, domain, or #hashtags. Paste a URL to add it via the trashit button.'
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shareMediaSub?.cancel();
    _headerFieldCtrl.dispose();
    _headerFieldFocus.dispose();
    super.dispose();
  }
}

class _DesktopNav extends StatelessWidget {
  final void Function(int index) onSelectTab;
  final int currentIndex;
  const _DesktopNav({required this.onSelectTab, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsSimple.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        _NavTile(
          icon: Icons.access_time,
          label: l10n.tabRecent,
          selected: currentIndex == 0,
          onTap: () => onSelectTab(0),
        ),
        _NavTile(
          icon: Icons.trending_up,
          label: l10n.tabTrending,
          selected: currentIndex == 1,
          onTap: () => onSelectTab(1),
        ),
        const Spacer(),
        _NavTile(
          icon: Icons.info_outline,
          label: 'About',
          selected: false,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutPage())),
        ),
        _NavTile(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          selected: false,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
        ),
      ],
    );
  }
}

class _DesktopRailIcons extends StatelessWidget {
  final void Function(int index) onSelectTab;
  final int currentIndex;
  const _DesktopRailIcons({required this.onSelectTab, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _IconOnlyBtn(
          icon: Icons.access_time,
          tooltip: AppLocalizationsSimple.of(context).tabRecent,
          selected: currentIndex == 0,
          onTap: () => onSelectTab(0),
          color: scheme.primary,
        ),
        const SizedBox(height: 6),
        _IconOnlyBtn(
          icon: Icons.trending_up,
          tooltip: AppLocalizationsSimple.of(context).tabTrending,
          selected: currentIndex == 1,
          onTap: () => onSelectTab(1),
          color: scheme.primary,
        ),
        const Spacer(),
        _IconOnlyBtn(
          icon: Icons.info_outline,
          tooltip: 'About',
          selected: false,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutPage())),
          color: scheme.onSurface,
        ),
        const SizedBox(height: 6),
        _IconOnlyBtn(
          icon: Icons.privacy_tip_outlined,
          tooltip: 'Privacy Policy',
          selected: false,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
          color: scheme.onSurface,
        ),
      ],
    );
  }
}

class _IconOnlyBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _IconOnlyBtn({required this.icon, required this.tooltip, required this.selected, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Ink(
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.15) : scheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56,
            height: 48,
            child: Icon(icon, color: selected ? scheme.primary : color),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.primary.withValues(alpha: 0.15) : scheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? scheme.primary : scheme.onSurface),
              const SizedBox(width: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected ? scheme.primary : scheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickComposerCard extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickComposerCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizationsSimple.of(context).quickComposerHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ),
              IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.add_link),
                tooltip: 'Add URL',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  const _TopicChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _MiniCard({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final onMuted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08)),
          ),
        ),
        child: ExpansionTile(
          title: Text(question, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(answer, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: onMuted)),
            )
          ],
        ),
      ),
    );
  }
}
