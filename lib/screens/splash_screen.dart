import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
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
    
    // We start checkAuth and wait for a maximum of 5 seconds
    final checkAuthFuture = authProvider.checkAuth();
    
    // Ensure the splash is visible for at least 1 second for a smooth transition
    final minDisplayTime = Future.delayed(const Duration(milliseconds: 1200));

    final results = await Future.wait([
      checkAuthFuture.catchError((e) => AuthStatus.offline),
      minDisplayTime,
    ]);

    AuthStatus authStatus = results[0] as AuthStatus;
    
    // Fallback: Try silent sign-in if our tokens are invalid
    if (authStatus == AuthStatus.unauthenticated) {
      final bool silentSuccess = await authProvider.trySilentLogin();
      if (silentSuccess) {
        authStatus = AuthStatus.authenticated;
      }
    }

    if (authStatus == AuthStatus.authenticated) {
      NotificationService.setupFcmToken();
    }

    if (mounted) {
      if (authStatus == AuthStatus.offline) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OfflineScreen(
              onRetry: () async {
                final provider = Provider.of<AuthProvider>(context, listen: false);
                final status = await provider.checkAuth();
                if (status != AuthStatus.offline && context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => status == AuthStatus.authenticated ? const MainScreen() : const AuthScreen()),
                  );
                }
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
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
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
    return Scaffold(
      backgroundColor: AppTheme.black,
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
                      color: AppTheme.white.withValues(alpha: 0.1),
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
              child: const Column(
                children: [
                  Text(
                    'KizzuAncien',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'SOCIAL CHALLENGES REDEFINED',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.zinc600,
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
