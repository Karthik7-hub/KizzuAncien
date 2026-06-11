import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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
    final user = context.watch<AuthProvider>().user;
    final bool isCreator = challenge.creator.id == user?.id;

    final bool isCompleted = challenge.status == 'approved';
    final bool isSubmitted = challenge.status == 'submitted';
    final bool isDeclined = challenge.status == 'rejected';
    
    String actionText = isCreator ? 'Waiting for Friend →' : 'Complete Challenge →';
    if (isSubmitted) {
      actionText = isCreator ? 'Review Proof →' : 'Reviewing...';
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.zinc950,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.zinc900),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (challenge.coverImage != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: CachedNetworkImage(
                  imageUrl: challenge.coverImage!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppTheme.zinc900),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.zinc900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          challenge.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9, 
                            fontWeight: FontWeight.bold, 
                            color: AppTheme.zinc400,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isCompleted 
                          ? 'COMPLETED' 
                          : 'DUE ${DateFormat('MMM d').format(challenge.deadline).toUpperCase()}',
                        style: TextStyle(
                          color: isCompleted ? Colors.green : AppTheme.zinc700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: AppTheme.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AvatarWidget(user: challenge.creator, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'by ${challenge.creator.name}',
                        style: const TextStyle(color: AppTheme.zinc600, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.target, size: 14, color: AppTheme.zinc500),
                          const SizedBox(width: 8),
                          Text(
                            challenge.proofType.toUpperCase(),
                            style: const TextStyle(color: AppTheme.zinc500, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        actionText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDeclined ? AppTheme.zinc700 : AppTheme.white,
                        ),
                      ),
                    ],
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
