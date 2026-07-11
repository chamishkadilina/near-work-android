import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/features/auth/providers/auth_provider.dart';
import 'package:nearwork/features/messages/models/conversation.dart';
import 'package:nearwork/features/messages/providers/inbox_provider.dart';
import 'package:nearwork/features/messages/screens/chat_screen.dart';
import 'package:nearwork/features/messages/services/inbox_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<InboxProvider>().init(uid);
    });
  }

  void _openChat(Conversation conv) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversation: conv, currentUserId: uid),
      ),
    );
  }

  void _deleteWithUndo(Conversation conv) {
    context.read<InboxProvider>().deleteConversation(conv.id);
    final sm = ScaffoldMessenger.of(context);
    sm.clearSnackBars();
    final entry = sm.showSnackBar(
      SnackBar(
        content: const Text('Conversation deleted'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              context.read<InboxProvider>().restoreConversation(conv),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      try {
        entry.close();
      } catch (_) {}
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Inbox Tips',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tipRow(
              Icons.mark_email_unread_outlined,
              'Reply quickly so applicants and recruiters stay engaged.',
            ),
            _tipRow(
              Icons.priority_high_outlined,
              'Check unread messages so you do not miss new opportunities.',
            ),
            _tipRow(
              Icons.delete_outline,
              'Swipe left to remove conversations you no longer need.',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Got it'),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _tipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<InboxProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final conversations = inbox.allConversations;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, size: 20),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: conversations.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              itemBuilder: (_, i) {
                final conv = conversations[i];
                final isRecruiterView = conv.recruiterId == uid;
                return Dismissible(
                  key: Key(conv.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteWithUndo(conv),
                  background: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: _ConvTile(
                    conv: conv,
                    isRecruiterView: isRecruiterView,
                    onTap: () => _openChat(conv),
                  ),
                );
              },
            ),
    );
  }
}

// ── Conversation tile ─────────────────────────────────────────────────────────

class _ConvTile extends StatefulWidget {
  const _ConvTile({
    required this.conv,
    required this.isRecruiterView,
    required this.onTap,
  });

  final Conversation conv;
  final bool isRecruiterView;
  final VoidCallback onTap;

  @override
  State<_ConvTile> createState() => _ConvTileState();
}

class _ConvTileState extends State<_ConvTile> {
  final _service = InboxService();
  String _photoUrl = '';

  @override
  void initState() {
    super.initState();
    if (widget.isRecruiterView) {
      // Recruiter sees the applicant's profile photo (fetched from Firestore).
      _service.getUserPhotoUrl(widget.conv.applicantId).then((url) {
        if (mounted) setState(() => _photoUrl = url);
      });
    } else {
      // Applicant sees the job's company image (already stored in the conversation).
      _photoUrl = widget.conv.jobImageUrl;
    }
  }

  bool get _isUnread => widget.isRecruiterView
      ? widget.conv.unreadByRecruiter
      : widget.conv.unreadByApplicant;

  String get _title =>
      widget.isRecruiterView ? widget.conv.applicantName : widget.conv.jobTitle;

  String get _subtitle => widget.isRecruiterView
      ? 'Applied for: ${widget.conv.jobTitle}'
      : widget.conv.jobEmployer;

  String get _initials => widget.isRecruiterView
      ? widget.conv.applicantInitials
      : widget.conv.employerInitials;

  @override
  Widget build(BuildContext context) {
    final conv = widget.conv;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: _isUnread
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isUnread
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            // Avatar with unread dot
            Stack(
              children: [
                _PhotoAvatar(
                  photoUrl: _photoUrl,
                  initials: _initials,
                  size: 64,
                ),
                if (_isUnread)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(conv.lastMessageAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: _isUnread
                              ? AppColors.primary
                              : Colors.grey.shade400,
                          fontWeight: _isUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _isUnread
                                ? AppColors.textPrimary
                                : Colors.grey.shade500,
                            fontWeight: _isUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.isRecruiterView &&
                          conv.matchScore >= 0) ...[
                        _MatchScoreChip(score: conv.matchScore),
                        const SizedBox(width: 6),
                      ],
                      _StatusChip(status: conv.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Photo avatar ──────────────────────────────────────────────────────────────

class _PhotoAvatar extends StatelessWidget {
  const _PhotoAvatar({
    required this.photoUrl,
    required this.initials,
    required this.size,
  });

  final String photoUrl;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: photoUrl.isNotEmpty
              ? Image.network(
                  photoUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, _) =>
                      _Initials(initials: initials, size: size),
                )
              : _Initials(initials: initials, size: size),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.size});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Match score chip ──────────────────────────────────────────────────────────
// Keyword-overlap score (0-10) between the applicant's resume and the job
// post, computed once when they applied. See ResumeMatchService.

class _MatchScoreChip extends StatelessWidget {
  const _MatchScoreChip({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 7
        ? Colors.green.shade600
        : (score >= 4 ? Colors.orange.shade600 : Colors.grey.shade500);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_rounded, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            '$score/10 match',
            style: TextStyle(
              fontSize: 10.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'shortlisted' => (Colors.green.shade600, 'Shortlisted'),
      'rejected' => (Colors.red.shade600, 'Rejected'),
      'viewed' => (AppColors.primary, 'Viewed'),
      _ => (Colors.orange.shade600, 'Pending'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Apply for a job to start a conversation with a recruiter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
