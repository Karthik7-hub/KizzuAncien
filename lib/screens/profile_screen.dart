import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';

import '../widgets/app_header.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user == null || authProvider.stats.isEmpty) {
        authProvider.checkAuth();
      }
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<AuthProvider>().checkAuth(),
      context.read<ChallengeProvider>().fetchChallenges(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final stats = authProvider.stats;

    if (user == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final bodyMediumColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      appBar: AppHeader(
        title: 'Profile',
        actions: [
          IconButton(
            icon: Icon(LucideIcons.settings, color: primaryColor, size: 22),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: primaryColor,
        backgroundColor: Theme.of(context).cardTheme.color,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // User Identity
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        AvatarWidget(user: user, size: 90, showBorder: true),
                        const SizedBox(height: 16),
                        Text(user.name, style: Theme.of(context).textTheme.displayLarge),
                        const SizedBox(height: 4),
                        Text('@${user.username}', style: TextStyle(fontSize: 14, color: bodyMediumColor, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        if (stats['streakFriend'] != null && stats['streakFriend'].toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.zinc900 : AppTheme.zinc100,
                              borderRadius: BorderRadius.circular(12),
                              border: isDark ? null : Border.all(color: AppTheme.zinc200),
                            ),
                            child: Text(
                              'Best streak with ${stats['streakFriend']}',
                              style: TextStyle(fontSize: 10, color: bodyMediumColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 1. Points Bank Card
                  _buildPointsBankCard(context, stats['pointsEarned'] ?? 0, stats['pointsSpent'] ?? 0),
                  const SizedBox(height: 20),

                  // 2. Grid Dashboard
                  GridView.count(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildGridStatCard(stats['longestStreak']?.toString() ?? '0', 'Longest Streak', LucideIcons.zap, const Color(0xFFFF9500)),
                      _buildGridStatCard(stats['streak']?.toString() ?? '0', 'Current Streak', LucideIcons.activity, const Color(0xFFFF5B00)),
                      _buildGridStatCard(stats['active']?.toString() ?? '0', 'Active Tasks', LucideIcons.playCircle, const Color(0xFF5856D6)),
                      _buildGridStatCard(stats['completed']?.toString() ?? '0', 'Completed', LucideIcons.checkCircle, const Color(0xFF34C759)),
                      _buildGridStatCard(stats['failed']?.toString() ?? '0', 'Failed', LucideIcons.xCircle, const Color(0xFFFF3B30)),
                      _buildGridStatCard(stats['friends']?.toString() ?? '0', 'Friends', LucideIcons.users, const Color(0xFF0A84FF)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Success Rate Card
                  _buildSuccessRateCard(stats['completed'] ?? 0, stats['failed'] ?? 0),
                  const SizedBox(height: 20),

                  // 4. Quick Toggles
                  _buildQuickTogglesCard(context, user, authProvider),

                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsBankCard(BuildContext context, int earned, int spent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balance = earned - spent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F12) : AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF1D1D22) : AppTheme.zinc200, width: 1.2),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withValues(alpha: isDark ? 0.1 : 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.sparkles, size: 14, color: Color(0xFFFFCC00)),
              ),
              const SizedBox(width: 8),
              Text(
                'POINTS BANK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.zinc500 : AppTheme.zinc600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$balance',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Available Balance',
                    style: TextStyle(fontSize: 11, color: AppTheme.zinc500, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),
              _buildPointsMiniStat('$earned', 'Earned', const Color(0xFF34C759), isDark),
              const SizedBox(width: 24),
              _buildPointsMiniStat('$spent', 'Spent', const Color(0xFFFF3B30), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointsMiniStat(String value, String label, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.zinc500, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGridStatCard(String value, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F12) : AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1D1D22) : AppTheme.zinc200, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.1 : 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.zinc500 : AppTheme.zinc600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessRateCard(int completed, int failed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = completed + failed;
    final successRate = total == 0 ? 0 : ((completed / total) * 100).toInt();

    Color rateColor = const Color(0xFF34C759); // Green
    if (successRate < 40) {
      rateColor = const Color(0xFFFF3B30); // Red
    } else if (successRate < 75) {
      rateColor = const Color(0xFFFF9500); // Amber
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F12) : AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF1D1D22) : AppTheme.zinc200, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CHALLENGE SUCCESS RATE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.zinc500 : AppTheme.zinc600,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '$successRate%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rateColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: successRate / 100.0,
              backgroundColor: isDark ? const Color(0xFF1D1D22) : AppTheme.zinc100,
              valueColor: AlwaysStoppedAnimation<Color>(rateColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed completed / $failed failed challenges total',
            style: const TextStyle(fontSize: 11, color: AppTheme.zinc500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTogglesCard(BuildContext context, dynamic user, AuthProvider authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F12) : AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF1D1D22) : AppTheme.zinc200, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK PRIVACY TOGGLES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.zinc500 : AppTheme.zinc600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          _buildToggleRow(
            'Allow Friend Requests',
            user.preferences.privacy.allowFriendRequests,
            (val) async {
              await authProvider.updatePreferences({
                'privacy': {
                  'allowFriendRequests': val,
                  'allowChallengeRequests': user.preferences.privacy.allowChallengeRequests,
                  'profileVisibility': user.preferences.privacy.profileVisibility,
                }
              });
            },
            isDark,
          ),
          const Divider(height: 16, color: Colors.transparent),
          _buildToggleRow(
            'Allow Challenge Requests',
            user.preferences.privacy.allowChallengeRequests,
            (val) async {
              await authProvider.updatePreferences({
                'privacy': {
                  'allowFriendRequests': user.preferences.privacy.allowFriendRequests,
                  'allowChallengeRequests': val,
                  'profileVisibility': user.preferences.privacy.profileVisibility,
                }
              });
            },
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: isDark ? AppTheme.zinc800 : AppTheme.black,
        ),
      ],
    );
  }
}
