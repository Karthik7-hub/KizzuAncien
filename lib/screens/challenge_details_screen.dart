import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/challenge.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import 'submit_proof_screen.dart';
import 'review_screen.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ChallengeDetailsScreen extends StatelessWidget {
  final Challenge challenge;
  const ChallengeDetailsScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final bool isRecipient = challenge.recipient.id == user?.id;
    final bool isCreator = challenge.creator.id == user?.id;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        title: const Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.padding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(challenge.status),
                Text(
                  DateFormat('MMM d, yyyy').format(challenge.createdAt),
                  style: const TextStyle(color: AppTheme.zinc600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              challenge.title,
              style: textTheme.displayMedium?.copyWith(fontSize: 32, letterSpacing: -1),
            ),
            const SizedBox(height: 16),
            Text(
              challenge.description ?? 'No description provided.',
              style: const TextStyle(color: AppTheme.zinc400, fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 40),
            
            _buildSectionTitle('PARTICIPANTS'),
            const SizedBox(height: 16),
            _buildParticipantTile('Creator', challenge.creator),
            const SizedBox(height: 12),
            _buildParticipantTile('Recipient', challenge.recipient),
            
            const SizedBox(height: 40),
            _buildSectionTitle('TIMELINE'),
            const SizedBox(height: 16),
            _buildDetailRow('Created', DateFormat('MMM d, h:mm a').format(challenge.createdAt)),
            _buildDetailRow('Deadline', DateFormat('MMM d, h:mm a').format(challenge.deadline)),
            
            if (challenge.submission != null) ...[
              const SizedBox(height: 40),
              _buildSectionTitle('VERIFICATION'),
              const SizedBox(height: 16),
              _buildDetailRow('Submitted', DateFormat('MMM d, h:mm a').format(DateTime.parse(challenge.submission!['createdAt']))),
              _buildDetailRow('Type', challenge.submission!['proofUrl'] != null ? 'Media Evidence' : 'Text Verification'),
              if (challenge.submission!['proofText'] != null && challenge.submission!['proofText'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('RESPONSE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.zinc950,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.zinc900),
                  ),
                  child: Text(
                    challenge.submission!['proofText'],
                    style: const TextStyle(color: AppTheme.white, fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ],
            
            const SizedBox(height: 60),
            if (isRecipient && challenge.status == 'pending')
              _buildActionButton(
                context,
                'Submit Proof',
                LucideIcons.checkCircle,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitProofScreen(challenge: challenge))),
                isPrimary: true,
              ),
            if (isCreator && challenge.status == 'submitted')
              _buildActionButton(
                context,
                'Review Submission',
                LucideIcons.eye,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(challenge: challenge))),
                isPrimary: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1.5),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.zinc500, fontSize: 14)),
          Text(value, style: const TextStyle(color: AppTheme.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(String role, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.zinc900),
      ),
      child: Row(
        children: [
          AvatarWidget(user: user, size: 36),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: const TextStyle(color: AppTheme.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text(role, style: const TextStyle(color: AppTheme.zinc600, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String label = status.toUpperCase();
    Color color = AppTheme.zinc600;
    
    if (status == 'approved') {
      label = 'COMPLETED';
      color = Colors.green;
    } else if (status == 'submitted') {
      label = 'PENDING REVIEW';
      color = Colors.orange;
    } else if (status == 'pending') {
      label = 'IN PROGRESS';
      color = Colors.blue;
    } else if (status == 'rejected') {
      label = 'DECLINED';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text, IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppTheme.white : AppTheme.zinc900,
          foregroundColor: isPrimary ? AppTheme.black : AppTheme.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}
