import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kizzu_ancien/screens/notifications_screen.dart';
import 'package:kizzu_ancien/services/notification_service.dart';
import '../providers/navigation_provider.dart';
import '../providers/notification_provider.dart';
import 'home_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';
import 'all_challenges_screen.dart';
import 'create_challenge_screen.dart';
import 'offline_screen.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late NavigationProvider _navigationProvider;

  final List<Widget> _screens = const [
    HomeScreen(),
    AllChallengesScreen(),
    CreateChallengeScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _navigationProvider = context.read<NavigationProvider>();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermissions();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_navigationProvider.currentIndex == index) return;
    
    // Clear global focus and dismiss keyboard immediately before navigation
    FocusManager.instance.primaryFocus?.unfocus();

    _navigationProvider.setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.select((NavigationProvider p) => p.currentIndex);
    final authStatus = context.select((AuthProvider p) => p.status);
    final hasUnread = context.select((NotificationProvider p) => 
      p.notifications.any((n) => !n.read));
    
    if (authStatus == AuthStatus.offline) {
      return OfflineScreen(onRetry: () => context.read<AuthProvider>().checkAuth());
    }

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentIndex != 0) {
          _navigationProvider.setIndex(0);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.black,
        appBar: AppBar(
          backgroundColor: AppTheme.black,
          elevation: 0,
          centerTitle: false,
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SvgPicture.asset(
                  'assets/logo.svg',
                  width: 28,
                  height: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'KizzuAncien',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.bell, color: AppTheme.white, size: 22),
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
        body: IndexedStack(
          index: currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 64,
            margin: const EdgeInsets.fromLTRB(40, 0, 40, 20),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.zinc900,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.white.withValues(alpha: 0.1), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(0, LucideIcons.home),
                _buildNavItem(1, LucideIcons.layoutList),
                _buildNavItem(2, LucideIcons.plusCircle),
                _buildNavItem(3, LucideIcons.users),
                _buildNavItem(4, LucideIcons.user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = context.select((NavigationProvider p) => p.currentIndex == index);
    final bool isCenter = index == 2;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: isCenter ? 64 : 50,
        height: isCenter ? 64 : 50,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white : (isCenter ? AppTheme.zinc800 : Colors.transparent),
          shape: BoxShape.circle,
          boxShadow: isCenter && isSelected ? [
            BoxShadow(color: AppTheme.white.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)
          ] : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? AppTheme.black : AppTheme.zinc500,
          size: isCenter ? 32 : 22,
        ),
      ),
    );
  }
}
