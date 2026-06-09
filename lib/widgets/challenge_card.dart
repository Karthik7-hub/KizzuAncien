import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/challenge.dart';
import '../theme/app_theme.dart';
import '../screens/challenge_details_screen.dart';
import 'avatar_widget.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  
  const ChallengeCard({
    super.key, 
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = challenge.status == 'approved';
    final bool isSubmitted = challenge.status == 'submitted';
    final bool isDeclined = challenge.status == 'rejected';
    
    String actionText = 'Complete Challenge →';
    if (isSubmitted) {
      actionText = 'Awaiting Review →';
    } else if (isCompleted) {
      actionText = 'View Details →';
    } else if (isDeclined) {
      actionText = 'Declined →';
    }

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
          color: AppTheme.zinc900.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: AppTheme.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            isCompleted ? LucideIcons.checkCircle : LucideIcons.calendar, 
                            size: 12, 
                            color: isCompleted ? Colors.green : AppTheme.zinc500
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCompleted 
                                ? 'Completed on ${DateFormat('MMM d').format(challenge.updatedAt)}'
                                : 'Due ${DateFormat('MMM d, h:mm a').format(challenge.deadline)}',
                            style: TextStyle(
                              fontSize: 12, 
                              color: isCompleted ? Colors.green.withValues(alpha: 0.7) : AppTheme.zinc500
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AvatarWidget(user: challenge.recipient, size: 36),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.zinc800.withValues(alpha: 0.5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      challenge.proofType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        color: AppTheme.zinc400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDeclined ? AppTheme.zinc600 : AppTheme.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
