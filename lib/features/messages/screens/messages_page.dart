import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/features/messages/widgets/message_card.dart';
import 'package:nearwork/features/messages/screens/message_detail_page.dart';

// Dummy message model
class ConversationModel {
  final String id;
  final String senderName;
  final String senderAvatar;
  final String messagePreview;
  final String timestamp;
  final bool isUnread;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.senderName,
    required this.senderAvatar,
    required this.messagePreview,
    required this.timestamp,
    required this.isUnread,
    required this.unreadCount,
  });
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  // Dummy data
  final List<ConversationModel> allConversations = [
    ConversationModel(
      id: '1',
      senderName: 'Chamishka Perera',
      senderAvatar: 'CP',
      messagePreview: 'Hey, can you share the job details?',
      timestamp: '2m ago',
      isUnread: true,
      unreadCount: 3,
    ),
    ConversationModel(
      id: '2',
      senderName: 'Ravi Kumar',
      senderAvatar: 'RK',
      messagePreview: 'I\'m interested in the Flutter position...',
      timestamp: '1h ago',
      isUnread: true,
      unreadCount: 1,
    ),
    ConversationModel(
      id: '3',
      senderName: 'Priya Singh',
      senderAvatar: 'PS',
      messagePreview: 'Thanks for the interview opportunity!',
      timestamp: '3h ago',
      isUnread: false,
      unreadCount: 0,
    ),
    ConversationModel(
      id: '4',
      senderName: 'Amit Patel',
      senderAvatar: 'AP',
      messagePreview: 'When can we schedule the meeting?',
      timestamp: '5h ago',
      isUnread: false,
      unreadCount: 0,
    ),
    ConversationModel(
      id: '5',
      senderName: 'Nisha Reddy',
      senderAvatar: 'NR',
      messagePreview: 'Congratulations on the new job! 🎉',
      timestamp: 'Yesterday',
      isUnread: false,
      unreadCount: 0,
    ),
    ConversationModel(
      id: '6',
      senderName: 'Vikram Singh',
      senderAvatar: 'VS',
      messagePreview: 'The position has been filled. Thanks for applying...',
      timestamp: 'Yesterday',
      isUnread: false,
      unreadCount: 0,
    ),
  ];

  // Build conversation list
  Widget _buildConversationList(
    List<ConversationModel> conversations, {
    String? emptyMessage,
  }) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline_rounded,
              size: 52,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage ?? 'No messages yet',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with candidates',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8).copyWith(bottom: 100),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return MessageCard(
          senderName: conversation.senderName,
          senderAvatar: conversation.senderAvatar,
          messagePreview: conversation.messagePreview,
          timestamp: conversation.timestamp,
          isUnread: conversation.isUnread,
          unreadCount: conversation.unreadCount,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MessageDetailPage(conversation: conversation),
              ),
            );
          },
          onDelete: () {
            // wire delete logic later
          },
        );
      },
    );
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
              'Messaging Guide',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoTip(
              Icons.speed,
              'Reply quickly to candidates - fast responses increase job applications.',
            ),
            _infoTip(
              Icons.check_circle_outline,
              'Confirm receipt and interview dates promptly.',
            ),
            _infoTip(
              Icons.star_outline,
              'Keep professional tone in all conversations.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Messages are archived automatically after 30 days of inactivity.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _infoTip(IconData icon, String text) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Messages',
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
      body: _buildConversationList(
        allConversations,
        emptyMessage: 'No messages yet',
      ),
    );
  }
}
