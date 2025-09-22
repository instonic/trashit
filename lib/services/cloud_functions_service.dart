import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';

class CloudFunctionsService {
  CloudFunctionsService._();

  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  static Future<bool> createTrashPost({
    required String url,
    required String title,
    required List<String> hashtags,
    required String deviceId,
    required String imageUrl,
  }) async {
    try {
      final callable = _functions.httpsCallable('trashitCreateOrRetrash');
      await callable.call({
        'url': url,
        'title': title,
        'hashtags': hashtags,
        'deviceId': deviceId,
        'imageUrl': imageUrl,
      }).timeout(const Duration(seconds: 10));
      return true;
    } on FirebaseFunctionsException catch (e) {
      // Any callable error (including 'internal') should gracefully fall back
      // Log for diagnostics in preview
      // ignore: avoid_print
      print('CF createTrashPost error: code=${e.code} message=${e.message}');
      return false;
    } on TimeoutException {
      // Network slowness; fall back gracefully
      return false;
    } catch (e) {
      // Unknown error; fall back
      // ignore: avoid_print
      print('CF createTrashPost unknown error: $e');
      return false;
    }
  }

  static Future<bool> voteOnPost({
    required String postId,
    required String deviceId,
    required bool isRetrash,
  }) async {
    try {
      final callable = _functions.httpsCallable('trashitVote');
      await callable.call({
        'postId': postId,
        'deviceId': deviceId,
        'isRetrash': isRetrash,
      }).timeout(const Duration(seconds: 10));
      return true;
    } on FirebaseFunctionsException catch (e) {
      // Fall back to client-side logic on any callable error
      // ignore: avoid_print
      print('CF voteOnPost error: code=${e.code} message=${e.message}');
      return false;
    } on TimeoutException {
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('CF voteOnPost unknown error: $e');
      return false;
    }
  }

  static Future<bool> deletePost({
    required String postId,
    required String deviceId,
  }) async {
    try {
      final callable = _functions.httpsCallable('trashitDeleteOwnedPost');
      await callable.call({
        'postId': postId,
        'deviceId': deviceId,
      }).timeout(const Duration(seconds: 10));
      return true;
    } on FirebaseFunctionsException catch (e) {
      // Fall back if callable fails for any reason
      // ignore: avoid_print
      print('CF deletePost error: code=${e.code} message=${e.message}');
      return false;
    } on TimeoutException {
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('CF deletePost unknown error: $e');
      return false;
    }
  }

  static Future<bool> undoVoteOnPost({
    required String postId,
    required String deviceId,
    required bool isRetrash,
  }) async {
    try {
      final callable = _functions.httpsCallable('trashitUndoVote');
      await callable.call({
        'postId': postId,
        'deviceId': deviceId,
        'isRetrash': isRetrash,
      }).timeout(const Duration(seconds: 10));
      return true;
    } on FirebaseFunctionsException catch (e) {
      // ignore: avoid_print
      print('CF undoVoteOnPost error: code=${e.code} message=${e.message}');
      return false;
    } on TimeoutException {
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('CF undoVoteOnPost unknown error: $e');
      return false;
    }
  }

  // Admin-only maintenance. Provide adminKey configured in Functions runtime config.
  static Future<Map<String, dynamic>?> runAdminMaintenance({
    required String adminKey,
    bool dryRun = true,
    int olderThanDays = 90,
  }) async {
    try {
      final callable = _functions.httpsCallable('trashitAdminRecalcAndCleanup');
      final result = await callable.call({
        'adminKey': adminKey,
        'dryRun': dryRun,
        'olderThanDays': olderThanDays,
      }).timeout(const Duration(seconds: 20));
      final data = result.data;
      if (data is Map<String, dynamic>) return data;
      return null;
    } on FirebaseFunctionsException catch (e) {
      // Treat permission or internal errors as "not available"
      // ignore: avoid_print
      print('CF adminMaintenance error: code=${e.code} message=${e.message}');
      return null;
    } on TimeoutException {
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('CF adminMaintenance unknown error: $e');
      return null;
    }
  }
}
