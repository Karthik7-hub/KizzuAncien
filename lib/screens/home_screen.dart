import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:kizzu_ancien/screens/friends_screen.dart';
import 'package:kizzu_ancien/models/challenge.dart';
import '../widgets/avatar_widget.dart';

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
    final user = context.watch<AuthProvider>().user;
    final stats = context.watch<AuthProvider>().stats;
    final challengeProvider = context.watch<ChallengeProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2)),
      );
    }

    final today = DateTime.now();
    final activeChallenges = challengeProvider.challenges
        .where((c) => c.recipient.id == user.id && c.status == 'pending')
        .toList();
    
    final completedToday = challengeProvider.challenges
        .where((c) => c.recipient.id == user.id && 
                      c.status == 'approved' && 
                      c.updatedAt.day == today.day &&
                      c.updatedAt.month == today.month &&
                      c.updatedAt.year == today.year)
        .length;

    final recentFriendActivity = challengeProvider.challenges
        .where((c) => c.recipient.id != user.id && c.status != 'pending')
        .toList();
    recentFriendActivity.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final displayActivity = recentFriendActivity.take(5).toList();

    final recentNotifications = notificationProvider.notifications.take(3).toList();

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.white,
        backgroundColor: AppTheme.zinc950,
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

                  if (displayActivity.isNotEmpty) ...[
                    _buildSectionHeader('FRIEND ACTIVITY'),
                    const SizedBox(height: 16),
                    ...displayActivity.map((c) => _buildActivityItem(c)),
                    const SizedBox(height: 40),
                  ],

                  if (recentNotifications.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('NOTIFICATIONS'),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                          child: const Text('View All', style: TextStyle(color: AppTheme.zinc600, fontSize: 12, fontWeight: FontWeight.bold)),
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
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.zinc900),
        boxShadow: [
          BoxShadow(
            color: AppTheme.white.withValues(alpha: 0.03),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CURRENT STREAK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${stats['streak'] ?? 0}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.white, height: 1)),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text('DAYS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.zinc500)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.zinc900, borderRadius: BorderRadius.circular(16)),
                child: const Icon(LucideIcons.zap, color: Colors.amber, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(height: 1, color: AppTheme.zinc900),
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
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc500, letterSpacing: 1.5),
    );
  }

  Widget _buildTodayChallengeCard(Challenge challenge) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChallengeDetailsScreen(challenge: challenge))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.zinc900.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.zinc800),
        ),
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
                      Text(challenge.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.white)),
                      const SizedBox(height: 4),
                      Text('Due ${DateFormat('h:mm a').format(challenge.deadline)}', style: const TextStyle(fontSize: 12, color: AppTheme.zinc500)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: AppTheme.zinc700, size: 18),
              ],
            ),
          ],
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 64) / 3,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.zinc950,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.zinc900),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.white, size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.zinc400)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Challenge challenge) {
    String action = 'completed a challenge';
    if (challenge.status == 'submitted') action = 'submitted proof';
    if (challenge.status == 'rejected') action = 'had a challenge declined';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          AvatarWidget(user: challenge.recipient, size: 36, showBorder: false),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: AppTheme.zinc500, fontSize: 13),
                children: [
                  TextSpan(text: challenge.recipient.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.white)),
                  TextSpan(text: ' $action'),
                ],
              ),
            ),
          ),
          Text(timeago.format(challenge.updatedAt), style: const TextStyle(color: AppTheme.zinc800, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildNotificationPreviewItem(dynamic notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.zinc900),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.white, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notification.message,
              style: const TextStyle(color: AppTheme.zinc400, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
