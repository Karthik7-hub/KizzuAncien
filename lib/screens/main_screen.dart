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
import 'challenges_screen.dart';
import '../theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  late NavigationProvider _navigationProvider;

  final List<Widget> _screens = const [
    HomeScreen(),
    ChallengesScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _navigationProvider = context.read<NavigationProvider>();
    _pageController = PageController(initialPage: _navigationProvider.currentIndex);
    _navigationProvider.addListener(_handleNavigationChange);
    
    // Request notification permissions on first load of main screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermissions();
    });
  }

  @override
  void dispose() {
    _navigationProvider.removeListener(_handleNavigationChange);
    _pageController.dispose();
    super.dispose();
  }

  void _handleNavigationChange() {
    if (_pageController.hasClients) {
      final targetPage = _navigationProvider.currentIndex;
      if (_pageController.page?.round() != targetPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _onTabTapped(int index) {
    if (_navigationProvider.currentIndex == index) return;
    _navigationProvider.setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final hasUnread = notificationProvider.notifications.any((n) => !n.read);

    return PopScope(
      canPop: navigationProvider.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (navigationProvider.currentIndex != 0) {
          navigationProvider.setIndex(0);
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
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(), // Enable smooth dragging
          onPageChanged: (index) {
            if (_navigationProvider.currentIndex != index) {
              _navigationProvider.setIndex(index);
            }
          },
          children: _screens,
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 64,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.zinc900.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppTheme.white.withValues(alpha: 0.1), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(0, LucideIcons.home),
                      _buildNavItem(1, LucideIcons.target),
                      _buildNavItem(2, LucideIcons.users),
                      _buildNavItem(3, LucideIcons.user),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final navigationProvider = context.watch<NavigationProvider>();
    final isSelected = navigationProvider.currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? AppTheme.black : AppTheme.zinc500,
          size: 22,
        ),
      ),
    );
  }
}
