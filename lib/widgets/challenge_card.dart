import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/challenge.dart';
import '../theme/app_theme.dart';
import '../screens/challenge_details_screen.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final bool showParticipant;
  
  const ChallengeCard({
    super.key, 
    required this.challenge,
    this.showParticipant = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => ChallengeDetailsScreen(challenge: challenge))
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.zinc950,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: AppTheme.zinc900),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusText(challenge.status),
                Text(
                  DateFormat('MMM d').format(challenge.createdAt),
                  style: const TextStyle(color: AppTheme.zinc600, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              challenge.title,
              style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: AppTheme.white,
                letterSpacing: -0.5,
              ),
            ),
            if (showParticipant) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(LucideIcons.user, size: 12, color: AppTheme.zinc500),
                  const SizedBox(width: 6),
                  Text(
                    'With ${challenge.creator.name}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.zinc500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusText(String status) {
    String label = 'In Progress';
    Color color = Colors.blue;

    if (status == 'approved') {
      label = 'Completed';
      color = Colors.green;
    } else if (status == 'submitted') {
      label = 'Pending Review';
      color = Colors.orange;
    } else if (status == 'rejected') {
      label = 'Declined';
      color = Colors.red;
    }

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.w600, 
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
