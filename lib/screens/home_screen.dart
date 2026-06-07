import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:kizzu_ancien/models/challenge.dart';
import 'package:kizzu_ancien/providers/auth_provider.dart';
import 'package:kizzu_ancien/providers/challenge_provider.dart';
import 'package:kizzu_ancien/providers/notification_provider.dart';
import 'package:kizzu_ancien/providers/navigation_provider.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/screens/submit_proof_screen.dart';
import 'package:kizzu_ancien/screens/review_screen.dart';
import '../widgets/avatar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    final user = context.watch<AuthProvider>().user;
    final challengeProvider = context.watch<ChallengeProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final navigationProvider = context.read<NavigationProvider>();

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.white,
      backgroundColor: AppTheme.zinc900,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simplified User Status Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.zinc900,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.zinc800),
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'profile-pic',
                    child: user != null 
                        ? AvatarWidget(user: user, size: 54)
                        : Container(width: 54, height: 54, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.zinc800)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hey ${user?.name.split(" ")[0] ?? "there"}!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.flame, size: 14, color: Colors.orangeAccent),
                            const SizedBox(width: 4),
                            Text(
                              '${user?.streak ?? 0} Day Streak',
                              style: const TextStyle(fontSize: 14, color: AppTheme.zinc400),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.zinc800),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.award, size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          '${user?.points ?? 0}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('REQUIRED ATTENTION'),
            const SizedBox(height: 12),
            _buildActionItem(
              context,
              icon: LucideIcons.plus,
              title: "Challenge a Friend",
              subtitle: 'Keep your streak alive today',
              iconColor: AppTheme.black,
              iconBgColor: AppTheme.white,
              onTap: () => navigationProvider.setIndex(1),
            ),
            
            // Pending Reviews
            ...challengeProvider.challenges
                .where((c) => c.creator.id == user?.id && c.status == 'submitted')
                .map((c) => Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildActionItem(
                        context,
                        icon: LucideIcons.checkCircle2,
                        title: 'Review proof',
                        subtitle: 'From ${c.recipient.name}',
                        iconColor: AppTheme.white,
                        iconBgColor: AppTheme.zinc800,
                        showBorder: true,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(challenge: c))),
                      ),
                    )),

            const SizedBox(height: 32),

            _buildSectionTitle('ACTIVE CHALLENGES'),
            const SizedBox(height: 12),
            challengeProvider.isLoading 
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2),
                ))
              : challengeProvider.challenges.where((c) => c.recipient.id == user?.id && c.status == 'pending').isEmpty
                ? _buildEmptyState('No active challenges. Go send some!')
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: challengeProvider.challenges.where((c) => c.recipient.id == user?.id && c.status == 'pending').length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = challengeProvider.challenges.where((c) => c.recipient.id == user?.id && c.status == 'pending').toList()[index];
                      return _buildChallengeCard(context, challenge: c);
                    },
                  ),
            const SizedBox(height: 32),

            _buildSectionTitle('RECENT ACTIVITY'),
            const SizedBox(height: 16),
            notificationProvider.isLoading && notificationProvider.notifications.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))
              : notificationProvider.notifications.isEmpty
                ? const Text('All caught up!', style: TextStyle(color: AppTheme.zinc600))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notificationProvider.notifications.length > 5 ? 5 : notificationProvider.notifications.length,
                    itemBuilder: (context, index) {
                      final n = notificationProvider.notifications[index];
                      return _ActivityItem(
                        text: n.message,
                        time: timeago.format(n.createdAt),
                        isLast: index == (notificationProvider.notifications.length > 5 ? 4 : notificationProvider.notifications.length - 1),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.zinc500,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.zinc900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.zinc800.withValues(alpha: 0.5), style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.zinc600, fontSize: 14),
        ),
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
    bool showBorder = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.zinc900,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
                border: showBorder ? Border.all(color: AppTheme.zinc700) : null,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: AppTheme.zinc500),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppTheme.zinc700, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, {required Challenge challenge}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitProofScreen(challenge: challenge))),
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
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 12, color: AppTheme.zinc500),
                          const SizedBox(width: 6),
                          Text(
                            'Due ${DateFormat('MMM d, h:mm a').format(challenge.deadline)}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.zinc500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AvatarWidget(user: challenge.creator, size: 36),
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
                      'Mode: ${challenge.proofType}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.zinc400, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Text(
                    'Complete Challenge →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
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
