import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/challenge.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/avatar_widget.dart';

class DiscussionScreen extends StatefulWidget {
  final Challenge challenge;
  const DiscussionScreen({super.key, required this.challenge});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeProvider>().fetchMessages(widget.challenge.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() => _isSending = true);
    final success = await context.read<ChallengeProvider>().sendMessage(
      widget.challenge.id,
      _messageController.text.trim(),
    );
    setState(() => _isSending = false);
    
    if (success) {
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final challengeProvider = context.watch<ChallengeProvider>();
    final messages = challengeProvider.challengeMessages[widget.challenge.id] ?? [];

    if (user == null) {
       final isDark = Theme.of(context).brightness == Brightness.dark;
       return Scaffold(
         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
         body: Center(child: CircularProgressIndicator(color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
       );
    }

    return Scaffold(
      appBar: const AppHeader(
        title: 'Discussion',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                // Showing messages in reverse order since it's a chat
                final message = messages[messages.length - 1 - index];
                return _buildMessageItem(message, user.id);
              },
            ),
          ),
          _buildActionArea(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message, String currentUserId) {
    final bool isMe = message.sender.id == currentUserId;
    final bool hasCode = message.content.contains('```');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            AvatarWidget(user: message.sender, size: 32, showBorder: false),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.sender.name, 
                      style: TextStyle(
                        color: Theme.of(context).textTheme.labelSmall?.color, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isMe 
                        ? (isDark ? AppTheme.white : AppTheme.black) 
                        : (isDark ? AppTheme.zinc900 : AppTheme.zinc100),
                    borderRadius: BorderRadius.circular(16),
                    border: (isMe || isDark) ? null : Border.all(color: AppTheme.zinc200),
                  ),
                  child: hasCode 
                    ? _buildCodeContent(message.content, isMe)
                    : Text(
                        message.content,
                        style: TextStyle(
                          color: isMe 
                              ? (isDark ? AppTheme.black : AppTheme.white) 
                              : (isDark ? AppTheme.white : AppTheme.black), 
                          fontSize: 14, 
                          height: 1.4
                        ),
                      ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    timeago.format(message.createdAt),
                    style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 12),
            AvatarWidget(user: message.sender, size: 32, showBorder: false),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeContent(String content, bool isMe) {
    final parts = content.split('```');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.asMap().entries.map((entry) {
        final idx = entry.key;
        final text = entry.value;
        if (idx % 2 == 1) { // Inside code block
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.black.withValues(alpha: 0.3) : AppTheme.zinc950,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppTheme.zinc800 : AppTheme.zinc900),
            ),
            child: SelectableText(
              text.trim(),
              style: const TextStyle(
                color: AppTheme.white, 
                fontFamily: 'monospace', 
                fontSize: 12,
              ),
            ),
          );
        } else {
          return text.trim().isEmpty ? const SizedBox.shrink() : Text(
            text,
            style: TextStyle(
              color: isMe 
                  ? (isDark ? AppTheme.black : AppTheme.white) 
                  : (isDark ? AppTheme.white : AppTheme.black), 
              fontSize: 14, 
              height: 1.4
            ),
          );
        }
      }).toList(),
    );
  }

  Widget _buildActionArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14),
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: _isSending 
                  ? Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Theme.of(context).scaffoldBackgroundColor, strokeWidth: 2)))
                  : Icon(LucideIcons.send, color: Theme.of(context).scaffoldBackgroundColor, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
