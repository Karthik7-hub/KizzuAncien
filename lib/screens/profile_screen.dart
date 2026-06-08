import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import 'auth_screen.dart';

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
    await context.read<AuthProvider>().checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final stats = authProvider.stats;

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.white,
        backgroundColor: AppTheme.zinc900,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Hero(
                          tag: 'profile-pic',
                          child: user != null 
                              ? AvatarWidget(user: user, size: 110)
                              : Container(width: 110, height: 110, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.zinc900)),
                        ),
                        /* 
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.black, width: 4),
                            ),
                            child: const Icon(LucideIcons.edit3, size: 16, color: AppTheme.black),
                          ),
                        ),
                        */
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user?.name ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user?.username ?? ""}',
                      style: const TextStyle(fontSize: 15, color: AppTheme.zinc500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildStatCard(stats['completed']?.toString() ?? '0', 'COMPLETED', LucideIcons.checkCircle),
                  _buildStatCard(stats['streak']?.toString() ?? '0', 'STREAK', LucideIcons.flame, color: AppTheme.accent),
                  _buildStatCard(stats['pointsEarned']?.toString() ?? '0', 'TOTAL EARNED', LucideIcons.award),
                  _buildStatCard(stats['friends']?.toString() ?? '0', 'FRIENDS', LucideIcons.users),
                ],
              ),
              const SizedBox(height: 32),

              _buildSettingItem(
                icon: LucideIcons.logOut,
                title: 'Sign Out',
                textColor: Colors.redAccent,
                iconColor: Colors.redAccent,
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.zinc900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color ?? AppTheme.zinc600, size: 14),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.zinc500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.zinc950,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: AppTheme.zinc900),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppTheme.zinc500, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? AppTheme.white,
                ),
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppTheme.zinc800, size: 16),
          ],
        ),
      ),
    );
  }
}
