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
import 'submit_proof_screen.dart';
import 'review_screen.dart';

class ChallengeDetailsScreen extends StatelessWidget {
  final Challenge challenge;
  const ChallengeDetailsScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final bool isRecipient = challenge.recipient.id == user?.id;
    final bool isCreator = challenge.creator.id == user?.id;
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
            _buildHeader(challenge),
            const SizedBox(height: 32),
            
            Text(
              challenge.title,
              style: textTheme.displayMedium?.copyWith(fontSize: 28, letterSpacing: -0.5),
            ),
            if (challenge.description != null && challenge.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                challenge.description!,
                style: const TextStyle(color: AppTheme.zinc500, fontSize: 15, height: 1.5),
              ),
            ],
            
            const SizedBox(height: 48),
            _buildSectionTitle('PARTICIPANTS'),
            const SizedBox(height: 16),
            _buildParticipantRow('Creator', challenge.creator),
            const SizedBox(height: 12),
            _buildParticipantRow('Recipient', challenge.recipient),
            
            const SizedBox(height: 48),
            _buildSectionTitle('STATUS & TIMELINE'),
            const SizedBox(height: 16),
            _buildInfoRow('Current Status', challenge.status.toUpperCase(), isValueBold: true),
            _buildInfoRow('Created On', DateFormat('MMM d, yyyy').format(challenge.createdAt)),
            _buildInfoRow('Deadline', DateFormat('MMM d, h:mm a').format(challenge.deadline)),
            
            if (challenge.submission != null) ...[
              const SizedBox(height: 48),
              _buildSectionTitle('VERIFICATION'),
              const SizedBox(height: 16),
              if (challenge.submission!['proofUrl'] != null) ...[
                const Text('EVIDENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: challenge.submission!['proofUrl'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(height: 200, color: AppTheme.zinc950, child: const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))),
                    errorWidget: (context, url, error) => const Icon(LucideIcons.imageOff, color: AppTheme.zinc700),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (challenge.submission!['proofText'] != null && challenge.submission!['proofText'].toString().isNotEmpty) ...[
                const Text('RESPONSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                  challenge.submission!['proofText'],
                  style: const TextStyle(color: AppTheme.white, fontSize: 14, height: 1.6),
                ),
              ],
            ],
            
            const SizedBox(height: 80),
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
