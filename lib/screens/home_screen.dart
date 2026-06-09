import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:kizzu_ancien/providers/auth_provider.dart';
import 'package:kizzu_ancien/providers/challenge_provider.dart';
import 'package:kizzu_ancien/providers/navigation_provider.dart';
import 'package:kizzu_ancien/providers/notification_provider.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/screens/notifications_screen.dart';
import 'package:kizzu_ancien/screens/challenge_details_screen.dart';
import 'package:kizzu_ancien/screens/review_screen.dart';
import 'package:kizzu_ancien/models/challenge.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/challenge_card.dart';
import '../widgets/challenge_filter_dropdown.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  ChallengeCategory _selectedCategory = ChallengeCategory.all;

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
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<AuthProvider>().user;
    final challengeProvider = context.watch<ChallengeProvider>();
    final navigationProvider = context.read<NavigationProvider>();
    final textTheme = Theme.of(context).textTheme;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2)),
      );
    }

    // Workflows for Home
    final pendingReviews = challengeProvider.challenges
        .where((c) => c.creator.id == user.id && c.status == 'submitted')
        .toList();

    final activeChallenges = challengeProvider.challenges
        .where((c) => c.recipient.id == user.id && (c.status == 'pending' || c.status == 'submitted'))
        .toList();

    // Social Feed: Chronological by updatedAt
    final List<Challenge> recentActivity = challengeProvider.challenges
        .where((c) => c.status != 'pending')
        .toList();
    
    recentActivity.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final displayActivity = recentActivity.take(10).toList();

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good ${DateTime.now().hour < 12 ? "morning" : DateTime.now().hour < 17 ? "afternoon" : "evening"}',
              style: textTheme.labelLarge?.copyWith(color: AppTheme.zinc600),
            ),
            Text(
              user.name.split(" ")[0],
              style: textTheme.displayLarge?.copyWith(fontSize: 22),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, size: 20, color: AppTheme.zinc500),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                navigationProvider.setIndex(2);
              },
              child: AvatarWidget(user: user, size: 32, showBorder: true),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.white,
        backgroundColor: AppTheme.zinc950,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSummaryRow(user),
                  const SizedBox(height: 32),

                  if (pendingReviews.isNotEmpty) ...[
                    _buildSectionHeader('REQUIRED ATTENTION', color: AppTheme.white),
                    const SizedBox(height: 16),
                    ...pendingReviews.map((c) => _buildReviewActionItem(context, c)),
                    const SizedBox(height: 32),
                  ],

                  if (activeChallenges.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('ACTIVE CHALLENGES'),
                        ChallengeFilterDropdown(
                          selectedCategory: _selectedCategory,
                          onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...activeChallenges.where((c) {
                      if (_selectedCategory == ChallengeCategory.received) return c.recipient.id == user.id;
                      if (_selectedCategory == ChallengeCategory.sent) return c.creator.id == user.id;
                      return true;
                    }).map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ChallengeCard(challenge: c),
                    )),
                    const SizedBox(height: 32),
                  ],

                  _buildSectionHeader('SOCIAL FEED'),
                  const SizedBox(height: 12),
                  
                  if (displayActivity.isEmpty && !challengeProvider.isLoading)
                    _buildEmptyFeed()
                  else
                    ...displayActivity.map((c) => _ActivityItem(challenge: c)),
                  
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(dynamic user) {
    final stats = context.watch<AuthProvider>().stats;
    return Row(
      children: [
        _buildMiniStat('${stats['streak'] ?? 0}', 'BEST STREAK', LucideIcons.zap, AppTheme.white),
        const SizedBox(width: 24),
        _buildMiniStat('${stats['activeStreaks'] ?? 0}', 'ACTIVE STREAKS', LucideIcons.activity, AppTheme.white),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.white)),
            Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.zinc600, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {Color color = AppTheme.zinc500}) {
    return Row(
      children: [
        Container(width: 2, height: 10, decoration: BoxDecoration(color: color == AppTheme.white ? AppTheme.white : AppTheme.zinc700)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildReviewActionItem(BuildContext context, Challenge challenge) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(challenge: challenge))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.white.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.black,
              ),
              child: const Icon(LucideIcons.checkCircle2, color: AppTheme.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review verification',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.black, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'From ${challenge.recipient.name}',
                    style: TextStyle(fontSize: 13, color: AppTheme.black.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.arrowRight, color: AppTheme.black.withValues(alpha: 0.4), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'No recent activity.\nStart a challenge to see updates.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.zinc700, fontSize: 13, height: 1.5),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Challenge challenge;
  const _ActivityItem({required this.challenge});

  @override
  Widget build(BuildContext context) {
    String action = '';
    if (challenge.status == 'approved') action = 'completed a challenge';
    if (challenge.status == 'submitted') action = 'submitted proof';
    if (challenge.status == 'rejected') action = 'had a challenge declined';

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChallengeDetailsScreen(challenge: challenge))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            AvatarWidget(user: challenge.recipient, size: 36, showBorder: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppTheme.zinc400, fontSize: 13),
                      children: [
                        TextSpan(text: challenge.recipient.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.white)),
                        TextSpan(text: ' $action'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    challenge.title,
                    style: const TextStyle(color: AppTheme.zinc600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              timeago.format(challenge.updatedAt),
              style: const TextStyle(color: AppTheme.zinc800, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
