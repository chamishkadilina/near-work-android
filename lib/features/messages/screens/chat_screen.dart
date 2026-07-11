import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/features/messages/models/conversation.dart';
import 'package:nearwork/features/messages/screens/pdf_preview_page.dart';
import 'package:nearwork/features/messages/services/inbox_service.dart';
import 'package:nearwork/features/profile/models/resume_item.dart';
import 'package:nearwork/features/profile/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = InboxService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String _otherPhotoUrl = '';

  bool get _isRecruiter =>
      widget.currentUserId == widget.conversation.recruiterId;

  String get _otherPartyName => _isRecruiter
      ? widget.conversation.applicantName
      : widget.conversation.jobEmployer;

  String get _otherInitials => _isRecruiter
      ? widget.conversation.applicantInitials
      : widget.conversation.employerInitials;

  @override
  void initState() {
    super.initState();
    _loadOtherPhoto();
    final conv = widget.conversation;
    if (_isRecruiter && conv.unreadByRecruiter) {
      _service.markViewedByRecruiter(conv.id);
    } else if (!_isRecruiter && conv.unreadByApplicant) {
      _service.markViewedByApplicant(conv.id);
    }
  }

  Future<void> _loadOtherPhoto() async {
    if (_isRecruiter) {
      // Recruiter sees the applicant's profile photo.
      final url = await _service.getUserPhotoUrl(
        widget.conversation.applicantId,
      );
      if (mounted) setState(() => _otherPhotoUrl = url);
    } else {
      // Applicant sees the job post's company image (already in the conversation).
      if (mounted)
        setState(() => _otherPhotoUrl = widget.conversation.jobImageUrl);
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await _service.sendMessage(
      widget.conversation.id,
      widget.currentUserId,
      text,
    );
    if (_isRecruiter) {
      await _service.markRecruiterReplied(widget.conversation.id);
    }
    _scrollToBottom();
  }

  Future<void> _showResumePicker() async {
    final uid = widget.currentUserId;
    final resumes = await context
        .read<ProfileProvider>()
        .resumesStream(uid)
        .first;

    if (!mounted) return;

    if (resumes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No resumes found in your profile. Upload one first.',
          ),
          backgroundColor: AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 72),
        ),
      );
      return;
    }

    ResumeItem? selectedResume;
    await showDialog<void>(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (_, setDlgState) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            title: const Text(
              'Send a resume',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose one of your saved resumes to share in this chat.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                ...resumes.map((r) {
                  final isSelected = selectedResume?.id == r.id;
                  return GestureDetector(
                    onTap: () => setDlgState(
                      () => selectedResume = isSelected ? null : r,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 18,
                              color: Colors.red.shade400,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.fileName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${r.fileSize} · ${r.updatedLabel}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dlgCtx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedResume == null
                          ? null
                          : () async {
                              final resume = selectedResume!;
                              Navigator.pop(dlgCtx);
                              await _service.sendResumeMessage(
                                conversationId: widget.conversation.id,
                                senderId: widget.currentUserId,
                                text: 'Shared a resume',
                                resumeUrl: resume.fileUrl,
                                resumeName: resume.fileName,
                              );
                              if (_isRecruiter) {
                                await _service.markRecruiterReplied(
                                  widget.conversation.id,
                                );
                              }
                              if (mounted) _scrollToBottom();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Send Resume'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            _AppBarAvatar(
              photoUrl: _otherPhotoUrl,
              initials: _otherInitials,
              size: 38,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _otherPartyName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    conv.jobTitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_isRecruiter) _StatusMenu(conv: conv, service: _service),
          if (!_isRecruiter)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'view_resume') {
                  if (conv.resumeUrl.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfPreviewPage(
                          url: conv.resumeUrl,
                          fileName: conv.resumeName.isNotEmpty
                              ? conv.resumeName
                              : 'Resume',
                        ),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  value: 'view_resume',
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        size: 24,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'View shared resume',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Status banner for applicant ──────────────────────────────────
            if (!_isRecruiter && conv.status != 'pending')
              _StatusBanner(status: conv.status),

            // ── Messages ─────────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: _service.messages(conv.id),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  final msgs = snap.data ?? [];
                  if (msgs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: msgs.length,
                    itemBuilder: (ctx, i) {
                      final msg = msgs[i];
                      final isMe = msg.senderId == widget.currentUserId;
                      final showDate =
                          i == 0 ||
                          !_sameDay(msgs[i - 1].createdAt, msg.createdAt);
                      return Column(
                        children: [
                          if (showDate) _DateDivider(date: msg.createdAt),
                          if (msg.type == 'application')
                            _ApplicationMessage(
                              msg: msg,
                              isMe: isMe,
                              conv: conv,
                            )
                          else if (msg.resumeUrl.isNotEmpty)
                            _ResumeBubble(
                              resumeUrl: msg.resumeUrl,
                              resumeName:
                                  msg.text.isNotEmpty &&
                                      msg.text != 'Shared a resume'
                                  ? msg.text
                                  : 'Resume',
                              isMe: isMe,
                              time: msg.createdAt,
                            )
                          else
                            _MessageBubble(msg: msg, isMe: isMe),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // ── Input bar ────────────────────────────────────────────────────
            _InputBar(
              controller: _msgCtrl,
              onSend: _sendMessage,
              onSendResume: _showResumePicker,
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

// Avatar shown inside the AppBar (white border + white initials fallback).
class _AppBarAvatar extends StatelessWidget {
  const _AppBarAvatar({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
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
                  errorBuilder: (context, error, _) => _fallback(),
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() => Container(
    color: Colors.white.withValues(alpha: 0.2),
    child: Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),
  );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      'shortlisted' => (
        Colors.green.shade600,
        Icons.star_rounded,
        'You have been shortlisted!',
      ),
      'rejected' => (
        Colors.red.shade600,
        Icons.cancel_rounded,
        'Application not selected',
      ),
      'viewed' => (
        AppColors.primary,
        Icons.visibility_rounded,
        'Recruiter viewed your application',
      ),
      _ => (Colors.grey.shade600, Icons.info_rounded, status),
    };
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.conv, required this.service});
  final Conversation conv;
  final InboxService service;

  static const _statuses = ['pending', 'viewed', 'shortlisted', 'rejected'];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (status) => service.updateStatus(conv.id, status),
      itemBuilder: (_) => _statuses.map((s) {
        final (icon, color, label) = switch (s) {
          'pending' => (Icons.pending_rounded, Colors.orange, 'Pending'),
          'viewed' => (Icons.visibility_rounded, AppColors.primary, 'Viewed'),
          'shortlisted' => (
            Icons.star_rounded,
            Colors.green.shade600,
            'Shortlisted',
          ),
          'rejected' => (Icons.cancel_rounded, Colors.red, 'Rejected'),
          _ => (Icons.circle, Colors.grey, s),
        };
        return PopupMenuItem<String>(
          value: s,
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Text(label),
              if (conv.status == s) ...[
                const Spacer(),
                Icon(Icons.check, size: 16, color: color),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

String _fmtTime(DateTime dt) {
  final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final m = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $period';
}

// Shows the initial application as 1–3 left/right aligned chat bubbles:
// "I'm interested in…" + optional cover note + optional resume tile.
class _ApplicationMessage extends StatelessWidget {
  const _ApplicationMessage({
    required this.msg,
    required this.isMe,
    required this.conv,
  });
  final Message msg;
  final bool isMe;
  final Conversation conv;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        _ApplicationBubble(
          isMe: isMe,
          jobTitle: conv.jobTitle,
          time: msg.createdAt,
        ),
        if (conv.coverNote.isNotEmpty)
          _MessageBubble(
            msg: Message(
              id: '${msg.id}_cover',
              senderId: msg.senderId,
              text: conv.coverNote,
              createdAt: msg.createdAt,
            ),
            isMe: isMe,
          ),
        if (conv.resumeUrl.isNotEmpty)
          _ResumeBubble(
            resumeUrl: conv.resumeUrl,
            resumeName: conv.resumeName,
            isMe: isMe,
            time: msg.createdAt,
          ),
      ],
    );
  }
}

class _ApplicationBubble extends StatelessWidget {
  const _ApplicationBubble({
    required this.isMe,
    required this.jobTitle,
    required this.time,
  });
  final bool isMe;
  final String jobTitle;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMe ? 14 : 2),
                      bottomRight: Radius.circular(isMe ? 2 : 14),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.work_outline_rounded,
                        size: 15,
                        color: isMe ? Colors.white70 : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "I'm interested in $jobTitle",
                          style: TextStyle(
                            fontSize: 14,
                            color: isMe ? Colors.white : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _fmtTime(time),
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeBubble extends StatelessWidget {
  const _ResumeBubble({
    required this.resumeUrl,
    required this.resumeName,
    required this.isMe,
    required this.time,
  });
  final String resumeUrl;
  final String resumeName;
  final bool isMe;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.primary.withValues(alpha: 0.14);
    final accentStroke = AppColors.primary.withValues(alpha: 0.22);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfPreviewPage(
                        url: resumeUrl,
                        fileName: resumeName.isNotEmpty ? resumeName : 'Resume',
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.74,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(isMe ? 14 : 2),
                        bottomRight: Radius.circular(isMe ? 2 : 14),
                      ),
                      border: Border.all(color: accentStroke, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resumeName.isNotEmpty ? resumeName : 'Resume',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Tap to preview and open',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmtTime(time),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg, required this.isMe});
  final Message msg;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final time = _fmtTime(msg.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMe ? 14 : 2),
                      bottomRight: Radius.circular(isMe ? 2 : 14),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final label = d == today
        ? 'Today'
        : d == today.subtract(const Duration(days: 1))
        ? 'Yesterday'
        : '${date.day}/${date.month}/${date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade200)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade200)),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onSendResume,
  });
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onSendResume;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: 10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.fromLTRB(16, 10, 48, 10),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    onPressed: onSendResume,
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(
                Icons.send_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
