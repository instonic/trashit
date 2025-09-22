import 'package:cloud_firestore/cloud_firestore.dart';

class TrashPost {
  final String id;
  final String url;
  final String title;
  final List<String> hashtags;
  final int retrashCount;
  final int untrashCount;
  final String deviceId;
  final DateTime timestamp;
  final String imageUrl;
  final String? aiSummary;
  final List<String> retrashVotes;
  final List<String> untrashVotes;
  // Devices that used their one-time undo on this post and are now locked (cannot vote again)
  final List<String> undoLocks;

  TrashPost({
    required this.id,
    required this.url,
    required this.title,
    required this.hashtags,
    required this.retrashCount,
    required this.untrashCount,
    required this.deviceId,
    required this.timestamp,
    required this.imageUrl,
    this.aiSummary,
    required this.retrashVotes,
    required this.untrashVotes,
    this.undoLocks = const [],
  });

  factory TrashPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrashPost(
      id: doc.id,
      url: data['url'] ?? '',
      title: data['title'] ?? '',
      hashtags: List<String>.from(data['hashtags'] ?? []),
      retrashCount: data['retrash_count'] ?? 0,
      untrashCount: data['untrash_count'] ?? 0,
      deviceId: data['device_id'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['image_url'] ?? '',
      aiSummary: data['ai_summary'],
      retrashVotes: List<String>.from(data['retrash_votes'] ?? []),
      untrashVotes: List<String>.from(data['untrash_votes'] ?? []),
      undoLocks: List<String>.from(data['undo_locks'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'url': url,
      'title': title,
      'hashtags': hashtags,
      'retrash_count': retrashCount,
      'untrash_count': untrashCount,
      'device_id': deviceId,
      'timestamp': Timestamp.fromDate(timestamp),
      'image_url': imageUrl,
      'ai_summary': aiSummary,
      'retrash_votes': retrashVotes,
      'untrash_votes': untrashVotes,
      'undo_locks': undoLocks,
    };
  }

  TrashPost copyWith({
    String? id,
    String? url,
    String? title,
    List<String>? hashtags,
    int? retrashCount,
    int? untrashCount,
    String? deviceId,
    DateTime? timestamp,
    String? imageUrl,
    String? aiSummary,
    List<String>? retrashVotes,
    List<String>? untrashVotes,
    List<String>? undoLocks,
  }) {
    return TrashPost(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      hashtags: hashtags ?? this.hashtags,
      retrashCount: retrashCount ?? this.retrashCount,
      untrashCount: untrashCount ?? this.untrashCount,
      deviceId: deviceId ?? this.deviceId,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      aiSummary: aiSummary ?? this.aiSummary,
      retrashVotes: retrashVotes ?? this.retrashVotes,
      untrashVotes: untrashVotes ?? this.untrashVotes,
      undoLocks: undoLocks ?? this.undoLocks,
    );
  }
}