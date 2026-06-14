import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_card.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _allowFriendRequests = true;
  bool _allowChallengeRequests = true;
  String _profileVisibility = 'friends'; // public, friends, private

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _allowFriendRequests = user.preferences.privacy.allowFriendRequests;
      _allowChallengeRequests = user.preferences.privacy.allowChallengeRequests;
      _profileVisibility = user.preferences.privacy.profileVisibility;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Privacy',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('INTERACTIONS'),
          _buildSwitchTile(
            'Friend Requests',
            'Allow others to send you friend requests',
            _allowFriendRequests,
            (val) => setState(() => _allowFriendRequests = val),
            isDark,
          ),
          _buildSwitchTile(
            'Challenge Requests',
            'Allow others to challenge you',
            _allowChallengeRequests,
            (val) => setState(() => _allowChallengeRequests = val),
            isDark,
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('VISIBILITY'),
          _buildVisibilityOption('Public', 'Everyone can see your profile and streaks', 'public', isDark),
          _buildVisibilityOption('Friends Only', 'Only your friends can see your progress', 'friends', isDark),
          _buildVisibilityOption('Private', 'Only you can see your detailed stats', 'private', isDark),
          
          const SizedBox(height: 48),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title,
        style: TextStyle(color: isDark ? AppTheme.zinc500 : AppTheme.zinc600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 16,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.zinc500, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: isDark ? AppTheme.white : AppTheme.white,
        activeTrackColor: isDark ? AppTheme.zinc800 : AppTheme.black,
      ),
    );
  }

  Widget _buildVisibilityOption(String title, String subtitle, String value, bool isDark) {
    final bool isSelected = _profileVisibility == value;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
      onTap: () => setState(() => _profileVisibility = value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppTheme.zinc500, fontSize: 12)),
              ],
            ),
          ),
          if (isSelected)
            Icon(LucideIcons.checkCircle, color: Theme.of(context).primaryColor, size: 18),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          try {
            await context.read<AuthProvider>().updatePreferences({
              'privacy': {
                'allowFriendRequests': _allowFriendRequests,
                'allowChallengeRequests': _allowChallengeRequests,
                'profileVisibility': _profileVisibility,
              }
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy settings saved successfully')),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving settings: $e'), backgroundColor: Colors.redAccent),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Save Privacy Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
