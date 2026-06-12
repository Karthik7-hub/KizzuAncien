import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final bool isCompact;
  
  const ChallengeCard({
    super.key, 
    required this.challenge,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthProvider p) => p.user);
    final bool isCreator = challenge.creator.id == user?.id;

    final bool isCompleted = challenge.status == 'approved';
    final bool isSubmitted = challenge.status == 'submitted';
    final bool isDeclined = challenge.status == 'rejected';
    
    // Discussion unread count
    final int unreadCount = challenge.unreadCounts[user?.id] ?? 0;

    String actionText = isCreator ? 'Waiting for Friend' : 'Complete Challenge';
    if (isSubmitted) {
      actionText = isCreator ? 'Review Proof' : 'Reviewing...';
    } else if (isCompleted) {
      actionText = 'View Details';
    } else if (isDeclined) {
      actionText = 'Declined';
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context, 
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ChallengeDetailsScreen(challenge: challenge),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.03);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: animation.drive(tween), child: child),
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: AppTheme.zinc950,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.zinc900),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (challenge.coverImage != null && !isCompact)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: CachedNetworkImage(
                  imageUrl: challenge.coverImage!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppTheme.zinc900),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(isCompact ? 20 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildBadge(challenge.status.toUpperCase(), isCompleted ? Colors.green : AppTheme.zinc400),
                      const Spacer(),
                      if (unreadCount > 0) ...[
                        _buildUnreadBadge(unreadCount),
                        const SizedBox(width: 8),
                      ],
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
                  Hero(
                    tag: 'challenge_title_${challenge.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        challenge.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 20 : 22, 
                          fontWeight: FontWeight.bold, 
                          color: AppTheme.white,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      AvatarWidget(user: challenge.creator, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'by ${challenge.creator.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.zinc600, fontSize: 13),
                        ),
                      ),
                      const Icon(LucideIcons.arrowRight, size: 14, color: AppTheme.zinc800),
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
                        actionText.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDeclined ? AppTheme.zinc700 : AppTheme.white,
                          letterSpacing: 0.5,
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.zinc900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9, 
          fontWeight: FontWeight.bold, 
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildUnreadBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.messagesSquare, size: 10, color: Colors.black),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
