import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
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
      return const Scaffold(
        backgroundColor: AppTheme.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, size: 20, color: AppTheme.zinc500),
            onPressed: () => _showSettingsMenu(context, authProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.white,
        backgroundColor: AppTheme.zinc950,
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
                        Text('@${user.username}', style: const TextStyle(fontSize: 15, color: AppTheme.zinc500, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        if (stats['streakFriend'] != null && stats['streakFriend'].toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.zinc900,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Best streak with ${stats['streakFriend']}',
                              style: const TextStyle(fontSize: 10, color: AppTheme.zinc400, fontWeight: FontWeight.bold),
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

  void _showSettingsMenu(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.zinc950,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.zinc900, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            _buildSettingsTile(LucideIcons.user, 'Edit Profile', () {
               Navigator.pop(context);
               _showEditProfileDialog(context, authProvider.user);
            }),
            _buildSettingsTile(LucideIcons.logOut, 'Sign Out', () async {
               HapticFeedback.mediumImpact();
               await authProvider.logout();
               if (context.mounted) {
                 Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(builder: (context) => const AuthScreen()),
                   (route) => false,
                 );
               }
            }, textColor: Colors.redAccent),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, dynamic user) {
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    String gender = user.gender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.zinc950,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.white)),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.white),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(color: AppTheme.zinc500),
                  filled: true,
                  fillColor: AppTheme.zinc900,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              const Text('GENDER', style: TextStyle(color: AppTheme.zinc600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildGenderOption('male', LucideIcons.user, gender == 'male', () => setModalState(() => gender = 'male')),
                  const SizedBox(width: 12),
                  _buildGenderOption('female', LucideIcons.user2, gender == 'female', () => setModalState(() => gender = 'female')),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.read<AuthProvider>().updateProfile(name: nameController.text.trim(), gender: gender);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.white,
                    foregroundColor: AppTheme.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.white : AppTheme.zinc900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppTheme.white : AppTheme.zinc800),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.black : AppTheme.zinc500, size: 20),
              const SizedBox(height: 4),
              Text(value.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? AppTheme.black : AppTheme.zinc500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap, {Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.zinc500, size: 20),
      title: Text(title, style: TextStyle(color: textColor ?? AppTheme.white, fontSize: 15, fontWeight: FontWeight.w600)),
      onTap: onTap,
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
              Icon(icon, color: color ?? AppTheme.zinc700, size: 14),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc500, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.white)),
        ],
      ),
    );
  }
}
