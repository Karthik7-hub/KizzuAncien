import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../theme/app_theme.dart';
import '../widgets/note_widgets.dart';
import '../widgets/custom_button.dart';
import '../widgets/avatar_widget.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import 'submit_proof_screen.dart';

class ChallengeDetailsScreen extends StatefulWidget {
  final Challenge challenge;
  const ChallengeDetailsScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailsScreen> createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
  int _selectedVersionNumber = 1;
  List<ChallengeActivity> _activities = [];
  bool _isLoadingActivities = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final challengeProvider = context.read<ChallengeProvider>();
    await Future.wait([
      challengeProvider.fetchMessages(widget.challenge.id),
      _loadActivities(),
    ]);
    
    final currentChallenge = challengeProvider.challenges.firstWhere(
      (c) => c.id == widget.challenge.id,
      orElse: () => widget.challenge,
    );
    
    if (currentChallenge.submission != null) {
      if (mounted) {
        setState(() {
          _selectedVersionNumber = currentChallenge.submission!.currentVersion;
        });
      }
    }
  }

  Future<void> _loadActivities() async {
    if (mounted) setState(() => _isLoadingActivities = true);
    final activities = await context.read<ChallengeProvider>().fetchActivities(widget.challenge.id);
    if (mounted) {
      setState(() {
        _activities = activities;
        _isLoadingActivities = false;
      });
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

    final bool isRecipient = currentChallenge.recipient.id == user?.id;
    final bool isCreator = currentChallenge.creator.id == user?.id;

    if (user == null) {
       return const Scaffold(
         backgroundColor: AppTheme.black,
         body: Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2)),
       );
    }

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(currentChallenge),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusOverview(currentChallenge),
                  const SizedBox(height: 32),
                  
                  // Challenge Description
                  if (currentChallenge.description != null && currentChallenge.description!.isNotEmpty) ...[
                    const Text(
                      'THE CHALLENGE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentChallenge.description!,
                      style: const TextStyle(color: AppTheme.zinc400, fontSize: 15, height: 1.6),
                    ),
                    const SizedBox(height: 48),
                  ],
                  
                  if (currentChallenge.submission != null) ...[
                    _buildSubmissionHeader(currentChallenge.submission!),
                    const SizedBox(height: 24),
                    _buildSubmissionCard(currentChallenge.submission!),
                    const SizedBox(height: 48),
                    _buildNotesSection(currentChallenge.submission!),
                    const SizedBox(height: 48),
                    _buildActivityTimeline(),
                  ] else ...[
                    _buildEmptySubmissionState(isRecipient, currentChallenge),
                  ],

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: currentChallenge.submission != null 
          ? _buildActionArea(context, currentChallenge, isRecipient, isCreator)
          : null,
    );
  }

  Widget _buildSliverAppBar(Challenge challenge) {
    return SliverAppBar(
      expandedHeight: 240,
      backgroundColor: AppTheme.black,
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.white),
        onPressed: () => Navigator.pop(context),
      ),
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (challenge.coverImage != null)
              Image.network(challenge.coverImage!, fit: BoxFit.cover)
            else
              Container(color: AppTheme.zinc900),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.black.withValues(alpha: 0.8),
                    AppTheme.black,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AvatarWidget(user: challenge.creator, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Created by ${challenge.creator.name}',
                        style: const TextStyle(color: AppTheme.zinc500, fontSize: 13),
                      ),
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

  Widget _buildStatusOverview(Challenge challenge) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.zinc900),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('STATUS', challenge.status.toUpperCase(), AppTheme.white),
          Container(width: 1, height: 32, color: AppTheme.zinc900),
          _buildStatItem(
            'DUE', 
            DateFormat('MMM d').format(challenge.deadline).toUpperCase(),
            AppTheme.zinc400
          ),
          Container(width: 1, height: 32, color: AppTheme.zinc900),
          _buildStatItem('TYPE', challenge.proofType.toUpperCase(), AppTheme.zinc400),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.zinc700, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildSubmissionHeader(ChallengeSubmission submission) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 3, height: 16, decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            const Text(
              'SUBMISSION',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.white, letterSpacing: 1.5),
            ),
          ],
        ),
        if (submission.versions.length > 1) _buildVersionDropdown(submission),
      ],
    );
  }

  Widget _buildSubmissionCard(ChallengeSubmission submission) {
    if (submission.versions.isEmpty) {
       return const Center(child: Text('No versions found', style: TextStyle(color: AppTheme.zinc600)));
    }

    final selectedVersion = submission.versions.firstWhere(
      (v) => v.versionNumber == _selectedVersionNumber,
      orElse: () => submission.versions.last,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.zinc900.withValues(alpha: 0.5), AppTheme.zinc950],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.zinc800.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildOverviewStat('VERSION', 'v${selectedVersion.versionNumber}', AppTheme.white),
              const Spacer(),
              _buildOverviewStat(
                'STATUS', 
                selectedVersion.status.toUpperCase(), 
                selectedVersion.status == 'approved' ? Colors.green : AppTheme.white
              ),
              const Spacer(),
              _buildOverviewStat('NOTES', '${selectedVersion.notes.length}', AppTheme.white),
            ],
          ),
          if (selectedVersion.reviewerNote != null && selectedVersion.reviewerNote!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(color: AppTheme.zinc900),
            const SizedBox(height: 16),
            const Text(
              'REVIEWER REMARKS',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Text(
              selectedVersion.reviewerNote!,
              style: const TextStyle(color: AppTheme.zinc400, fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.zinc700, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildVersionDropdown(ChallengeSubmission submission) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.zinc900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: DropdownButton<int>(
        value: _selectedVersionNumber,
        items: submission.versions.map((v) => DropdownMenuItem(
          value: v.versionNumber,
          child: Text('v${v.versionNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.white)),
        )).toList(),
        onChanged: (val) {
           if (val != null) setState(() => _selectedVersionNumber = val);
        },
        underline: const SizedBox(),
        icon: const Icon(LucideIcons.chevronDown, size: 12, color: AppTheme.zinc500),
        dropdownColor: AppTheme.zinc900,
        isDense: true,
      ),
    );
  }

  Widget _buildNotesSection(ChallengeSubmission submission) {
    if (submission.versions.isEmpty) return const SizedBox.shrink();

    final selectedVersion = submission.versions.firstWhere(
      (v) => v.versionNumber == _selectedVersionNumber,
      orElse: () => submission.versions.last,
    );
    
    final List<Note> sortedNotes = List.from(selectedVersion.notes);
    sortedNotes.sort((a, b) {
      final order = {'explanation': 0, 'code': 1, 'image': 2, 'link': 3};
      return (order[a.type] ?? 99).compareTo(order[b.type] ?? 99);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SOLUTION NOTES',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1.5),
        ),
        const SizedBox(height: 24),
        if (sortedNotes.isEmpty)
          const Text('No detailed notes provided for this version.', style: TextStyle(color: AppTheme.zinc800, fontSize: 13))
        else
          ...sortedNotes.map((note) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildNoteRenderer(note),
          )),
      ],
    );
  }

  Widget _buildNoteRenderer(Note note) {
    switch (note.type) {
      case 'explanation': return ExplanationNoteWidget(note: note);
      case 'code': return CodeNoteWidget(note: note);
      case 'image': return ImageNoteWidget(note: note);
      case 'link': return LinkNoteWidget(note: note);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildActivityTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTIVITY LOG',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1.5),
        ),
        const SizedBox(height: 32),
        if (_isLoadingActivities)
          const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.zinc800)))
        else if (_activities.isEmpty)
          const Text('No logs recorded yet.', style: TextStyle(color: AppTheme.zinc800, fontSize: 12))
        else
          ..._activities.map((a) => _buildActivityItem(a)),
      ],
    );
  }

  Widget _buildActivityItem(ChallengeActivity activity) {
    IconData icon = LucideIcons.circle;
    Color iconColor = AppTheme.zinc700;
    
    if (activity.type == 'submission_created') {
      icon = LucideIcons.plusCircle;
      iconColor = AppTheme.white;
    } else if (activity.type == 'submission_edited') {
      icon = LucideIcons.edit3;
    } else if (activity.type == 'approved') {
      icon = LucideIcons.checkCircle2;
      iconColor = Colors.green;
    } else if (activity.type == 'rejected') {
      icon = LucideIcons.xCircle;
      iconColor = Colors.redAccent;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, size: 14, color: iconColor),
              Expanded(
                child: Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: AppTheme.zinc900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      activity.user.name,
                      style: const TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(activity.createdAt),
                      style: const TextStyle(color: AppTheme.zinc800, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity.message ?? '',
                  style: const TextStyle(color: AppTheme.zinc600, fontSize: 12),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySubmissionState(bool isRecipient, Challenge challenge) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.zinc950,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.zinc900),
            ),
            child: const Icon(LucideIcons.fileQuestion, size: 40, color: AppTheme.zinc800),
          ),
          const SizedBox(height: 32),
          const Text(
            'PENDING SUBMISSION',
            style: TextStyle(color: AppTheme.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Text(
            isRecipient 
                ? 'Your friend is waiting for your solution.'
                : 'Waiting for your friend to upload their proof.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.zinc600, fontSize: 13),
          ),
          if (isRecipient) ...[
            const SizedBox(height: 40),
            CustomButton(
              text: 'Start Submission',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitProofScreen(challenge: challenge))),
              backgroundColor: AppTheme.white,
              textColor: AppTheme.black,
              width: 220,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, Challenge challenge, bool isRecipient, bool isCreator) {
    final submission = challenge.submission!;
    final latestVersion = submission.versions.last;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: AppTheme.black,
        border: Border(top: BorderSide(color: AppTheme.zinc900)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, -10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRecipient && latestVersion.status != 'approved')
            CustomButton(
              text: 'Edit Submission',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitProofScreen(challenge: challenge, existingSubmission: submission))),
              backgroundColor: AppTheme.zinc950,
              textColor: AppTheme.white,
              borderColor: AppTheme.zinc800,
            ),
          if (isCreator && latestVersion.status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Decline',
                    onPressed: () => _showReviewDialog(submission.id, 'rejected', latestVersion.versionNumber),
                    backgroundColor: AppTheme.zinc950,
                    textColor: Colors.redAccent,
                    borderColor: AppTheme.zinc900,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Verify',
                    onPressed: () => _showReviewDialog(submission.id, 'approved', latestVersion.versionNumber),
                    backgroundColor: AppTheme.white,
                    textColor: AppTheme.black,
                  ),
                ),
              ],
            ),
          ],
          if (submission.versions.length > 1) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showComparison(submission),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'COMPARE WITH PREVIOUS VERSION',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewDialog(String submissionId, String status, int versionNumber) {
    final noteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.zinc950,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${status == "approved" ? "Approve" : "Reject"} Submission v$versionNumber',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.white),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: noteController,
              maxLines: 4,
              style: const TextStyle(color: AppTheme.white),
              decoration: InputDecoration(
                hintText: 'Add a note for your friend (optional)',
                hintStyle: const TextStyle(color: AppTheme.zinc700),
                filled: true,
                fillColor: AppTheme.zinc900,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Confirm Review',
              onPressed: () async {
                final challengeProvider = context.read<ChallengeProvider>();
                final success = await challengeProvider.reviewSubmission(
                  submissionId, 
                  status, 
                  versionNumber, 
                  reviewerNote: noteController.text.trim()
                );
                if (mounted) {
                  Navigator.pop(context);
                  if (success) _loadData();
                }
              },
              backgroundColor: status == 'approved' ? AppTheme.white : AppTheme.zinc900,
              textColor: status == 'approved' ? AppTheme.black : Colors.redAccent,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showComparison(ChallengeSubmission submission) {
    if (submission.versions.length < 2) return;
    
    final current = submission.versions.last;
    final previous = submission.versions[submission.versions.length - 2];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.zinc950,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.zinc900, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('COMPARE CHANGES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc500, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text('v${previous.versionNumber} → v${current.versionNumber}', style: const TextStyle(color: AppTheme.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildComparisonGroup('ADDED NOTES', current.notes.where((n) => !previous.notes.any((pn) => pn.id == n.id)).toList(), AppTheme.white),
                  const SizedBox(height: 32),
                  _buildComparisonGroup('REMOVED NOTES', previous.notes.where((pn) => !current.notes.any((n) => n.id == pn.id)).toList(), AppTheme.zinc600),
                  const SizedBox(height: 32),
                  _buildComparisonGroup('MODIFIED NOTES', current.notes.where((n) {
                    final pn = previous.notes.where((pn) => pn.id == n.id);
                    return pn.isNotEmpty && pn.first.content != n.content;
                  }).toList(), AppTheme.zinc400, previousNotes: previous.notes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonGroup(String title, List<Note> notes, Color iconColor, {List<Note>? previousNotes}) {
    if (notes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.zinc500, letterSpacing: 1)),
        const SizedBox(height: 16),
        ...notes.map((n) {
          final pn = previousNotes?.where((prev) => prev.id == n.id).firstOrNull;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.zinc950,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.zinc900),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(n.type == 'code' ? LucideIcons.code : LucideIcons.fileText, size: 14, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(child: Text(n.title ?? 'Untitled ${n.type}', style: const TextStyle(color: AppTheme.white, fontSize: 13))),
                  ],
                ),
                if (pn != null) ...[
                  const SizedBox(height: 12),
                  const Text('PREVIOUS', style: TextStyle(fontSize: 8, color: AppTheme.zinc700, fontWeight: FontWeight.bold)),
                  Text(pn.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.zinc600, fontSize: 11, fontFamily: 'monospace')),
                  const SizedBox(height: 8),
                  const Text('CURRENT', style: TextStyle(fontSize: 8, color: AppTheme.zinc500, fontWeight: FontWeight.bold)),
                  Text(n.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.zinc400, fontSize: 11, fontFamily: 'monospace')),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
