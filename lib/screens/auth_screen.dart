import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'main_screen.dart';
import 'signup_screen.dart';
import 'complete_profile_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  void _handleGoogleLogin() async {
    debugPrint('🚀 Starting Google Login...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      debugPrint('🔑 Using serverClientId: ${AppConstants.googleServerClientId}');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: AppConstants.googleServerClientId,
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      debugPrint('👤 Google User Result: $googleUser');

      if (googleUser == null) {
        debugPrint('⚠️ Google Login Cancelled by User');
        return;
      }

      final Map<String, dynamic> googleData = {
        'googleId': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName,
      };
      debugPrint('📊 Google Data Collected: $googleData');

      // Check if user exists
      final exists = await authProvider.checkEmail(googleUser.email);
      debugPrint('🔍 User Exists in DB: $exists');

      if (!exists) {
        if (mounted) {
          debugPrint('🆕 Navigating to CompleteProfileScreen');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompleteProfileScreen(googleData: googleData),
            ),
          );
        }
      } else {
        debugPrint('🔐 Logging in existing user via API...');
        final result = await authProvider.googleLogin(googleData);
        debugPrint('✅ API Login Result: $result');
        if (result['exists'] == true && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ GOOGLE LOGIN CRITICAL ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Login failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/logo.svg',
                      width: 56,
                      height: 56,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Welcome back.',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to continue your streak.',
                      style: TextStyle(color: AppTheme.zinc500, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 32),
              isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))
                  : Column(
                      children: [
                        CustomButton(
                          text: 'Sign In',
                          onPressed: _handleLogin,
                          backgroundColor: AppTheme.white,
                          textColor: AppTheme.black,
                          icon: const Icon(LucideIcons.logIn, size: 20),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Continue with Google',
                          onPressed: _handleGoogleLogin,
                          backgroundColor: AppTheme.zinc900,
                          textColor: AppTheme.white,
                          borderColor: AppTheme.zinc800,
                          icon: const Icon(LucideIcons.chrome, size: 20),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "New here? ",
                      style: TextStyle(color: AppTheme.zinc600, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Create Account',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
