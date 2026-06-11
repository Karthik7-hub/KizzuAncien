import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kizzu_ancien/models/challenge.dart';
import 'package:kizzu_ancien/providers/challenge_provider.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/widgets/custom_button.dart';
import 'package:kizzu_ancien/widgets/note_widgets.dart';
import '../widgets/avatar_widget.dart';
import '../utils/logger.dart';

class ReviewScreen extends StatefulWidget {
  final Challenge challenge;
  const ReviewScreen({super.key, required this.challenge});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  ChallengeSubmission? _submission;
  bool _isDataLoading = true;
  bool _isVerifying = false;
  bool _isDeclining = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review Verification',
          style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isDataLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2));
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
              Text(_errorMessage!, style: const TextStyle(color: AppTheme.zinc400)),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Go Back',
                onPressed: () => Navigator.pop(context),
                backgroundColor: AppTheme.zinc900,
                textColor: AppTheme.white,
              ),
            ],
          ),
        ),
      );
    }

    final latestVersion = _submission?.versions.last;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 32),
                if (latestVersion != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 16),
                    child: Text(
                      'SUBMISSION VERSION ${latestVersion.versionNumber}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc500, letterSpacing: 1.5),
                    ),
                  ),
                  ...latestVersion.notes.map((note) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildNoteRenderer(note),
                  )),
                ] else
                   const Center(child: Text('No notes provided.', style: TextStyle(color: AppTheme.zinc600))),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        _buildActionFooter(),
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

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.zinc900,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(user: widget.challenge.recipient, size: 36),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SUBMITTED BY', style: TextStyle(color: AppTheme.zinc600, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Text(widget.challenge.recipient.name, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.challenge.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter() {
    final latestVersion = _submission?.versions.last;
    if (latestVersion == null || latestVersion.status != 'pending') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: const BoxDecoration(
        color: AppTheme.black,
        border: Border(top: BorderSide(color: AppTheme.zinc900)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Decline',
              isLoading: _isDeclining,
              onPressed: (_isVerifying || _isDeclining) ? null : () => _handleReview('rejected'),
              backgroundColor: AppTheme.zinc900,
              textColor: AppTheme.white,
              borderColor: AppTheme.zinc800,
              icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              text: 'Verify',
              isLoading: _isVerifying,
              onPressed: (_isVerifying || _isDeclining) ? null : () => _handleReview('approved'),
              backgroundColor: AppTheme.white,
              textColor: AppTheme.black,
              icon: const Icon(LucideIcons.check, size: 18, color: AppTheme.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReview(String status) async {
    final latestVersion = _submission?.versions.last;
    if (latestVersion == null) return;

    setState(() {
      if (status == 'approved') {
        _isVerifying = true;
      } else {
        _isDeclining = true;
      }
    });

    try {
      final success = await context.read<ChallengeProvider>().reviewSubmission(
        _submission!.id, 
        status, 
        latestVersion.versionNumber
      );
      if (success && mounted) {
        Navigator.of(context).pop();
        return;
      }
    } catch (e) {
      AppLogger.error('Review failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status. Please try again.'))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isDeclining = false;
        });
      }
    }
  }
}
