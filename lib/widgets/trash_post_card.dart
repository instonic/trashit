import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trashit/models/trash_post.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trashit/services/analytics_service.dart';

class TrashPostCard extends StatelessWidget {
  final TrashPost post;
  final String deviceId;
  final bool trending;
  final Function(String postId, bool isRetrash) onVote;
  final Future<void> Function(String postId, bool isRetrash)? onUndo;
  final Future<void> Function(String postId)? onDelete;
  final Future<void> Function(String postId, String reason)? onReport;
  final Future<void> Function(String domain)? onBlockDomain;

  const TrashPostCard({
    super.key,
    required this.post,
    required this.deviceId,
    required this.trending,
    required this.onVote,
    this.onUndo,
    this.onDelete,
    this.onReport,
    this.onBlockDomain,
  });

  bool get hasUserVoted =>
      post.retrashVotes.contains(deviceId) || post.untrashVotes.contains(deviceId);

  bool get hasRetrashed => post.retrashVotes.contains(deviceId);
  bool get hasUntrashed => post.untrashVotes.contains(deviceId);
  bool get hasUndoLock => post.undoLocks.contains(deviceId);

  bool get isOwner => post.deviceId == deviceId;

  @override
  Widget build(BuildContext context) {
    final onSurfaceMuted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    // Use the larger of the stored counters and the vote array lengths so UI reflects
    // updates whether server updates counts, arrays, or both.
    final int retrashDisplay = post.retrashVotes.isEmpty
        ? post.retrashCount
        : (post.retrashVotes.length >= post.retrashCount
            ? post.retrashVotes.length
            : post.retrashCount);
    final int untrashDisplay = post.untrashVotes.isEmpty
        ? post.untrashCount
        : (post.untrashVotes.length >= post.untrashCount
            ? post.untrashVotes.length
            : post.untrashCount);

    // Enablement rules
    // New rule: after any vote, only allow Undo (no switching sides). After Undo is used, lock both.
    final bool canAttemptVote = !hasUserVoted && !hasUndoLock && !isOwner;
    final bool retrashEnabled = trending ? canAttemptVote : canAttemptVote;
    final bool untrashEnabled = trending ? canAttemptVote : canAttemptVote;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Hashtags
                if (post.hashtags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: post.hashtags.map((hashtag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hashtag,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    )).toList(),
                  ),
                
                const SizedBox(height: 12),
                
                // AI Summary
                if (post.aiSummary != null && post.aiSummary!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.smart_toy,
                              size: 16,
                              color: Theme.of(context).colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Why It\'s Trash:',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.aiSummary!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (post.aiSummary != null && post.aiSummary!.isNotEmpty)
                  const SizedBox(height: 12),
                
                // Marker + timestamp
                Row(
                  children: [
                    if (hasUserVoted || hasUndoLock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasUndoLock ? Icons.lock : Icons.check_circle,
                              size: 14,
                              color: hasUndoLock
                                  ? Theme.of(context).colorScheme.outline
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasUndoLock ? 'Undo used' : 'You reacted',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Text(
                      _formatTimestamp(post.timestamp),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                const Divider(height: 24),
                
                // Action bar (Twitter-like)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isTight = constraints.maxWidth < 380;
                    final leftActions = [
                      _actionItem(
                        context: context,
                        enabled: retrashEnabled,
                        icon: Icons.delete,
                        color: Theme.of(context).colorScheme.primary,
                        label: 'Retrash',
                        count: retrashDisplay,
                        showUndo: !trending && hasRetrashed && onUndo != null,
                        onUndo: onUndo == null ? null : () => onUndo!(post.id, true),
                        onTap: () => onVote(post.id, true),
                      ),
                      _actionItem(
                        context: context,
                        enabled: untrashEnabled,
                        icon: Icons.recycling,
                        color: Theme.of(context).colorScheme.secondary,
                        label: 'Untrash',
                        count: untrashDisplay,
                        showUndo: !trending && hasUntrashed && onUndo != null,
                        onUndo: onUndo == null ? null : () => onUndo!(post.id, false),
                        onTap: () => onVote(post.id, false),
                      ),
                      _shareAction(context: context, onTap: () => _handleShare(context)),
                    ];

                    final rightActions = [
                      if (isOwner && onDelete != null)
                        Tooltip(
                          message: 'Delete your post',
                          child: IconButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete post?'),
                                  content: const Text('This will permanently remove your trashed post.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await onDelete!(post.id);
                              }
                            },
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                            tooltip: 'Delete',
                          ),
                        ),
                      Tooltip(
                        message: 'More',
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          onSelected: (value) async {
                            if (value == 'open') {
                              await _launchUrl(post.url);
                            } else if (value == 'report' && onReport != null) {
                              final reason = await _pickReportReason(context);
                              if (reason != null) await onReport!(post.id, reason);
                            } else if (value == 'block' && onBlockDomain != null) {
                              final host = Uri.tryParse(post.url)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? '';
                              await onBlockDomain!(host);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'open', child: Text('Open link')),
                            const PopupMenuItem(value: 'report', child: Text('Report…')),
                            const PopupMenuItem(value: 'block', child: Text('Block domain')),
                          ],
                        ),
                      ),
                    ];

                    if (isTight) {
                      // Allow wrapping on tight widths to prevent overflow
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: leftActions),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: rightActions,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        ...leftActions,
                        const Spacer(),
                        ...rightActions,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionItem({
    required BuildContext context,
    required bool enabled,
    required IconData icon,
    required Color color,
    required String label,
    required int count,
    required VoidCallback onTap,
    bool showUndo = false,
    VoidCallback? onUndo,
  }) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.65,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: enabled ? color : muted, size: 20),
              const SizedBox(width: 6),
              Text(
                '$label',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: enabled ? color : muted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Text(
                  '$count',
                  key: ValueKey<int>(count),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: enabled ? color : muted,
                      ),
                ),
              ),
              if (showUndo && onUndo != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Undo',
                  child: InkResponse(
                    onTap: onUndo,
                    borderRadius: BorderRadius.circular(16),
                    radius: 16,
                    child: Icon(Icons.undo, size: 18, color: color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareAction({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_new, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              'Share',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    final title = post.title.trim().isEmpty ? 'Check this' : post.title.trim();
    final url = post.url;
    final tags = post.hashtags.isNotEmpty ? '\n${post.hashtags.join(' ')}' : '';
    final text = '$title\n$url$tags\n\nShared via Trashit';

    try {
      await Share.share(text, subject: title);
      await AnalyticsService.logShare(postId: post.id);
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: url));
      // Best-effort destination indicator for analytics
      await AnalyticsService.logShare(postId: post.id, destination: 'copy_fallback');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }

  Future<String?> _pickReportReason(BuildContext context) async {
    String? selected;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        String? localSelection = selected;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Report content'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  value: 'spam',
                  groupValue: localSelection,
                  onChanged: (v) => setState(() => localSelection = v),
                  title: const Text('Spam or misleading'),
                ),
                RadioListTile<String>(
                  value: 'abuse',
                  groupValue: localSelection,
                  onChanged: (v) => setState(() => localSelection = v),
                  title: const Text('Abusive or hateful'),
                ),
                RadioListTile<String>(
                  value: 'illegal',
                  groupValue: localSelection,
                  onChanged: (v) => setState(() => localSelection = v),
                  title: const Text('Illegal or dangerous'),
                ),
                RadioListTile<String>(
                  value: 'copyright',
                  groupValue: localSelection,
                  onChanged: (v) => setState(() => localSelection = v),
                  title: const Text('Copyright infringement'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  selected = localSelection;
                  Navigator.of(ctx).pop();
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        );
      },
    );
    return selected;
  }
  
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // ignore
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
