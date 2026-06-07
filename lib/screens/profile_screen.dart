import 'package:flutter/material.dart';
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

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<AuthProvider>().checkAuth();
  }

  @override
  Widget build(BuildContext context) {
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
                childAspectRatio: 1.4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildStatCard(stats['completed']?.toString() ?? '0', 'COMPLETED', LucideIcons.checkCircle),
                  _buildStatCard(stats['streak']?.toString() ?? '0', 'DAY STREAK', LucideIcons.flame),
                  _buildStatCard(stats['pointsEarned']?.toString() ?? '0', 'TOTAL EARNED', LucideIcons.award),
                  _buildStatCard(stats['friends']?.toString() ?? '0', 'FRIENDS', LucideIcons.users),
                  _buildStatCard(stats['active']?.toString() ?? '0', 'ACTIVE', LucideIcons.zap),
                  _buildStatCard(stats['failed']?.toString() ?? '0', 'MISSED', LucideIcons.xCircle),
                ],
              ),
              const SizedBox(height: 40),

              // Settings
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 16),
                  child: Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.zinc600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              /* 
              _buildSettingItem(
                icon: LucideIcons.settings,
                title: 'Global Preferences',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                icon: LucideIcons.helpCircle,
                title: 'Help & Feedback',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              */
              _buildSettingItem(
                icon: LucideIcons.logOut,
                title: 'Secure Log Out',
                textColor: Colors.redAccent,
                iconColor: Colors.redAccent,
                onTap: () async {
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

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.zinc900.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppTheme.zinc600, size: 16),
              const Icon(LucideIcons.arrowUpRight, color: AppTheme.zinc800, size: 14),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
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
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.zinc900.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.zinc400).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? AppTheme.zinc400, size: 20),
            ),
            const SizedBox(width: 16),
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
            if (textColor == null)
              const Icon(LucideIcons.chevronRight, color: AppTheme.zinc800, size: 18),
          ],
        ),
      ),
    );
  }
}
