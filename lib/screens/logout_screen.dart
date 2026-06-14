import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  @override
  void initState() {
    super.initState();
    _performLogout();
  }

  Future<void> _performLogout() async {
    // Add a small delay for smooth visual transition
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    try {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppTheme.white;
    final textColor = isDark ? AppTheme.zinc400 : AppTheme.zinc600;
    final shadowColor = isDark ? AppTheme.white.withValues(alpha: 0.05) : AppTheme.black.withValues(alpha: 0.05);
    final indicatorColor = isDark ? AppTheme.white : AppTheme.black;
    final fallbackIconColor = isDark ? AppTheme.white : AppTheme.black;
    final fallbackBgColor = isDark ? AppTheme.zinc900 : AppTheme.zinc100;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SvgPicture.asset(
                  'assets/logo.svg',
                  width: 80,
                  height: 80,
                  placeholderBuilder: (BuildContext context) => Container(
                    color: fallbackBgColor,
                    child: Icon(
                      Icons.power_settings_new,
                      color: fallbackIconColor,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              color: indicatorColor,
              strokeWidth: 2,
            ),
            const SizedBox(height: 24),
            Text(
              'Signing out safely...',
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
