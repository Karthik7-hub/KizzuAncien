import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/challenge.dart';
import '../models/note.dart';
import '../providers/challenge_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/app_header.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/note_preview_card.dart';
import 'note_viewer_screen.dart';
import 'discussion_screen.dart';

class ReviewScreen extends StatefulWidget {
  final Challenge challenge;
  const ReviewScreen({super.key, required this.challenge});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  Map<String, dynamic>? _submission;
  bool _isDataLoading = true;
  bool _isReviewing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    try {
      final sub = await context.read<ChallengeProvider>().fetchSubmission(widget.challenge.id);
      if (mounted) {
        setState(() {
          _submission = sub;
          _isDataLoading = false;
          if (sub == null) {
            _errorMessage = 'Could not load submission details.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDataLoading = false;
          _errorMessage = 'An error occurred while loading data.';
        });
      }
    }
  }

  Future<void> _handleReview(String status) async {
    if (_submission == null || _isReviewing) return;
    
    setState(() => _isReviewing = true);
    
    final submissionId = _submission!['_id'] as String;
    final provider = context.read<ChallengeProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final success = await provider.reviewSubmission(submissionId, status);
    
    if (mounted) {
      setState(() => _isReviewing = false);
      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(status == 'approved' ? 'Solution approved!' : 'Changes requested.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        navigator.pop();
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to submit review. Please try again.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AppHeader(
        title: 'Review Submission',
        showBackButton: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isDataLoading) {
      return Center(child: CircularProgressIndicator(color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: TextStyle(color: isDark ? AppTheme.zinc400 : AppTheme.zinc600)),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Go Back',
                onPressed: () => Navigator.pop(context),
                backgroundColor: isDark ? AppTheme.zinc900 : AppTheme.zinc200,
                textColor: isDark ? AppTheme.white : AppTheme.black,
              ),
            ],
          ),
        ),
      );
    }

    final selectedNotesJson = _submission?['selectedNotes'] as List?;
    final List<Note> selectedNotes = selectedNotesJson != null
        ? selectedNotesJson.map((n) => Note.fromJson(n)).toList()
        : [];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 24),
                _buildSummarySection(),
                const SizedBox(height: 24),
                _buildEvidenceSection(),
                const SizedBox(height: 24),
                _buildSelectedNotesSection(selectedNotes),
                const SizedBox(height: 24),
                _buildDiscussionLinkCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        _buildActionFooter(),
      ],
    );
  }

  Widget _buildHeaderCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          AvatarWidget(user: widget.challenge.recipient, size: 44, showBorder: false),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUBMITTED BY', 
                  style: TextStyle(color: isDark ? AppTheme.zinc500 : AppTheme.zinc600, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8)
                ),
                const SizedBox(height: 2),
                Text(
                  widget.challenge.recipient.name, 
                  style: TextStyle(color: isDark ? AppTheme.white : AppTheme.zinc950, fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final proofText = _submission?['proofText'] as String?;
    if (proofText == null || proofText.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'SUBMISSION SUMMARY'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Text(
            proofText,
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 15, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final proofUrl = _submission?['proofUrl'] as String?;
    if (proofUrl == null || proofUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'MEDIA EVIDENCE'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showFullScreenImage(context, proofUrl),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.zinc800 : AppTheme.zinc200),
              color: isDark ? AppTheme.zinc950 : AppTheme.zinc100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: proofUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: isDark ? AppTheme.zinc950 : AppTheme.zinc100,
                  child: Center(child: CircularProgressIndicator(color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 100,
                  color: isDark ? AppTheme.zinc950 : AppTheme.zinc100,
                  child: Icon(LucideIcons.imageOff, color: isDark ? AppTheme.zinc700 : AppTheme.zinc400),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedNotesSection(List<Note> selectedNotes) {
    if (selectedNotes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'SELECTED WORKSPACE NOTES'),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: selectedNotes.length,
          itemBuilder: (context, index) {
            final note = selectedNotes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NotePreviewCard(
                note: note,
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => NoteViewerScreen(note: note))
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDiscussionLinkCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'COMMUNICATION'),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => DiscussionScreen(challenge: widget.challenge))
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.messageSquare, color: Theme.of(context).primaryColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Discussion Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('View messages exchanged for this challenge.', style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 11)),
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

  Widget _buildActionFooter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isReviewing ? null : () => _handleReview('rejected'),
                  icon: const Icon(LucideIcons.xCircle, size: 16, color: Colors.redAccent),
                  label: const Text('Request Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isReviewing ? null : () => _handleReview('approved'),
                  icon: const Icon(LucideIcons.checkCircle, size: 16),
                  label: const Text('Approve Submission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: imageUrl),
            ),
          ),
        ),
      ),
    );
  }
}
