import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:kizzu_ancien/models/challenge.dart';
import 'package:kizzu_ancien/providers/auth_provider.dart';
import 'package:kizzu_ancien/providers/challenge_provider.dart';
import 'package:kizzu_ancien/providers/notification_provider.dart';
import 'package:kizzu_ancien/providers/navigation_provider.dart';
import 'package:kizzu_ancien/providers/truth_dare_provider.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/screens/submit_proof_screen.dart';
import 'package:kizzu_ancien/screens/review_screen.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/custom_button.dart';

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
      // Only auto-fetch if we don't have data yet
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
    final truthDareProvider = context.watch<TruthDareProvider>();
    final navigationProvider = context.read<NavigationProvider>();
    final textTheme = Theme.of(context).textTheme;

    final pendingReviews = challengeProvider.challenges
        .where((c) => c.creator.id == user?.id && c.status == 'submitted')
        .toList();

    final activeChallenges = challengeProvider.challenges
        .where((c) => c.recipient.id == user?.id && c.status == 'pending')
        .toList();

    final pendingTruths = truthDareProvider.truths
        .where((t) => t['recipient']['_id'] == user?.id && t['status'] == 'pending')
        .toList();

    final pendingDares = truthDareProvider.dares
        .where((d) => d['recipient']['_id'] == user?.id && d['status'] == 'pending')
        .toList();

    final hasSocialTasks = pendingTruths.isNotEmpty || pendingDares.isNotEmpty;

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
                      child: _buildChallengeCard(context, challenge: activeChallenges[index]),
                    );
                  },
                  childCount: activeChallenges.length,
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.padding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildSectionTitle('RECENT ACTIVITY'),
                const SizedBox(height: 16),
                if (notificationProvider.isLoading && notificationProvider.notifications.isEmpty)
                  const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))
                else if (notificationProvider.notifications.isEmpty)
                  Text('All caught up!', style: textTheme.bodyMedium)
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.zinc950,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      border: Border.all(color: AppTheme.zinc900),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: notificationProvider.notifications.length > 3 ? 3 : notificationProvider.notifications.length,
                      separatorBuilder: (_, __) => const Divider(color: AppTheme.zinc900, height: 1),
                      itemBuilder: (context, index) {
                        final n = notificationProvider.notifications[index];
                        final isLast = index == (notificationProvider.notifications.length > 3 ? 2 : notificationProvider.notifications.length - 1);
                        return _ActivityItem(
                          text: n.message,
                          time: timeago.format(n.createdAt),
                          isLast: isLast,
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 140),
              ]),
            ),
          ),
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
    return Text(
      title,
      style: Theme.of(context).textTheme.labelSmall,
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

  Widget _buildChallengeCard(BuildContext context, {required Challenge challenge}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitProofScreen(challenge: challenge)));
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
              children: [
                AvatarWidget(user: challenge.creator, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.creator.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.white),
                      ),
                      Text(
                        'Requested verification',
                        style: const TextStyle(fontSize: 12, color: AppTheme.zinc500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.zinc900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    challenge.proofType.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc400),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              challenge.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.white),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 14, color: AppTheme.zinc600),
                const SizedBox(width: 6),
                Text(
                  'Due ${DateFormat('MMM d, h:mm a').format(challenge.deadline)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.zinc600),
                ),
                const Spacer(),
                const Text(
                  'Verify Now',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.white),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.arrowRight, size: 14, color: AppTheme.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String text;
  final String time;
  final bool isLast;

  const _ActivityItem({required this.text, required this.time, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.zinc700,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppTheme.zinc800,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 14, color: AppTheme.zinc300, height: 1.4),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: AppTheme.zinc600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
