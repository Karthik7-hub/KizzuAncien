import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User, AuthProvider;
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

  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;

  bool get _isAnyLoading => _isEmailLoading || _isGoogleLoading;

  bool get _canLogin {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    return email.isNotEmpty && 
           RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email) && 
           password.length >= 6;
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateState);
    _passwordController.addListener(_updateState);
  }

  @override
  void dispose() {
    _emailController.removeListener(_updateState);
    _passwordController.removeListener(_updateState);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  void _handleLogin() async {
    if (_isAnyLoading || !_canLogin) return;
    setState(() => _isEmailLoading = true);
    
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
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  void _handleGoogleLogin() async {
    if (_isAnyLoading) return;
    setState(() => _isGoogleLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: AppConstants.googleServerClientId,
        scopes: ['email', 'profile'],
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final String? firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        throw Exception('Could not get Firebase ID Token');
      }

      final Map<String, dynamic> googleData = {
        'googleId': userCredential.user!.uid,
        'email': userCredential.user!.email,
        'name': userCredential.user!.displayName,
        'idToken': firebaseIdToken,
      };

      final result = await authProvider.googleLogin(googleData);
      
      if (result['exists'] == true) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompleteProfileScreen(googleData: googleData),
            ),
          ).then((_) {
            if (mounted) setState(() => _isGoogleLoading = false);
          });
        }
      }
    } catch (e) {
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
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      style: textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.zinc500 : AppTheme.zinc600),
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
                    onPressed: (_isAnyLoading || !_canLogin) ? null : _handleLogin,
                    backgroundColor: isDark ? AppTheme.white : AppTheme.black,
                    textColor: isDark ? AppTheme.black : AppTheme.white,
                    icon: Icon(LucideIcons.logIn, size: 18, color: isDark ? AppTheme.black : AppTheme.white),
                    isLoading: _isEmailLoading,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Continue with Google',
                    onPressed: _isAnyLoading ? null : _handleGoogleLogin,
                    backgroundColor: isDark ? AppTheme.zinc950 : AppTheme.zinc100,
                    textColor: isDark ? AppTheme.white : AppTheme.black,
                    borderColor: isDark ? AppTheme.zinc900 : AppTheme.zinc200,
                    icon: SvgPicture.asset(
                      'assets/google_icon.svg',
                      width: 18,
                      height: 18,
                    ),
                    isLoading: _isGoogleLoading,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: _isAnyLoading ? null : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "New here? ",
                      style: textTheme.bodyMedium?.copyWith(color: isDark ? AppTheme.zinc500 : AppTheme.zinc600),
                      children: [
                        TextSpan(
                          text: 'Create Account',
                          style: textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppTheme.white : AppTheme.zinc950,
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
