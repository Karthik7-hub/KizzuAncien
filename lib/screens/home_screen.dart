import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:kizzu_ancien/providers/auth_provider.dart';
import 'package:kizzu_ancien/providers/challenge_provider.dart';
import 'package:kizzu_ancien/providers/navigation_provider.dart';
import 'package:kizzu_ancien/providers/notification_provider.dart';
import 'package:kizzu_ancien/providers/friend_provider.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/screens/notifications_screen.dart';
import 'package:kizzu_ancien/screens/challenge_details_screen.dart';
import 'package:kizzu_ancien/models/challenge.dart';
import 'package:kizzu_ancien/models/user.dart';
import '../widgets/section_header.dart';

import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/app_header.dart';

import '../widgets/app_card.dart';

import '../widgets/unified_user_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    await Future.wait([
      context.read<ChallengeProvider>().fetchChallenges(),
      context.read<NotificationProvider>().fetchNotifications(),
      context.read<AuthProvider>().checkAuth(),
      context.read<FriendProvider>().fetchFriends(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.select<AuthProvider, User?>((p) => p.user);
    final stats = context.select<AuthProvider, Map<String, dynamic>>((p) => p.stats);
    final challenges = context.select<ChallengeProvider, List<Challenge>>((p) => p.challenges);
    final notifications = context.select<NotificationProvider, List<dynamic>>((p) => p.notifications);
    
    if (user == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
      );
    }

    final hasUnread = notifications.any((n) => !n.read);

    final today = DateTime.now();
    final activeChallenges = challenges
        .where((c) => c.recipient.id == user.id && c.status == 'pending')
        .toList();
    
    final completedToday = challenges
        .where((c) => c.recipient.id == user.id && 
                      c.status == 'approved' && 
                      c.updatedAt.day == today.day &&
                      c.updatedAt.month == today.month &&
                      c.updatedAt.year == today.year)
        .length;

    final recentFriendActivity = challenges
        .where((c) => c.recipient.id != user.id && c.status != 'pending')
        .take(5)
        .toList();

    final recentNotifications = notifications.take(3).toList();

    return Scaffold(
      appBar: AppHeader(
        title: 'KizzuAncien',
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SvgPicture.asset(
                'assets/logo.svg',
                width: 28,
                height: 28,
              ),
            ),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(LucideIcons.bell, color: Theme.of(context).primaryColor, size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              if (hasUnread)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).cardTheme.color,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeroCard(stats, completedToday, activeChallenges.length),
                  const SizedBox(height: 32),
                  
                  if (activeChallenges.isNotEmpty) ...[
                    _buildSectionHeader('TODAY\'S CHALLENGES'),
                    const SizedBox(height: 16),
                    ...activeChallenges.map((c) => _buildTodayChallengeCard(c)),
                    const SizedBox(height: 32),
                  ],

                  _buildSectionHeader('QUICK ACTIONS'),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 40),

                  if (recentFriendActivity.isNotEmpty) ...[
                    _buildSectionHeader('FRIEND ACTIVITY'),
                    const SizedBox(height: 16),
                    ...recentFriendActivity.map((c) => _buildActivityItem(c)),
                    const SizedBox(height: 40),
                  ],

                  if (recentNotifications.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('NOTIFICATIONS'),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                          child: Text(
                            'View All', 
                            style: TextStyle(
                              color: Theme.of(context).textTheme.labelSmall?.color, 
                              fontSize: 12, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...recentNotifications.map((n) => _buildNotificationPreviewItem(n)),
                  ],

                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> stats, int completed, int remaining) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      padding: const EdgeInsets.all(32),
      boxShadow: [
        BoxShadow(
          color: (isDark ? AppTheme.white : AppTheme.black).withValues(alpha: 0.03),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT STREAK', 
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold, 
                      color: Theme.of(context).textTheme.labelSmall?.color, 
                      letterSpacing: 1.5
                    )
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${stats['streak'] ?? 0}', 
                        style: TextStyle(
                          fontSize: 48, 
                          fontWeight: FontWeight.bold, 
                          color: Theme.of(context).primaryColor, 
                          height: 1
                        )
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'DAYS', 
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold, 
                            color: Theme.of(context).textTheme.labelLarge?.color
                          )
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.zinc900 : AppTheme.zinc100, 
                  borderRadius: BorderRadius.circular(16)
                ),
                child: const Icon(LucideIcons.zap, color: Colors.amber, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(height: 1, color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildHeroStat('$completed', 'COMPLETED TODAY'),
              const SizedBox(width: 48),
              _buildHeroStat('$remaining', 'REMAINING'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value, 
          style: TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold, 
            color: Theme.of(context).primaryColor
          )
        ),
        const SizedBox(height: 4),
        Text(
          label, 
          style: TextStyle(
            fontSize: 9, 
            fontWeight: FontWeight.bold, 
            color: Theme.of(context).textTheme.labelSmall?.color, 
            letterSpacing: 0.5
          )
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return SectionHeader(title: title);
  }

  Widget _buildTodayChallengeCard(Challenge challenge) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      color: isDark ? AppTheme.zinc900.withValues(alpha: 0.4) : AppTheme.zinc50,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChallengeDetailsScreen(challenge: challenge))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (challenge.coverImage != null)
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
                        color: Theme.of(context).primaryColor
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due ${DateFormat('h:mm a').format(challenge.deadline)}', 
                      style: TextStyle(
                        fontSize: 12, 
                        color: Theme.of(context).textTheme.labelLarge?.color
                      )
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight, 
                color: Theme.of(context).textTheme.labelSmall?.color, 
                size: 18
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionBtn(LucideIcons.plus, 'Create', () => context.read<NavigationProvider>().setIndex(2)),
        _buildActionBtn(LucideIcons.userPlus, 'Add Friend', () => context.read<NavigationProvider>().setIndex(3)),
        _buildActionBtn(LucideIcons.layoutList, 'Challenges', () => context.read<NavigationProvider>().setIndex(1)),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 64) / 3,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(height: 8),
            Text(
              label, 
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: Theme.of(context).textTheme.bodyMedium?.color
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Challenge challenge) {
    String action = 'completed a challenge';
    if (challenge.status == 'submitted') action = 'submitted proof';
    if (challenge.status == 'rejected') action = 'had a challenge declined';

    return UnifiedUserTile(
      user: challenge.recipient,
      variant: UserTileVariant.activity,
      subtitle: action,
      trailing: Text(
        timeago.format(challenge.updatedAt), 
        style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 10)
      ),
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => ChallengeDetailsScreen(challenge: challenge))
      ),
    );
  }

  Widget _buildNotificationPreviewItem(dynamic notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
      ),
      child: Row(
        children: [
          Container(
            width: 4, 
            height: 4, 
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor, 
              shape: BoxShape.circle
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notification.message,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color, 
                fontSize: 12
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
