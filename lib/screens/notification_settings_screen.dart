import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/section_header.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _challenges = true;
  bool _friendRequests = true;
  bool _approvals = true;
  bool _streaks = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _challenges = user.preferences.notifications.challenges;
      _friendRequests = user.preferences.notifications.friendRequests;
      _approvals = user.preferences.notifications.approvals;
      _streaks = user.preferences.notifications.streaks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Notifications',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('PUSH NOTIFICATIONS'),
          _buildSwitchTile('Challenges', 'New challenge received', _challenges, (val) => setState(() => _challenges = val), isDark),
          _buildSwitchTile('Friend Requests', 'Someone wants to be your friend', _friendRequests, (val) => setState(() => _friendRequests = val), isDark),
          _buildSwitchTile('Approvals', 'When your proof is approved or rejected', _approvals, (val) => setState(() => _approvals = val), isDark),
          _buildSwitchTile('Streaks', 'Reminders to keep your streak alive', _streaks, (val) => setState(() => _streaks = val), isDark),
          
          const SizedBox(height: 48),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SectionHeader(
      title: title,
      padding: const EdgeInsets.only(left: 4, bottom: 16),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.zinc500, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: Theme.of(context).primaryColor,
        activeTrackColor: isDark ? AppTheme.zinc800 : AppTheme.zinc200,
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
              'notifications': {
                'challenges': _challenges,
                'friendRequests': _friendRequests,
                'approvals': _approvals,
                'streaks': _streaks,
              }
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification preferences saved successfully')),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving preferences: $e'), backgroundColor: Colors.redAccent),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
