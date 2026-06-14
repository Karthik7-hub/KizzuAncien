import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/challenge.dart';
import '../models/message.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import 'review_screen.dart';
import 'main_screen.dart';
import 'submission_workspace_screen.dart';
import 'discussion_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';

class ChallengeDetailsScreen extends StatefulWidget {
  final Challenge challenge;
  const ChallengeDetailsScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailsScreen> createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeProvider>().fetchMessages(widget.challenge.id);
      context.read<ChallengeProvider>().fetchNotes(widget.challenge.id);
    });
  }

  void _safePop() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
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
    final notes = challengeProvider.challengeNotes[currentChallenge.id] ?? [];

    final bool isRecipient = currentChallenge.recipient.id == user?.id;
    final bool isCreator = currentChallenge.creator.id == user?.id;

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _safePop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppHeader(
          title: 'Challenge Details',
          showBackButton: true,
          leading: IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).primaryColor),
            onPressed: _safePop,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    context.read<ChallengeProvider>().fetchMessages(currentChallenge.id),
                    context.read<ChallengeProvider>().fetchNotes(currentChallenge.id),
                    context.read<ChallengeProvider>().fetchChallenges(),
                  ]);
                },
                color: Theme.of(context).primaryColor,
                backgroundColor: Theme.of(context).cardTheme.color,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeaderCard(currentChallenge),
                      const SizedBox(height: 24),
                      _buildDescriptionCard(currentChallenge),
                      const SizedBox(height: 24),
                      _buildActionCards(currentChallenge),
                      const SizedBox(height: 24),
                      _buildActivityTimeline(currentChallenge, notes, messages),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            _buildActionArea(context, currentChallenge, isRecipient, isCreator),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Challenge challenge) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    // Status color mapping
    Color statusColor;
    Color statusBgColor;
    switch (challenge.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusBgColor = Colors.green.withValues(alpha: 0.15);
        break;
      case 'rejected':
        statusColor = isDark ? AppTheme.zinc400 : AppTheme.zinc600;
        statusBgColor = isDark ? AppTheme.zinc900 : AppTheme.zinc100;
        break;
      case 'submitted':
        statusColor = AppTheme.accent;
        statusBgColor = AppTheme.accent.withValues(alpha: 0.15);
        break;
      default:
        statusColor = isDark ? AppTheme.zinc400 : AppTheme.zinc600;
        statusBgColor = isDark ? AppTheme.zinc900 : AppTheme.zinc100;
    }

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  challenge.status.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 1),
                ),
              ),
              Text(
                'Due ${DateFormat('MMM d, yyyy').format(challenge.deadline)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.labelSmall?.color),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            challenge.title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: -0.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildParticipantInfo('CREATOR', challenge.creator)),
              Container(width: 1, height: 32, color: isDark ? AppTheme.zinc800 : AppTheme.zinc200, margin: const EdgeInsets.symmetric(horizontal: 16)),
              Expanded(child: _buildParticipantInfo('RECIPIENT', challenge.recipient)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantInfo(String role, dynamic user) {
    return Row(
      children: [
        AvatarWidget(user: user, size: 36, showBorder: false),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role, 
                style: TextStyle(
                  fontSize: 8, 
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).textTheme.labelSmall?.color, 
                  letterSpacing: 0.8
                )
              ),
              Text(
                user.name, 
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: FontWeight.w600, 
                  color: Theme.of(context).textTheme.bodyMedium?.color
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(Challenge challenge) {
    if (challenge.description == null || challenge.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'CHALLENGE DESCRIPTION'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Text(
            challenge.description!,
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards(Challenge challenge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'COLLABORATION'),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmissionWorkspaceScreen(challenge: challenge))),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.layers, color: Theme.of(context).primaryColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Open Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).primaryColor)),
                    const SizedBox(height: 2),
                    Text('Write and structure collaborative notes.', style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 11)),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: Theme.of(context).textTheme.labelSmall?.color, size: 16),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DiscussionScreen(challenge: challenge))),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.messageSquare, color: Theme.of(context).primaryColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Open Discussion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).primaryColor)),
                    const SizedBox(height: 2),
                    Text('Chat about rules and requirements.', style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 11)),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: Theme.of(context).textTheme.labelSmall?.color, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTimeline(Challenge challenge, List<Note> notes, List<Message> messages) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Collect dynamic events
    final List<Map<String, dynamic>> events = [];
    
    events.add({
      'title': 'Challenge Launched',
      'subtitle': 'Created by ${challenge.creator.name}',
      'time': challenge.createdAt,
      'icon': LucideIcons.rocket,
      'color': isDark ? AppTheme.zinc500 : AppTheme.zinc600,
    });

    if (notes.isNotEmpty) {
      // Find latest note update
      final latestNote = notes.reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b);
      events.add({
        'title': 'Workspace Active',
        'subtitle': '${notes.length} note(s) created. Latest by ${latestNote.createdBy.name}',
        'time': latestNote.updatedAt,
        'icon': LucideIcons.layers,
        'color': AppTheme.accent,
      });
    }

    if (messages.isNotEmpty) {
      events.add({
        'title': 'Discussion Active',
        'subtitle': '${messages.length} message(s) exchanged. Latest by ${messages.last.sender.name}',
        'time': messages.last.createdAt,
        'icon': LucideIcons.messageCircle,
        'color': AppTheme.accent,
      });
    }

    if (challenge.status == 'submitted' && challenge.updatedAt != challenge.createdAt) {
      events.add({
        'title': 'Solution Submitted',
        'subtitle': 'Awaiting creator review',
        'time': challenge.updatedAt,
        'icon': LucideIcons.checkSquare,
        'color': AppTheme.accent,
      });
    } else if (challenge.status == 'approved') {
      events.add({
        'title': 'Challenge Completed',
        'subtitle': 'Solution approved by ${challenge.creator.name}',
        'time': challenge.updatedAt,
        'icon': LucideIcons.checkCircle,
        'color': Colors.green,
      });
    } else if (challenge.status == 'rejected') {
      events.add({
        'title': 'Changes Requested',
        'subtitle': 'Sent back by ${challenge.creator.name}',
        'time': challenge.updatedAt,
        'icon': LucideIcons.xCircle,
        'color': isDark ? AppTheme.zinc500 : AppTheme.zinc600,
      });
    }

    // Sort events latest first
    events.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'CHALLENGE ACTIVITY'),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final ev = events[index];
            final bool isLast = index == events.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: (ev['color'] as Color).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(ev['icon'] as IconData, size: 14, color: ev['color'] as Color),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppTheme.zinc800 
                                : AppTheme.zinc200,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ev['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(timeago.format(ev['time'] as DateTime), style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(ev['subtitle'] as String, style: TextStyle(color: Theme.of(context).textTheme.labelLarge?.color, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionArea(BuildContext context, Challenge challenge, bool isRecipient, bool isCreator) {
    // The action area triggers:
    // - For Recipient: "Build Solution" (Workspace) when status is pending or rejected
    // - For Creator: "Review Submission" when status is submitted
    final bool showRecipientPending = isRecipient && (challenge.status == 'pending' || challenge.status == 'rejected' || challenge.status == 'expired');
    final bool showCreatorSubmitted = isCreator && challenge.status == 'submitted';

    if (!(showRecipientPending || showCreatorSubmitted)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(context).bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200)),
      ),
      child: showRecipientPending
          ? _buildPrimaryButton(
              context,
              'Build Solution',
              LucideIcons.edit3,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmissionWorkspaceScreen(challenge: challenge))),
            )
          : _buildPrimaryButton(
              context,
              'Review Submission',
              LucideIcons.eye,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(challenge: challenge))),
            ),
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
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}
