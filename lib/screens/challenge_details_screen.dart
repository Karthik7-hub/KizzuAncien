import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import 'submit_proof_screen.dart';
import 'review_screen.dart';

class ChallengeDetailsScreen extends StatefulWidget {
  final Challenge challenge;
  const ChallengeDetailsScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailsScreen> createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
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
    
    final currentChallenge = challengeProvider.challenges.firstWhere(
      (c) => c.id == widget.challenge.id,
      orElse: () => widget.challenge,
    );

    final messages = challengeProvider.challengeMessages[currentChallenge.id] ?? [];

    final bool isRecipient = currentChallenge.recipient.id == user?.id;
    final bool isCreator = currentChallenge.creator.id == user?.id;
    final textTheme = Theme.of(context).textTheme;

    if (user == null) {
       return const Scaffold(
         backgroundColor: AppTheme.black,
         body: Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2)),
       );
    }

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('CHALLENGE DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentChallenge.coverImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: currentChallenge.coverImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(height: 200, color: AppTheme.zinc900, child: const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))),
                        errorWidget: (context, url, error) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  _buildHeader(currentChallenge),
                  const SizedBox(height: 24),
                  
                  Text(
                    currentChallenge.title,
                    style: textTheme.displayMedium?.copyWith(fontSize: 28, letterSpacing: -0.5),
                  ),
                  if (currentChallenge.description != null && currentChallenge.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      currentChallenge.description!,
                      style: const TextStyle(color: AppTheme.zinc500, fontSize: 15, height: 1.5),
                    ),
                  ],
                  
                  const SizedBox(height: 48),
                  _buildSectionTitle('PARTICIPANTS'),
                  const SizedBox(height: 16),
                  _buildParticipantRow('Creator', currentChallenge.creator),
                  const SizedBox(height: 12),
                  _buildParticipantRow('Recipient', currentChallenge.recipient),
                  
                  const SizedBox(height: 48),
                  _buildSectionTitle('STATUS & TIMELINE'),
                  const SizedBox(height: 16),
                  _buildInfoRow('Current Status', currentChallenge.status.toUpperCase(), isValueBold: true),
                  _buildInfoRow('Created On', DateFormat('MMM d, yyyy').format(currentChallenge.createdAt)),
                  _buildInfoRow('Deadline', DateFormat('MMM d, h:mm a').format(currentChallenge.deadline)),
                  
                  if (currentChallenge.submission != null) ...[
                    const SizedBox(height: 48),
                    _buildSectionTitle('VERIFICATION'),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.zinc900.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.zinc800),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currentChallenge.submission!['proofUrl'] != null ? 'MEDIA EVIDENCE' : 'TEXT VERIFICATION',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1),
                              ),
                              if (currentChallenge.submission!['createdAt'] != null)
                                Text(
                                  timeago.format(DateTime.parse(currentChallenge.submission!['createdAt'])),
                                  style: const TextStyle(fontSize: 10, color: AppTheme.zinc700),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (currentChallenge.submission!['proofUrl'] != null) ...[
                            GestureDetector(
                              onTap: () => _showFullScreenImage(context, currentChallenge.submission!['proofUrl']),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: currentChallenge.submission!['proofUrl'],
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(height: 200, color: AppTheme.zinc950, child: const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))),
                                  errorWidget: (context, url, error) => Container(height: 100, color: AppTheme.zinc900, child: const Icon(LucideIcons.imageOff, color: AppTheme.zinc700)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          if (currentChallenge.submission!['proofText'] != null && currentChallenge.submission!['proofText'].toString().isNotEmpty) ...[
                            Text(
                              currentChallenge.submission!['proofText'].toString(),
                              style: const TextStyle(color: AppTheme.white, fontSize: 15, height: 1.6),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),
                  _buildSectionTitle('DISCUSSION'),
                  const SizedBox(height: 16),
                  if (messages.isEmpty)
                    const Center(child: Text('No messages yet. Start the conversation!', style: TextStyle(color: AppTheme.zinc700, fontSize: 12)))
                  else
                    ...messages.map((m) => _buildMessageItem(m, user.id)),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          _buildActionArea(context, currentChallenge, isRecipient, isCreator),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message, String currentUserId) {
    final bool isMe = message.sender.id == currentUserId;
    // Basic detection of code blocks (triple backticks)
    final bool hasCode = message.content.contains('```');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            AvatarWidget(user: message.sender, size: 24, showBorder: false),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(message.sender.name, style: const TextStyle(color: AppTheme.zinc600, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.white : AppTheme.zinc900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: hasCode 
                    ? _buildCodeContent(message.content, isMe)
                    : Text(
                        message.content,
                        style: TextStyle(color: isMe ? AppTheme.black : AppTheme.white, fontSize: 13),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(message.createdAt),
                  style: const TextStyle(color: AppTheme.zinc800, fontSize: 9),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            AvatarWidget(user: message.sender, size: 24, showBorder: false),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeContent(String content, bool isMe) {
    // Simple parsing for code blocks
    final parts = content.split('```');
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
              color: AppTheme.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.zinc800),
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
            style: TextStyle(color: isMe ? AppTheme.black : AppTheme.white, fontSize: 13),
          );
        }
      }).toList(),
    );
  }

  Widget _buildActionArea(BuildContext context, Challenge challenge, bool isRecipient, bool isCreator) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: AppTheme.black,
        border: Border(top: BorderSide(color: AppTheme.zinc900)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.zinc950,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.zinc900),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: AppTheme.white, fontSize: 14),
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: AppTheme.zinc700, fontSize: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isSending 
                    ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppTheme.black, strokeWidth: 2)))
                    : const Icon(LucideIcons.send, color: AppTheme.black, size: 18),
                ),
              ),
            ],
          ),
          if ((isRecipient && challenge.status == 'pending') || (isCreator && challenge.status == 'submitted')) ...[
            const SizedBox(height: 16),
            if (isRecipient && challenge.status == 'pending')
              _buildPrimaryButton(
                context,
                'Submit Proof',
                LucideIcons.checkCircle,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitProofScreen(challenge: challenge))),
              ),
            if (isCreator && challenge.status == 'submitted')
              _buildPrimaryButton(
                context,
                'Review Submission',
                LucideIcons.eye,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(challenge: challenge))),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(Challenge challenge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.zinc900,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            challenge.proofType.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc400, letterSpacing: 1),
          ),
        ),
        Text(
          timeago.format(challenge.createdAt),
          style: const TextStyle(color: AppTheme.zinc700, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 2, height: 10, decoration: const BoxDecoration(color: AppTheme.white)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc500, letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isValueBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.zinc600, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.white, 
              fontSize: 13, 
              fontWeight: isValueBold ? FontWeight.bold : FontWeight.w500,
              letterSpacing: isValueBold ? 0.5 : 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(String role, dynamic user) {
    return Row(
      children: [
        AvatarWidget(user: user, size: 32, showBorder: false),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: const TextStyle(color: AppTheme.white, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(role.toUpperCase(), style: const TextStyle(color: AppTheme.zinc700, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context, String text, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.white,
          foregroundColor: AppTheme.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
