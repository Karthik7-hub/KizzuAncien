import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'package:kizzu_ancien/utils/logger.dart';
import 'package:kizzu_ancien/services/notification_service.dart';
import 'auth_screen.dart';
import 'main_screen.dart';
import 'offline_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5, curve: Curves.easeIn)),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // We start checkAuth and wait for a maximum of 10 seconds (handles cold starts)
    final checkAuthFuture = authProvider.checkAuth();
    
    // Fast minimum display time for snappy feel when ready (600ms)
    final minDisplayTime = Future.delayed(const Duration(milliseconds: 600));

    final results = await Future.wait([
      checkAuthFuture.catchError((e) {
        AppLogger.error('SplashScreen checkAuth error', e);
        return AuthStatus.offline;
      }),
      minDisplayTime,
    ]);

    final authStatus = results[0] as AuthStatus;
    
    if (authStatus == AuthStatus.authenticated) {
      NotificationService.setupFcmToken();
    }

    if (mounted) {
      if (authStatus == AuthStatus.offline) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OfflineScreen(
              onRetry: () async {
                // To retry, we simply re-run initialization
                await _initializeApp();
              },
            ),
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
            authStatus == AuthStatus.authenticated ? const MainScreen() : const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final fade = FadeTransition(opacity: animation, child: child);
            return Container(color: isDark ? AppTheme.black : AppTheme.white, child: fade);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We want the splash to render IMMEDIATELY.
    // The background should be static and match native splash.
    // Only the internal components should animate if needed.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppTheme.white;
    final textColor = isDark ? AppTheme.white : AppTheme.zinc950;
    final subtextColor = isDark ? AppTheme.zinc600 : AppTheme.zinc400;
    final shadowColor = isDark ? AppTheme.white.withValues(alpha: 0.15) : AppTheme.black.withValues(alpha: 0.12);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  // Subtle shadow that appears with the icon
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: SvgPicture.asset(
                    'assets/logo.svg',
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'KizzuAncien',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SOCIAL CHALLENGES REDEFINED',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtextColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
