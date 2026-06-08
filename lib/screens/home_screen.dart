import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:kizzu_ancien/providers/auth_provider.dart';
import 'package:kizzu_ancien/providers/challenge_provider.dart';
import 'package:kizzu_ancien/providers/notification_provider.dart';
import 'package:kizzu_ancien/providers/navigation_provider.dart';
import 'package:kizzu_ancien/providers/truth_dare_provider.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/screens/review_screen.dart';
import 'package:kizzu_ancien/screens/notifications_screen.dart';
import '../models/notification.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/custom_button.dart';
import '../widgets/challenge_card.dart';

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
      final challengeProvider = context.read<ChallengeProvider>();
      final truthDareProvider = context.read<TruthDareProvider>();
      if (challengeProvider.challenges.isEmpty || truthDareProvider.truths.isEmpty) {
        _refreshData();
      }
    });
  }

  Future<void> _refreshData() async {
    await Future.wait([
      context.read<ChallengeProvider>().fetchChallenges(),
      context.read<NotificationProvider>().fetchNotifications(),
      context.read<AuthProvider>().checkAuth(),
      context.read<TruthDareProvider>().fetchHistory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<AuthProvider>().user;
    final challengeProvider = context.watch<ChallengeProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final navigationProvider = context.read<NavigationProvider>();
    final textTheme = Theme.of(context).textTheme;

    final pendingReviews = challengeProvider.challenges
        .where((c) => c.creator.id == user?.id && c.status == 'submitted')
        .toList();

    final activeChallenges = challengeProvider.challenges
        .where((c) => c.recipient.id == user?.id && c.status == 'pending')
        .toList();

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.white,
      backgroundColor: AppTheme.zinc950,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.padding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good ${DateTime.now().hour < 12 ? "morning" : DateTime.now().hour < 17 ? "afternoon" : "evening"}',
                            style: textTheme.labelLarge,
                          ),
                          Text(
                            user?.name.split(" ")[0] ?? "Elite",
                            style: textTheme.displayLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        navigationProvider.setIndex(2);
                      },
                      child: user != null 
                        ? AvatarWidget(user: user, size: 48, showBorder: true)
                        : Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.zinc900)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Streak & Points Row
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryStat(
                        icon: LucideIcons.flame,
                        label: 'Day Streak',
                        value: '${user?.streak ?? 0}',
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryStat(
                        icon: LucideIcons.award,
                        label: 'Points',
                        value: '${user?.points ?? 0}',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                if (pendingReviews.isNotEmpty) ...[
                  _buildSectionTitle('REQUIRED ATTENTION'),
                  const SizedBox(height: 12),
                  ...pendingReviews.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildActionItem(
                      context,
                      icon: LucideIcons.checkCircle2,
                      title: 'Review verification',
                      subtitle: 'From ${c.recipient.name}',
                      iconColor: AppTheme.black,
                      iconBgColor: AppTheme.white,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(challenge: c))),
                    ),
                  )),
                  const SizedBox(height: 20),
                ],

                _buildSectionTitle('ACTIVE CHALLENGES'),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          
          if (challengeProvider.isLoading && activeChallenges.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2)),
            )
          else if (activeChallenges.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              sliver: SliverToBoxAdapter(
                child: _buildEmptyState(
                  icon: LucideIcons.zapOff,
                  msg: 'No active challenges.\nStart one to keep your streak.',
                  actionLabel: 'Browse Friends',
                  onAction: () => navigationProvider.setIndex(1),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ChallengeCard(challenge: activeChallenges[index]),
                    );
                  },
                  childCount: activeChallenges.length,
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('RECENT ACTIVITY'),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(color: AppTheme.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          if (notificationProvider.isLoading && notificationProvider.notifications.isEmpty)
            const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2)))
          else if (notificationProvider.notifications.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.zinc950,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(color: AppTheme.zinc900),
                  ),
                  child: Center(
                    child: Text('All caught up!', style: textTheme.bodyMedium),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.zinc950,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(color: AppTheme.zinc900),
                  ),
                  child: Column(
                    children: [
                      ...notificationProvider.notifications
                          .take(4)
                          .map((n) => _ActivityItem(notification: n))
                          .toList(),
                    ],
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }

  Widget _buildSummaryStat({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.zinc900),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.white)),
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.zinc500, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.zinc500,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String msg, String? actionLabel, VoidCallback? onAction}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.zinc900, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppTheme.zinc800),
          const SizedBox(height: 16),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.zinc600, fontSize: 14, height: 1.5),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            CustomButton(
              text: actionLabel,
              onPressed: onAction!,
              backgroundColor: AppTheme.white,
              textColor: AppTheme.black,
              width: 160,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.zinc600),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppTheme.zinc400, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final NotificationModel notification;

  const _ActivityItem({required this.notification});

  IconData _getIcon() {
    switch (notification.type) {
      case 'challenge_received':
        return LucideIcons.target;
      case 'challenge_update':
        return LucideIcons.refreshCw;
      case 'friend_request':
        return LucideIcons.userPlus;
      case 'friend_accept':
        return LucideIcons.userCheck;
      case 'truth_dare_received':
        return LucideIcons.zap;
      default:
        return LucideIcons.bell;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case 'challenge_received':
        return Colors.blue;
      case 'friend_request':
        return Colors.purple;
      case 'truth_dare_received':
        return Colors.amber;
      case 'friend_accept':
        return Colors.green;
      default:
        return AppTheme.zinc500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        // Handle navigation based on type if needed
        if (notification.type.contains('friend')) {
          context.read<NavigationProvider>().setIndex(2);
        } else if (notification.type.contains('challenge')) {
          context.read<NavigationProvider>().setIndex(1);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (notification.sender != null)
                  AvatarWidget(user: notification.sender!, size: 38, showBorder: false)
                else
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _getIconColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getIcon(), size: 18, color: _getIconColor()),
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.black,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _getIconColor(),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIcon(), 
                        size: 8, 
                        color: _getIconColor() == Colors.white ? Colors.black : Colors.white
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: AppTheme.zinc300, height: 1.4),
                      children: [
                        if (notification.sender != null)
                          TextSpan(
                            text: '${notification.sender!.name} ',
                            style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
                          ),
                        TextSpan(text: notification.message.replaceAll(notification.sender?.name ?? '', '').trim()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt),
                    style: const TextStyle(fontSize: 10, color: AppTheme.zinc600, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (!notification.read)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6, left: 8),
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
