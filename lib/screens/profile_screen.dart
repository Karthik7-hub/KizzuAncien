import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';

import '../widgets/app_header.dart';
import 'settings_screen.dart';

import '../widgets/app_card.dart';

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
                        AvatarWidget(user: user, size: 100, showBorder: true),
                        const SizedBox(height: 20),
                        Text(user.name, style: Theme.of(context).textTheme.displayLarge),
                        const SizedBox(height: 4),
                        Text('@${user.username}', style: TextStyle(fontSize: 15, color: bodyMediumColor, fontWeight: FontWeight.w500)),
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
                  const SizedBox(height: 40),

                  // Quick Stats
                  GridView.count(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.6,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildStatCard(stats['longestStreak']?.toString() ?? '0', 'LONGEST STREAK', LucideIcons.zap),
                      _buildStatCard(stats['streak']?.toString() ?? '0', 'CURRENT STREAK', LucideIcons.activity),
                      _buildStatCard(stats['completed']?.toString() ?? '0', 'COMPLETED', LucideIcons.checkCircle),
                      _buildStatCard(stats['friends']?.toString() ?? '0', 'FRIENDS', LucideIcons.users),
                    ],
                  ),
                  const SizedBox(height: 140),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, {Color? color}) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color ?? Theme.of(context).textTheme.labelSmall?.color, size: 14),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.labelSmall?.color, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }
}
