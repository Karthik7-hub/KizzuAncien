import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/section_header.dart';
import 'appearance_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'logout_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildSectionTitle(context, 'ACCOUNT'),
          _buildSettingsTile(
            context,
            LucideIcons.user,
            'Edit Profile',
            onTap: () => _showEditProfileDialog(context, user),
          ),
          _buildSettingsTile(
            context,
            LucideIcons.lock,
            'Privacy',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsScreen())),
          ),
          _buildSettingsTile(
            context,
            LucideIcons.bell,
            'Notifications',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'PREFERENCES'),
          _buildSettingsTile(
            context,
            LucideIcons.palette,
            'Appearance',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen())),
          ),
          _buildSettingsTile(
            context,
            LucideIcons.info,
            'About KizzuAncien',
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'ACCOUNT ACTIONS'),
          _buildSettingsTile(
            context,
            LucideIcons.logOut,
            'Sign Out',
            textColor: Colors.redAccent,
            onTap: () => _showSignOutDialog(context, authProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return SectionHeader(
      title: title,
      padding: const EdgeInsets.only(left: 16, bottom: 12, top: 8),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    Color? textColor,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.zinc950 : AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
      ),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? (enabled ? (isDark ? AppTheme.zinc400 : AppTheme.zinc500) : (isDark ? AppTheme.zinc800 : AppTheme.zinc300)), size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? (enabled ? (isDark ? AppTheme.white : AppTheme.zinc950) : (isDark ? AppTheme.zinc700 : AppTheme.zinc400)),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: isDark ? AppTheme.zinc700 : AppTheme.zinc500, fontSize: 12),
              )
            : null,
        trailing: enabled
            ? Icon(LucideIcons.chevronRight, color: isDark ? AppTheme.zinc800 : AppTheme.zinc300, size: 16)
            : null,
        onTap: enabled ? onTap : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, dynamic user) {
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    final usernameController = TextEditingController(text: user.username);
    String gender = user.gender;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Timer? debounceTimer;
    bool isChecking = false;
    bool usernameExists = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.zinc950 : AppTheme.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void onUsernameChanged() {
            final username = usernameController.text.trim();
            if (debounceTimer?.isActive ?? false) debounceTimer?.cancel();

            if (username == user.username) {
              setModalState(() {
                usernameExists = false;
                isChecking = false;
              });
              return;
            }

            if (username.length < 3) {
              setModalState(() {
                usernameExists = false;
                isChecking = false;
              });
              return;
            }

            setModalState(() {
              isChecking = true;
            });

            debounceTimer = Timer(const Duration(milliseconds: 500), () async {
              final exists = await context.read<AuthProvider>().checkUsername(username, excludeUserId: user.id);
              if (usernameController.text.trim() == username) {
                setModalState(() {
                  usernameExists = exists;
                  isChecking = false;
                });
              }
            });
          }

          final bool canSave = nameController.text.trim().isNotEmpty &&
              usernameController.text.trim().length >= 3 &&
              !usernameExists &&
              !isChecking;

          return Padding(
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
                Text('Edit Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppTheme.white : AppTheme.zinc950)),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: isDark ? AppTheme.white : AppTheme.zinc950),
                  onChanged: (val) => setModalState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: AppTheme.zinc500),
                    filled: true,
                    fillColor: isDark ? AppTheme.zinc900 : AppTheme.zinc100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16), 
                      borderSide: isDark ? BorderSide.none : const BorderSide(color: AppTheme.zinc200),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  style: TextStyle(color: isDark ? AppTheme.white : AppTheme.zinc950),
                  onChanged: (val) => onUsernameChanged(),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: const TextStyle(color: AppTheme.zinc500),
                    filled: true,
                    fillColor: isDark ? AppTheme.zinc900 : AppTheme.zinc100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16), 
                      borderSide: isDark ? BorderSide.none : const BorderSide(color: AppTheme.zinc200),
                    ),
                  ),
                ),
                if (usernameController.text.trim().length >= 3 && usernameController.text.trim() != user.username) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        if (isChecking) ...[
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.zinc500),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Checking availability...',
                            style: TextStyle(color: AppTheme.zinc500, fontSize: 12),
                          ),
                        ] else if (usernameExists) ...[
                          const Icon(LucideIcons.xCircle, color: Colors.redAccent, size: 14),
                          const SizedBox(width: 8),
                          const Text(
                            'Username is already taken',
                            style: TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ] else ...[
                          const Icon(LucideIcons.checkCircle, color: Colors.green, size: 14),
                          const SizedBox(width: 8),
                          const Text(
                            'Username is available',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text('GENDER', style: TextStyle(color: isDark ? AppTheme.zinc500 : AppTheme.zinc600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildGenderOption(context, 'male', LucideIcons.user, gender == 'male', () => setModalState(() => gender = 'male')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGenderOption(context, 'female', LucideIcons.user2, gender == 'female', () => setModalState(() => gender = 'female')),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: !canSave ? null : () async {
                      try {
                        await context.read<AuthProvider>().updateProfile(
                          name: nameController.text.trim(),
                          username: usernameController.text.trim(),
                          gender: gender,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.white : AppTheme.black,
                      foregroundColor: isDark ? AppTheme.black : AppTheme.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.zinc950 : AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
        ),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: isDark ? AppTheme.white : AppTheme.zinc950,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of KizzuAncien?',
          style: TextStyle(
            color: isDark ? AppTheme.zinc400 : AppTheme.zinc600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppTheme.zinc500 : AppTheme.zinc600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              HapticFeedback.mediumImpact();
              
              if (context.mounted) {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const LogoutScreen()),
                );

                if (result != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to sign out: $result'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(BuildContext context, String value, IconData icon, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? AppTheme.white : AppTheme.black) : (isDark ? AppTheme.zinc900 : AppTheme.zinc100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? (isDark ? AppTheme.white : AppTheme.black) : (isDark ? AppTheme.zinc800 : AppTheme.zinc200)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? (isDark ? AppTheme.black : AppTheme.white) : AppTheme.zinc500, size: 20),
            const SizedBox(height: 4),
            Text(value.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? (isDark ? AppTheme.black : AppTheme.white) : AppTheme.zinc500)),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'KizzuAncien',
      applicationVersion: '1.2.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset('assets/logo.png', width: 48, height: 48, errorBuilder: (_, __, ___) => const Icon(LucideIcons.zap)),
      ),
      children: [
        const Text('Social Challenges Redefined.'),
        const SizedBox(height: 12),
        const Text('Build habits and strengthen relationships through fun challenges.'),
      ],
    );
  }
}
