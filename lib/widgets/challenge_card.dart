import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/challenge.dart';
import '../theme/app_theme.dart';
import '../screens/challenge_details_screen.dart';
import 'avatar_widget.dart';

import 'app_card.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String actionText = 'Complete Challenge →';
    if (isSubmitted) {
      actionText = 'Reviewing...';
    } else if (isCompleted) {
      actionText = 'View Details →';
    } else if (isDeclined) {
      actionText = 'Declined →';
    }

    return AppCard(
      padding: const EdgeInsets.all(20),
      color: isDark ? AppTheme.zinc900.withValues(alpha: 0.6) : AppTheme.zinc50,
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => ChallengeDetailsScreen(challenge: challenge))
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (challenge.coverImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: challenge.coverImage!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? AppTheme.white : AppTheme.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          isCompleted ? LucideIcons.checkCircle : LucideIcons.calendar, 
                          size: 12, 
                          color: isCompleted ? Colors.green : (isDark ? AppTheme.zinc500 : AppTheme.zinc600)
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCompleted 
                              ? 'Completed on ${DateFormat('MMM d').format(challenge.updatedAt)}'
                              : 'Due ${DateFormat('MMM d, h:mm a').format(challenge.deadline)}',
                          style: TextStyle(
                            fontSize: 12, 
                            color: isCompleted ? Colors.green.withValues(alpha: 0.7) : (isDark ? AppTheme.zinc500 : AppTheme.zinc600)
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
              border: Border(top: BorderSide(color: (isDark ? AppTheme.zinc800 : AppTheme.zinc200).withValues(alpha: 0.5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDeclined ? AppTheme.zinc600 : (isDark ? AppTheme.white : AppTheme.black),
                  ),
                ),
                const Icon(LucideIcons.arrowRight, size: 16, color: AppTheme.zinc500),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
