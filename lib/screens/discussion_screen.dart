import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/challenge.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../providers/challenge_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/keyboard_spacer.dart';

class DiscussionScreen extends StatefulWidget {
  final Challenge challenge;
  const DiscussionScreen({super.key, required this.challenge});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeProvider>().fetchMessages(widget.challenge.id);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<ChallengeProvider>().challengeMessages[widget.challenge.id] ?? [];
    final currentUser = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.white),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            const Text('DISCUSSION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc500, letterSpacing: 2)),
            const SizedBox(height: 2),
            Text(widget.challenge.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.sender.id == currentUser?.id;
                      return MessageBubble(
                        message: message, 
                        isMe: isMe,
                        currentUser: currentUser,
                      );
                    },
                  ),
          ),
          _buildInputArea(),
          const IsolatedKeyboardSpacer(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.messagesSquare, size: 48, color: AppTheme.zinc900),
          SizedBox(height: 16),
          Text('No messages yet', style: TextStyle(color: AppTheme.zinc700, fontSize: 14)),
          SizedBox(height: 8),
          Text('Start the conversation about this challenge', style: TextStyle(color: AppTheme.zinc800, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    // Only fetch safe area padding once to avoid full rebuild on keyboard height change
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
      decoration: const BoxDecoration(
        color: AppTheme.black,
        border: Border(top: BorderSide(color: AppTheme.zinc900)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.zinc950,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.zinc900),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppTheme.white, fontSize: 15),
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppTheme.zinc700),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _handleSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSending ? AppTheme.zinc900 : AppTheme.white,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                  : const Icon(LucideIcons.send, color: AppTheme.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSend() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    final challengeProvider = context.read<ChallengeProvider>();
    final success = await challengeProvider.sendMessage(widget.challenge.id, content);
    
      if (mounted) {
        setState(() => _isSending = false);
        if (success) {
          _messageController.clear();
          FocusScope.of(context).unfocus();
          _scrollToBottom();
        }
      }
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final User? currentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            AvatarWidget(user: message.sender, size: 32, showBorder: false),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.white : AppTheme.zinc900,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? AppTheme.black : AppTheme.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeago.format(message.createdAt, locale: 'en_short'),
                  style: const TextStyle(color: AppTheme.zinc800, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 12),
            AvatarWidget(user: currentUser ?? message.sender, size: 32, showBorder: false),
          ],
        ],
      ),
    );
  }
}
