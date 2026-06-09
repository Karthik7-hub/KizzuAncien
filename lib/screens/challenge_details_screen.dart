import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import 'submit_proof_screen.dart';
import 'review_screen.dart';

class ChallengeDetailsScreen extends StatelessWidget {
  final Challenge challenge;
  const ChallengeDetailsScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final challengeProvider = context.watch<ChallengeProvider>();
    
    // Always use the latest data from the provider if available
    final currentChallenge = challengeProvider.challenges.firstWhere(
      (c) => c.id == challenge.id,
      orElse: () => challenge,
    );

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
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(currentChallenge),
            const SizedBox(height: 32),
            
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
              if (currentChallenge.submission!['createdAt'] != null)
                _buildInfoRow('Submitted', DateFormat('MMM d, h:mm a').format(DateTime.parse(currentChallenge.submission!['createdAt']))),
              
              _buildInfoRow('Type', currentChallenge.submission!['proofUrl'] != null ? 'Media Evidence' : 'Text Verification'),
              
              if (currentChallenge.submission!['proofUrl'] != null) ...[
                const SizedBox(height: 16),
                const Text('EVIDENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: currentChallenge.submission!['proofUrl'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(height: 200, color: AppTheme.zinc950, child: const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))),
                    errorWidget: (context, url, error) => Container(height: 100, color: AppTheme.zinc900, child: const Icon(LucideIcons.imageOff, color: AppTheme.zinc700)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (currentChallenge.submission!['proofText'] != null && currentChallenge.submission!['proofText'].toString().isNotEmpty) ...[
                const Text('RESPONSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                  currentChallenge.submission!['proofText'].toString(),
                  style: const TextStyle(color: AppTheme.white, fontSize: 14, height: 1.6),
                ),
              ],
            ],
            
            const SizedBox(height: 80),
            if (isRecipient && currentChallenge.status == 'pending')
              _buildPrimaryButton(
                context,
                'Submit Proof',
                LucideIcons.checkCircle,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitProofScreen(challenge: currentChallenge))),
              ),
            if (isCreator && currentChallenge.status == 'submitted')
              _buildPrimaryButton(
                context,
                'Review Submission',
                LucideIcons.eye,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(challenge: currentChallenge))),
              ),
            const SizedBox(height: 40),
          ],
        ),
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
}
