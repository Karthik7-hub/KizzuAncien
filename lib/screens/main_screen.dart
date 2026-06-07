import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kizzu_ancien/screens/notifications_screen.dart';
import '../providers/navigation_provider.dart';
import '../providers/challenge_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'home_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';
import '../theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _screens = const [
    HomeScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    final navigationProvider = context.read<NavigationProvider>();
    if (navigationProvider.currentIndex != index) {
      navigationProvider.setIndex(index);
      
      if (index == 0) {
        context.read<ChallengeProvider>().fetchChallenges();
        context.read<NotificationProvider>().fetchNotifications();
      } else if (index == 1) {
        context.read<FriendProvider>().fetchFriends();
      } else if (index == 2) {
        context.read<AuthProvider>().checkAuth();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final hasUnread = notificationProvider.notifications.any((n) => !n.read);

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SvgPicture.asset(
                'assets/logo.svg',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'KizzuAncien',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell, color: AppTheme.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              if (hasUnread)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens[navigationProvider.currentIndex],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          decoration: BoxDecoration(
            color: AppTheme.zinc900.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: AppTheme.zinc800, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, LucideIcons.home, 'Home'),
              _buildNavItem(1, LucideIcons.users, 'Friends'),
              _buildNavItem(2, LucideIcons.user, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final navigationProvider = context.watch<NavigationProvider>();
    final isSelected = navigationProvider.currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.black : AppTheme.zinc500,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
