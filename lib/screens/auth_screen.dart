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

  bool _isProcessing = false;

  void _handleLogin() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    
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
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleGoogleLogin() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    debugPrint('🚀 Starting Google Login...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      debugPrint('🔑 Using serverClientId: ${AppConstants.googleServerClientId}');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: AppConstants.googleServerClientId,
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('⚠️ Google Login Cancelled');
        setState(() => _isProcessing = false);
        return;
      }

      final Map<String, dynamic> googleData = {
        'googleId': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName,
      };

      // Call googleLogin directly. The backend will tell us if user exists.
      final result = await authProvider.googleLogin(googleData);
      
      if (result['exists'] == true) {
        // EXISTING USER: Login successful
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      } else {
        // NEW USER: Needs to complete profile
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompleteProfileScreen(googleData: googleData),
            ),
          ).then((_) {
            if (mounted) setState(() => _isProcessing = false);
          });
        }
      }
    } catch (e) {
      debugPrint('❌ GOOGLE LOGIN ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString().replaceAll('Exception: ', '')}'), 
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Note: We don't set _isProcessing = false here if we navigated away 
      // but the .then() and error catch handle it.
      if (mounted && !Navigator.of(context).canPop()) {
         // This is a bit tricky if we pushed a screen.
      }
      // Simpler:
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading || _isProcessing;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.padding * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/logo.svg',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Welcome back.',
                      style: textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue your streak.',
                      style: textTheme.bodyLarge?.copyWith(color: AppTheme.zinc500),
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
              const SizedBox(height: 12),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  CustomButton(
                    text: 'Sign In',
                    onPressed: _handleLogin,
                    backgroundColor: AppTheme.white,
                    textColor: AppTheme.black,
                    icon: const Icon(LucideIcons.logIn, size: 18),
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Continue with Google',
                    onPressed: _handleGoogleLogin,
                    backgroundColor: AppTheme.zinc950,
                    textColor: AppTheme.white,
                    borderColor: AppTheme.zinc900,
                    icon: SvgPicture.network(
                      'https://www.vectorlogo.zone/logos/google/google-icon.svg',
                      width: 18,
                      height: 18,
                      placeholderBuilder: (context) => const Icon(LucideIcons.globe, size: 18),
                    ),
                    isLoading: isLoading,
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
                    text: TextSpan(
                      text: "New here? ",
                      style: textTheme.bodyMedium?.copyWith(color: AppTheme.zinc600),
                      children: [
                        TextSpan(
                          text: 'Create Account',
                          style: textTheme.bodyMedium?.copyWith(
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
