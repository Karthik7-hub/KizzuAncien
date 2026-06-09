import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kizzu_ancien/models/challenge.dart';
import 'package:kizzu_ancien/providers/challenge_provider.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/widgets/custom_button.dart';
import '../widgets/avatar_widget.dart';
import '../utils/logger.dart';

class ReviewScreen extends StatefulWidget {
  final Challenge challenge;
  const ReviewScreen({super.key, required this.challenge});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  Map<String, dynamic>? _submission;
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
          'Verification',
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
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 12),
                  child: Text(
                    'EVIDENCE PROVIDED',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1.5),
                  ),
                ),
                _buildEvidenceSection(),
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

  Widget _buildEvidenceSection() {
    final proofUrl = _submission?['proofUrl'] as String?;
    final proofText = _submission?['proofText'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (proofUrl != null)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.zinc900),
              color: AppTheme.zinc950,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(
                imageUrl: proofUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: AppTheme.zinc950,
                  child: const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 100,
                  color: AppTheme.zinc950,
                  child: const Icon(LucideIcons.imageOff, color: AppTheme.zinc700),
                ),
              ),
            ),
          ),
        if (proofText != null && proofText.isNotEmpty)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: proofUrl != null ? 16 : 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.zinc900.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.zinc800),
            ),
            child: Text(
              proofText,
              style: const TextStyle(color: AppTheme.white, fontSize: 15, height: 1.6),
            ),
          ),
        if (proofUrl == null && (proofText == null || proofText.isEmpty))
          const Text('No evidence provided in this submission.', style: TextStyle(color: AppTheme.zinc600, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildActionFooter() {
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
    setState(() {
      if (status == 'approved') {
        _isVerifying = true;
      } else {
        _isDeclining = true;
      }
    });

    try {
      final success = await context.read<ChallengeProvider>().reviewSubmission(widget.challenge.id, status);
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
