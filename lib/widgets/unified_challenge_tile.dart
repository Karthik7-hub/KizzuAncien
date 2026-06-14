import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/challenge.dart';
import '../theme/app_theme.dart';
import '../screens/challenge_details_screen.dart';
import 'avatar_widget.dart';
import 'app_card.dart';

enum ChallengeTileVariant { compact, full }

class UnifiedChallengeTile extends StatelessWidget {
  final Challenge challenge;
  final ChallengeTileVariant variant;

  const UnifiedChallengeTile({
    super.key,
    required this.challenge,
    this.variant = ChallengeTileVariant.full,
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
      padding: EdgeInsets.all(variant == ChallengeTileVariant.compact ? 16 : 20),
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? AppTheme.zinc900.withValues(alpha: 0.4) : AppTheme.zinc50,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChallengeDetailsScreen(challenge: challenge)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (variant == ChallengeTileVariant.full && challenge.coverImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: challenge.coverImage!,
                height: 140,
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
                        fontSize: variant == ChallengeTileVariant.compact ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white : AppTheme.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isCompleted ? LucideIcons.checkCircle : LucideIcons.calendar,
                          size: 12,
                          color: isCompleted ? Colors.green : (isDark ? AppTheme.zinc500 : AppTheme.zinc600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCompleted
                              ? 'Completed on ${DateFormat('MMM d').format(challenge.updatedAt)}'
                              : 'Due ${DateFormat('MMM d, h:mm a').format(challenge.deadline)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCompleted ? Colors.green.withValues(alpha: 0.7) : (isDark ? AppTheme.zinc500 : AppTheme.zinc600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AvatarWidget(user: challenge.recipient, size: variant == ChallengeTileVariant.compact ? 32 : 36),
            ],
          ),
          if (variant == ChallengeTileVariant.full) ...[
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
                  Icon(
                    LucideIcons.chevronRight,
                    color: isDark ? AppTheme.zinc700 : AppTheme.zinc400,
                    size: 18,
                  ),
                ],
              ),
            ),
          ] else ...[
             const SizedBox(height: 4),
             if (isSubmitted) 
               Text('Reviewing...', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.zinc500 : AppTheme.zinc600, fontWeight: FontWeight.bold)),
          ]
        ],
      ),
    );
  }
}
