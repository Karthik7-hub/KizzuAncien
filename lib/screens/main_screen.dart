import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:kizzu_ancien/services/notification_service.dart';
import '../providers/navigation_provider.dart';
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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  late NavigationProvider _navigationProvider;
  bool _isKeyboardOpen = false;

  // Synchronized animation config — used by navbar indicator
  static const Duration _navDuration = Duration(milliseconds: 500);
  static const Curve _navCurve = ElasticOutCurve(0.8);

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
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _navigationProvider.removeListener(_handleNavigationChange);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (mounted) {
      final double bottomInset = View.of(context).viewInsets.bottom;
      final bool isOpen = bottomInset > 0;
      if (isOpen != _isKeyboardOpen) {
        setState(() {
          _isKeyboardOpen = isOpen;
        });
      }
    }
  }

  void _handleNavigationChange() {
    if (!_pageController.hasClients) return;
    
    final double? page = _pageController.position.hasContentDimensions &&
            _pageController.position.hasPixels
        ? _pageController.page
        : null;
    final targetPage = _navigationProvider.currentIndex;
    final currentPage = page?.round() ?? _pageController.initialPage;
    
    if (currentPage != targetPage) {
      _pageController.jumpToPage(targetPage);
    }
  }

  void _onTabTapped(int index) {
    if (_navigationProvider.currentIndex == index) return;
    _navigationProvider.setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.select<NavigationProvider, int>((p) => p.currentIndex);
    final authStatus = context.select<AuthProvider, AuthStatus>((p) => p.status);
    
    if (authStatus == AuthStatus.offline) {
      return OfflineScreen(onRetry: () => context.read<AuthProvider>().checkAuth());
    }

    final bool isKeyboardOpen = _isKeyboardOpen;

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentIndex != 0) {
          context.read<NavigationProvider>().setIndex(0);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: isKeyboardOpen 
                  ? const NeverScrollableScrollPhysics() 
                  : const BouncingScrollPhysics(),
              onPageChanged: (index) {
                if (_navigationProvider.currentIndex != index) {
                  _navigationProvider.setIndex(index);
                }
              },
              children: _screens,
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              bottom: isKeyboardOpen ? -120.0 : 0.0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: RepaintBoundary(
                  child: _SlidingNavbar(onTabTapped: _onTabTapped),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidingNavbar extends StatelessWidget {
  final ValueChanged<int> onTabTapped;

  const _SlidingNavbar({required this.onTabTapped});

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.select<NavigationProvider, int>((p) => p.currentIndex);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? AppTheme.zinc900.withValues(alpha: 0.7) 
                  : AppTheme.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark 
                    ? AppTheme.white.withValues(alpha: 0.1) 
                    : AppTheme.zinc200, 
                width: 1
              ),
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: AppTheme.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth = constraints.maxWidth;
                final double itemWidth = totalWidth / 5;
                final double indicatorWidth = currentIndex == 2 ? 64 : 50;
                final double leftOffset = (currentIndex * itemWidth) + (itemWidth / 2) - (indicatorWidth / 2);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Sliding Indicator — synced duration/curve with PageView
                    AnimatedPositioned(
                      duration: _MainScreenState._navDuration,
                      curve: _MainScreenState._navCurve,
                      left: leftOffset,
                      top: (64 - indicatorWidth) / 2,
                      width: indicatorWidth,
                      height: indicatorWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.white : AppTheme.black,
                          shape: BoxShape.circle,
                          boxShadow: currentIndex == 2 ? [
                            BoxShadow(
                              color: (isDark ? AppTheme.white : AppTheme.black).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ] : [],
                          border: isDark ? null : Border.all(color: AppTheme.zinc200, width: 0.5),
                        ),
                      ),
                    ),
                    // Navigation Items (on top of indicator)
                    Row(
                      children: List.generate(5, (index) {
                        final icons = [
                          LucideIcons.home,
                          LucideIcons.layoutList,
                          LucideIcons.plusCircle,
                          LucideIcons.users,
                          LucideIcons.user,
                        ];
                        return Expanded(
                          child: _NavItem(
                            index: index,
                            icon: icons[index],
                            onTap: () => onTabTapped(index),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.select<NavigationProvider, int>((p) => p.currentIndex);
    final isSelected = currentIndex == index;
    final bool isCenter = index == 2;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedScale(
          duration: _MainScreenState._navDuration,
          scale: isSelected ? 1.15 : 1.0,
          curve: Curves.easeOutBack,
          child: Container(
            width: isCenter ? 64 : 50,
            height: isCenter ? 64 : 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (isCenter && !isSelected) ? (isDark ? AppTheme.zinc800 : AppTheme.zinc200) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected 
                  ? (isDark ? AppTheme.black : AppTheme.white) 
                  : (isDark ? AppTheme.zinc500 : AppTheme.zinc400),
              size: isCenter ? 32 : 22,
            ),
          ),
        ),
      ),
    );
  }
}
