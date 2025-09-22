import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trashit/services/cloud_functions_service.dart';
import 'package:trashit/models/trash_post.dart';
import 'package:trashit/openai/openai_config.dart';
import 'package:trashit/services/sample_data_service.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'trash_can_posts';
  static const String _reportsCollection = 'trash_reports';
  // Prefer Cloud Functions for stronger guarantees (idempotency, validation, auth)
  // If the callable function is not found, we gracefully fall back to client-side logic.
  static const bool _useCloudFunctions = true;

  // Client-side mirror of deletion policy (must match Functions):
  // delete only if totalVotes >= kMinVotesToDelete AND (untrash - retrash) >= kRequiredMarginToDelete
  static const int kMinVotesToDelete = 5;
  static const int kRequiredMarginToDelete = 2;

  static bool get _useMock => Firebase.apps.isEmpty;

  static String _normalizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
      final filteredParams = Map<String, String>.from(uri.queryParameters)
        ..removeWhere((key, value) => key.toLowerCase().startsWith('utm_'));
      var path = uri.path;
      if (path.length > 1 && path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }
      final normalized = Uri(
        scheme: uri.scheme,
        host: host,
        path: path,
        queryParameters: filteredParams.isEmpty ? null : filteredParams,
      );
      return normalized.toString();
    } catch (_) {
      return url;
    }
  }

  static Stream<List<TrashPost>> getTrashPosts({bool trending = false}) {
    if (_useMock) {
      // Mock mode: in-memory live stream
      return SampleDataService.watchMockPosts(trending: trending);
    }

    // Try Firestore first; if the listener errors (rules, misconfig, offline),
    // automatically fall back to the in-memory mock stream so preview keeps working.
    final controller = StreamController<List<TrashPost>>.broadcast();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;

    void startFirestore() {
      Query<Map<String, dynamic>> query = _firestore.collection(_collection);
      if (trending) {
        query = query.orderBy('retrash_count', descending: true);
      } else {
        query = query.orderBy('timestamp', descending: true);
      }
      sub = query.snapshots().listen(
        (snapshot) {
          // ignore: avoid_print
          print('[FS] Live Firestore snapshot received: ${snapshot.docs.length} docs (trending=$trending)');
          final list = snapshot.docs.map((doc) => TrashPost.fromFirestore(doc)).toList();
          controller.add(list);
        },
        onError: (error) async {
          // ignore: avoid_print
          print('[FS] Firestore stream error -> falling back to mock: $error');
          // Fall back only once; subsequent updates come from mock stream
          await sub?.cancel();
          // Ensure mock data exists
          await SampleDataService.ensureMockDataLoaded();
          // Pipe mock posts
          SampleDataService.watchMockPosts(trending: trending).listen(
            (list) {
              // ignore: avoid_print
              print('[FS] Mock stream update: ${list.length} items (trending=$trending)');
              controller.add(list);
            },
            onError: (_) {},
          );
        },
      );
    }

    startFirestore();

    controller.onCancel = () {
      sub?.cancel();
    };

    return controller.stream;
  }

  static Future<void> createTrashPost({
    required String url,
    required String title,
    required List<String> hashtags,
    required String deviceId,
    required String imageUrl,
  }) async {
    if (_useMock) {
      // Mock mode: update in-memory list
      // ignore: avoid_print
      print('[FS] createTrashPost (mock) url=$url device=$deviceId');
      return SampleDataService.createMockPost(
        url: url,
        title: title,
        hashtags: hashtags,
        deviceId: deviceId,
        imageUrl: imageUrl,
      );
    }

    // Try Cloud Function first (server-enforced dedupe, voting, summary)
    if (_useCloudFunctions) {
      // ignore: avoid_print
      print('[FS] createTrashPost via CF start url=$url device=$deviceId');
      final called = await CloudFunctionsService.createTrashPost(
        url: url,
        title: title,
        hashtags: hashtags,
        deviceId: deviceId,
        imageUrl: imageUrl,
      );
      if (called) {
        // ignore: avoid_print
        print('[FS] createTrashPost via CF success');
        return;
      } else {
        // ignore: avoid_print
        print('[FS] createTrashPost CF unavailable/failure -> falling back to client write');
      }
    }

    // Fallback client-side logic
    try {
      // Normalize and check if a post with this URL already exists
      final normalizedUrl = _normalizeUrl(url);
      // ignore: avoid_print
      print('[FS] createTrashPost fallback normalizedUrl=$normalizedUrl');
      final existing = await _firestore
          .collection(_collection)
          .where('url', isEqualTo: normalizedUrl)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        final docRef = existing.docs.first.reference;
        // ignore: avoid_print
        print('[FS] existing post found -> adding retrash vote');
        // Add a re-trash vote if the user hasn't voted yet
        await _firestore.runTransaction((transaction) async {
          final snap = await transaction.get(docRef);
          if (!snap.exists) return;
          final post = TrashPost.fromFirestore(snap);

          // If same device created this post, block with friendly error
          if (post.deviceId == deviceId) {
            throw Exception('You have already trashed this post');
          }

          final alreadyVoted = post.retrashVotes.contains(deviceId) || post.untrashVotes.contains(deviceId);
          if (alreadyVoted) {
            throw Exception('You have already voted on this post');
          }

          final newRetrashVotes = List<String>.from(post.retrashVotes)..add(deviceId);
          final newRetrashCount = post.retrashCount + 1;

          transaction.update(docRef, {
            'retrash_count': newRetrashCount,
            'retrash_votes': newRetrashVotes,
          });
        });
        // ignore: avoid_print
        print('[FS] retrash vote added to existing post');
        return;
      }

      // Generate AI summary for a new post (client-side fallback)
      final aiSummary = await OpenAIService.generateTrashSummary(title, hashtags);

      final post = TrashPost(
        id: '',
        url: normalizedUrl,
        title: title,
        hashtags: hashtags,
        retrashCount: 1,
        untrashCount: 0,
        deviceId: deviceId,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        aiSummary: aiSummary,
        retrashVotes: [deviceId],
        untrashVotes: [],
      );

      await _firestore.collection(_collection).add(post.toFirestore());
      // ignore: avoid_print
      print('[FS] createTrashPost fallback -> new post added');
    } catch (e) {
      // ignore: avoid_print
      print('[FS] createTrashPost error: $e');
      throw Exception('Failed to create trash post: $e');
    }
  }

  static Future<void> voteOnPost(String postId, String deviceId, bool isRetrash) async {
    if (_useMock) {
      return SampleDataService.voteOnMockPost(postId, deviceId, isRetrash);
    }

    // Try Cloud Function first to guarantee single-vote and auto-delete on server
    if (_useCloudFunctions) {
      final called = await CloudFunctionsService.voteOnPost(
        postId: postId,
        deviceId: deviceId,
        isRetrash: isRetrash,
      );
      if (called) return;
    }

    // Fallback client-side voting logic with counter-array sync and undo lock enforcement
    try {
      final docRef = _firestore.collection(_collection).doc(postId);

      // ignore: avoid_print
      print('[FS] voteOnPost fallback (client txn) start: postId=$postId isRetrash=$isRetrash deviceId=$deviceId');

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          // ignore: avoid_print
          print('[FS] voteOnPost: doc not found for postId=$postId');
          return;
        }

        final post = TrashPost.fromFirestore(snapshot);

        // Prevent self-votes: owners cannot retrash or untrash their own post
        if (post.deviceId == deviceId) {
          throw Exception(isRetrash
              ? "You can't retrash your own post"
              : "You can't untrash your own post. You can delete it instead");
        }

        // If undo was already used by this device on this post, block any further voting
        if (post.undoLocks.contains(deviceId)) {
          throw Exception('You already used Undo for this post');
        }

        // Check if user already voted
        final hasRetrashVote = post.retrashVotes.contains(deviceId);
        final hasUntrashVote = post.untrashVotes.contains(deviceId);

        if (hasRetrashVote || hasUntrashVote) {
          throw Exception('You have already voted on this post');
        }

        final rv = List<String>.from(post.retrashVotes.where((e) => e.isNotEmpty).toSet());
        final uv = List<String>.from(post.untrashVotes.where((e) => e.isNotEmpty).toSet());

        if (isRetrash) {
          rv.add(deviceId);
        } else {
          uv.add(deviceId);
        }

        final newRetrashCount = rv.length;
        final newUntrashCount = uv.length;

        // Conservative deletion rule: require majority and minimum participation
        final totalVotes = newRetrashCount + newUntrashCount;
        final shouldDelete = totalVotes >= kMinVotesToDelete && (newUntrashCount - newRetrashCount) >= kRequiredMarginToDelete;
        if (shouldDelete) {
          // ignore: avoid_print
          print('[FS] voteOnPost: deleting post (untrash outweighs retrash with sufficient votes)');
          transaction.delete(docRef);
          return;
        }

        transaction.update(docRef, {
          'retrash_count': newRetrashCount,
          'untrash_count': newUntrashCount,
          'retrash_votes': rv,
          'untrash_votes': uv,
        });

        // ignore: avoid_print
        print('[FS] voteOnPost updated counts -> retrash=$newRetrashCount untrash=$newUntrashCount');
      });
    } catch (e) {
      // ignore: avoid_print
      print('[FS] voteOnPost fallback error: $e');
      throw Exception('Failed to vote on post: $e');
    }
  }

  static Future<void> undoVoteOnPost(String postId, String deviceId, bool isRetrash) async {
    if (_useMock) {
      return SampleDataService.undoVoteOnMockPost(postId, deviceId, isRetrash);
    }

    // Try Cloud Function first
    if (_useCloudFunctions) {
      final called = await CloudFunctionsService.undoVoteOnPost(
        postId: postId,
        deviceId: deviceId,
        isRetrash: isRetrash,
      );
      if (called) return;
    }

    // Fallback client-side undo with counter-array sync and lock-out
    try {
      final docRef = _firestore.collection(_collection).doc(postId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return; // Post may have been deleted
        }
        final post = TrashPost.fromFirestore(snapshot);
        final rv = List<String>.from(post.retrashVotes.where((e) => e.isNotEmpty).toSet());
        final uv = List<String>.from(post.untrashVotes.where((e) => e.isNotEmpty).toSet());
        final locks = List<String>.from(post.undoLocks.where((e) => e.isNotEmpty).toSet());

        if (isRetrash) {
          rv.remove(deviceId);
        } else {
          uv.remove(deviceId);
        }
        // After undo, record a lock to prevent any further voting on this post by this device
        if (!locks.contains(deviceId)) {
          locks.add(deviceId);
        }

        transaction.update(docRef, {
          'retrash_count': rv.length,
          'untrash_count': uv.length,
          'retrash_votes': rv,
          'untrash_votes': uv,
          'undo_locks': locks,
        });
      });
    } catch (e) {
      // ignore: avoid_print
      print('[FS] undoVoteOnPost fallback error: $e');
      throw Exception('Failed to undo vote: $e');
    }
  }

  static Future<bool> hasUserVoted(String postId, String deviceId) async {
    if (_useMock) {
      return SampleDataService.hasUserVotedMock(postId, deviceId);
    }
    try {
      final doc = await _firestore.collection(_collection).doc(postId).get();
      if (!doc.exists) return false;

      final post = TrashPost.fromFirestore(doc);
      return post.retrashVotes.contains(deviceId) || post.untrashVotes.contains(deviceId);
    } catch (e) {
      return false;
    }
  }

  static Future<void> deletePost({required String postId, required String deviceId}) async {
    if (_useMock) {
      return SampleDataService.deleteMockPost(postId: postId, deviceId: deviceId);
    }

    // Try Cloud Function first for server-side ownership enforcement
    if (_useCloudFunctions) {
      final called = await CloudFunctionsService.deletePost(postId: postId, deviceId: deviceId);
      if (called) return;
    }

    // Fallback client-side check
    try {
      final docRef = _firestore.collection(_collection).doc(postId);
      final snap = await docRef.get();
      if (!snap.exists) return;
      final post = TrashPost.fromFirestore(snap);
      if (post.deviceId != deviceId) {
        throw Exception('Only the original trasher can delete this post');
      }
      await docRef.delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  static Future<void> reportPost({
    required String postId,
    required String deviceId,
    required String reason,
  }) async {
    if (_useMock) {
      // ignore: avoid_print
      print('[FS] reportPost (mock) postId=' + postId + ' reason=' + reason);
      return;
    }
    try {
      final doc = await _firestore.collection(_collection).doc(postId).get();
      if (!doc.exists) return;
      final post = TrashPost.fromFirestore(doc);
      final host = Uri.tryParse(post.url)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? '';
      await _firestore.collection(_reportsCollection).add({
        'post_id': postId,
        'url': post.url,
        'domain': host,
        'reason': reason,
        'reporter_device': deviceId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to report: $e');
    }
  }
}
