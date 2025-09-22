import 'dart:async';
import 'package:trashit/models/trash_post.dart';

class SampleDataService {
  // Base sample payloads used to seed mock posts (ensure >10 for richer preview)
  static final List<Map<String, dynamic>> _samplePosts = [
    {
      'url': 'https://twitter.com/example/status/123456789',
      'title': '🚨 BREAKING: Local Man Discovers Water is Wet',
      'hashtags': ['#breaking', '#news', '#obviousfacts'],
      'image_url': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=1200&h=675&fit=crop',
      'ai_summary': 'Revolutionary discovery shakes scientific community worldwide.'
    },
    {
      'url': 'https://instagram.com/influencer/post/987654321',
      'title': 'My Morning Routine for Success (Sponsored)',
      'hashtags': ['#morningroutine', '#sponsored', '#blessed'],
      'image_url': 'https://images.unsplash.com/photo-1493612276216-ee3925520721?w=1200&h=675&fit=crop',
      'ai_summary': 'Wake up at 4am to sell you overpriced wellness products.'
    },
    {
      'url': 'https://tiktok.com/@dancer/video/456789123',
      'title': 'Dancing to the Same Song Everyone Else Is',
      'hashtags': ['#trending', '#dance', '#viral'],
      'image_url': 'https://images.unsplash.com/photo-1516389573391-5620a0263801?w=1200&h=675&fit=crop',
      'ai_summary': 'Copy + paste choreography for fleeting internet fame.'
    },
    {
      'url': 'https://facebook.com/meme/posts/789123456',
      'title': 'Minion Meme About Monday Being Bad',
      'hashtags': ['#mondayblues', '#minions', '#relatable'],
      'image_url': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=1200&h=675&fit=crop',
      'ai_summary': 'Peak humor for people who still use Facebook.'
    },
    {
      'url': 'https://youtube.com/watch?v=clickbait123',
      'title': 'You Won\'t BELIEVE What Happens Next! (GONE WRONG)',
      'hashtags': ['#clickbait', '#gonewrong', '#shocking'],
      'image_url': 'https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=1200&h=675&fit=crop',
      'ai_summary': 'Spoiler: Nothing interesting happens. Ever.'
    },
    {
      'url': 'https://threads.net/post/coffee-journey',
      'title': 'Day 47 of My Coffee Journey ☕️',
      'hashtags': ['#grind', '#coffee', '#aesthetic'],
      'image_url': 'https://images.unsplash.com/photo-1507133750040-4a8f57021524?w=1200&h=675&fit=crop',
      'ai_summary': 'Daily latte art that looks identical to the last 46 days.'
    },
    {
      'url': 'https://tiktok.com/@dancer/video/456789123',
      'title': 'Dancing to the Same Song Everyone Else Is',
      'hashtags': ['#trending', '#dance', '#viral'],
      'image_url': 'https://images.unsplash.com/photo-1516389573391-5620a0263801?w=1200&h=675&fit=crop',
      'ai_summary': 'Copy + paste choreography for fleeting internet fame.'
    },
    {
      'url': 'https://news.site/opinion/123',
      'title': 'Hot Take: Pizza Without Cheese is Better',
      'hashtags': ['#hottake', '#food', '#controversial'],
      'image_url': 'https://images.unsplash.com/photo-1548365328-8b849c0c66a6?w=1200&h=675&fit=crop',
      'ai_summary': 'Bold culinary opinion with suspiciously few data points.'
    },
    {
      'url': 'https://linkedin.com/posts/hustle-journey',
      'title': 'I Woke Up at 2:59 AM and It Changed Everything',
      'hashtags': ['#hustle', '#riseandgrind', '#leadership'],
      'image_url': 'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=1200&h=675&fit=crop',
      'ai_summary': 'Definitely not compensating for anything. Definitely.'
    },
    {
      'url': 'https://reddit.com/r/oddlysatisfying/comments/xyz',
      'title': 'Oddly Satisfying: Slicing Sand for 10 Minutes',
      'hashtags': ['#satisfying', '#asmr', '#loop'],
      'image_url': 'https://images.unsplash.com/photo-1600267185393-e158c3c3b9f2?w=1200&h=675&fit=crop',
      'ai_summary': 'Therapeutic filler content when your brain needs airplane mode.'
    },
    {
      'url': 'https://pinterest.com/pin/diy-lifehack',
      'title': 'DIY Life Hack: Use a Fork as a Phone Stand',
      'hashtags': ['#lifehack', '#diy', '#innovation'],
      'image_url': 'https://images.unsplash.com/photo-1517433456452-f9633a875f6f?w=1200&h=675&fit=crop',
      'ai_summary': 'Totally not dangerous and absolutely not silly.'
    },
    {
      'url': 'https://tiktok.com/@prankster/video/999',
      'title': 'Prank: I Told My Grandma It\'s Tuesday (It\'s Wednesday)',
      'hashtags': ['#prank', '#lol', '#wholesome'],
      'image_url': 'https://images.unsplash.com/photo-1520975922131-c0d61b7e640e?w=1200&h=675&fit=crop',
      'ai_summary': 'Society may never recover from this level of chaos.'
    },
    {
      'url': 'https://youtube.com/watch?v=superfood999',
      'title': 'This One Superfood Cures Everything (Trust Me)',
      'hashtags': ['#superfood', '#health', '#miracle'],
      'image_url': 'https://images.unsplash.com/photo-1524594224032-1f09911f3a2b?w=1200&h=675&fit=crop',
      'ai_summary': 'Cures boredom by making you scroll away faster.'
    },
    {
      'url': 'https://x.com/brand/status/abc',
      'title': 'Brand Apology Notes App Screenshot',
      'hashtags': ['#apology', '#notesapp', '#PR'],
      'image_url': 'https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?w=1200&h=675&fit=crop',
      'ai_summary': 'We\'re sorry you noticed. We won\'t get caught next time.'
    },
    {
      'url': 'https://blog.site/crypto-to-the-moon',
      'title': 'Crypto Will 100x by Friday (Mathematical Proof)',
      'hashtags': ['#crypto', '#moon', '#notfinancialadvice'],
      'image_url': 'https://images.unsplash.com/photo-1518779578993-ec3579fee39f?w=1200&h=675&fit=crop',
      'ai_summary': 'Proof includes vibes, charts, and a generous imagination.'
    },
  ];

  // In-memory mock store
  static final List<TrashPost> _mockPosts = [];
  static final List<_MockListener> _listeners = [];
  static bool _mockInitialized = false;

  // Public: ensure in-memory dataset exists
  static Future<void> ensureMockDataLoaded() async {
    if (_mockInitialized) return;
    _mockInitialized = true;

    final now = DateTime.now();
    for (int i = 0; i < _samplePosts.length; i++) {
      final p = _samplePosts[i];
      final retrashCount = 5 + (i * 3);
      final untrashCount = (i % 3 == 0) ? (i) : (i ~/ 2);

      _mockPosts.add(
        TrashPost(
          id: 'mock_${i + 1}',
          url: p['url'],
          title: p['title'],
          hashtags: List<String>.from(p['hashtags']),
          retrashCount: retrashCount,
          untrashCount: untrashCount,
          deviceId: 'sample_device_$i',
          timestamp: now.subtract(Duration(hours: i * 3 + (i % 2 == 0 ? 1 : 0))),
          imageUrl: p['image_url'],
          aiSummary: p['ai_summary'],
          retrashVotes: List.generate(retrashCount, (index) => 'voter_${i}_$index'),
          untrashVotes: List.generate(untrashCount, (index) => 'unvoter_${i}_$index'),
        ),
      );
    }

    // We want at least 10 in list; the above guarantees >10.
    _notifyAll();
  }

  // Public: live stream of posts, sorted depending on trending flag
  static Stream<List<TrashPost>> watchMockPosts({required bool trending}) {
    // Create a controller per subscriber to allow per-subscriber sorting
    final controller = StreamController<List<TrashPost>>.broadcast();
    final listener = _MockListener(controller: controller, trending: trending);
    _listeners.add(listener);

    // Emit initial snapshot
    Future.microtask(() => _emitTo(listener));

    controller.onCancel = () {
      _listeners.remove(listener);
    };

    return controller.stream;
  }

  // Public: create or bump a mock post when sharing/adding
  static Future<void> createMockPost({
    required String url,
    required String title,
    required List<String> hashtags,
    required String deviceId,
    required String imageUrl,
  }) async {
    await ensureMockDataLoaded();

    // Normalize by basic trimming (keep simple for mock)
    final normalized = url.trim();

    // Check for existing url
    final existingIndex = _mockPosts.indexWhere((p) => p.url == normalized);
    if (existingIndex != -1) {
      final existing = _mockPosts[existingIndex];

      // If the same device already owns this post (self submission), block duplicate and surface message
      if (existing.deviceId == deviceId) {
        throw Exception('You have already trashed this post');
      }

      // If not yet voted by this device, add a retrash vote
      final hasVoted = existing.retrashVotes.contains(deviceId) || existing.untrashVotes.contains(deviceId);
      if (!hasVoted) {
        final updated = existing.copyWith(
          retrashCount: existing.retrashCount + 1,
          retrashVotes: List<String>.from(existing.retrashVotes)..add(deviceId),
        );
        _mockPosts[existingIndex] = updated;
        _notifyAll();
      } else {
        // Already voted on this post (retrash or untrash)
        throw Exception('You have already voted on this post');
      }
      return;
    }

    // Create a new post
    final newPost = TrashPost(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      url: normalized,
      title: title.isNotEmpty ? title : 'Shared Content',
      hashtags: hashtags,
      retrashCount: 1,
      untrashCount: 0,
      deviceId: deviceId,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      aiSummary: 'Mock summary: community thinks this is trash.',
      retrashVotes: [deviceId],
      untrashVotes: const [],
    );
    _mockPosts.insert(0, newPost);
    _notifyAll();
  }

  static Future<void> voteOnMockPost(String postId, String deviceId, bool isRetrash) async {
    await ensureMockDataLoaded();
    final index = _mockPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _mockPosts[index];

    // Prevent self-voting: owners cannot retrash or untrash their own post
    if (post.deviceId == deviceId) {
      if (isRetrash) {
        throw Exception("You can't retrash your own post");
      } else {
        throw Exception("You can't untrash your own post. You can delete it instead");
      }
    }

    // Block if this device already used undo on this post
    if (post.undoLocks.contains(deviceId)) {
      throw Exception('You already used Undo for this post');
    }

    // Already voted
    if (post.retrashVotes.contains(deviceId) || post.untrashVotes.contains(deviceId)) {
      throw Exception('You have already voted on this post');
    }

    final rv = List<String>.from(post.retrashVotes);
    final uv = List<String>.from(post.untrashVotes);

    if (isRetrash) {
      rv.add(deviceId);
    } else {
      uv.add(deviceId);
    }

    final retrash = rv.length;
    final untrash = uv.length;

    // Auto-delete if untrash >= retrash
    if (untrash >= retrash) {
      _mockPosts.removeAt(index);
      _notifyAll();
      return;
    }

    _mockPosts[index] = post.copyWith(
      retrashCount: retrash,
      untrashCount: untrash,
      retrashVotes: rv,
      untrashVotes: uv,
    );
    _notifyAll();
  }

  static Future<void> undoVoteOnMockPost(String postId, String deviceId, bool isRetrash) async {
    await ensureMockDataLoaded();
    final index = _mockPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _mockPosts[index];

    final rv = List<String>.from(post.retrashVotes);
    final uv = List<String>.from(post.untrashVotes);
    final locks = List<String>.from(post.undoLocks);

    if (isRetrash) {
      rv.remove(deviceId);
    } else {
      uv.remove(deviceId);
    }

    if (!locks.contains(deviceId)) {
      locks.add(deviceId);
    }

    _mockPosts[index] = post.copyWith(
      retrashCount: rv.length,
      untrashCount: uv.length,
      retrashVotes: rv,
      untrashVotes: uv,
      undoLocks: locks,
    );
    _notifyAll();
  }

  static Future<bool> hasUserVotedMock(String postId, String deviceId) async {
    await ensureMockDataLoaded();
    final post = _mockPosts.firstWhere(
      (p) => p.id == postId,
      orElse: () => _nullPost,
    );
    if (post.id.isEmpty) return false;
    return post.retrashVotes.contains(deviceId) || post.untrashVotes.contains(deviceId);
    }

  static Future<void> deleteMockPost({required String postId, required String deviceId}) async {
    await ensureMockDataLoaded();
    final index = _mockPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _mockPosts[index];
    if (post.deviceId != deviceId) {
      throw Exception('Only the original trasher can delete this post');
    }
    _mockPosts.removeAt(index);
    _notifyAll();
  }

  // Emit helpers
  static void _notifyAll() {
    for (final l in List<_MockListener>.from(_listeners)) {
      _emitTo(l);
    }
  }

  static void _emitTo(_MockListener listener) {
    final list = List<TrashPost>.from(_mockPosts);
    if (listener.trending) {
      list.sort((a, b) => b.retrashCount.compareTo(a.retrashCount));
    } else {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    // Limit to top 10 items for a concise preview per tab
    final topTen = list.take(10).toList();
    listener.controller.add(topTen);
  }

  static TrashPost get _nullPost => TrashPost(
        id: '',
        url: '',
        title: '',
        hashtags: const [],
        retrashCount: 0,
        untrashCount: 0,
        deviceId: '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        imageUrl: '',
        aiSummary: null,
        retrashVotes: const [],
        untrashVotes: const [],
      );
}

class _MockListener {
  final StreamController<List<TrashPost>> controller;
  final bool trending;
  _MockListener({required this.controller, required this.trending});
}
