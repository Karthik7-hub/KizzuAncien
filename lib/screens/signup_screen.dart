import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/app_header.dart';
import 'main_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _gender = 'male';
  bool _isLoading = false;
  Timer? _debounceTimer;
  bool _isCheckingUsername = false;
  bool _usernameExists = false;

  bool get _canSubmit {
    return _nameController.text.trim().isNotEmpty &&
           _usernameController.text.trim().length >= 3 &&
           !_usernameExists &&
           !_isCheckingUsername &&
           _emailController.text.trim().isNotEmpty &&
           RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim()) &&
           _passwordController.text.trim().length >= 6;
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateState);
    _usernameController.addListener(_onUsernameChanged);
    _emailController.addListener(_updateState);
    _passwordController.addListener(_updateState);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.removeListener(_updateState);
    _usernameController.removeListener(_onUsernameChanged);
    _emailController.removeListener(_updateState);
    _passwordController.removeListener(_updateState);
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateState() => setState(() {});

  void _onUsernameChanged() {
    _updateState();
    final username = _usernameController.text.trim();
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    
    if (username.length < 3) {
      setState(() {
        _usernameExists = false;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final exists = await authProvider.checkUsername(username);
      if (mounted && _usernameController.text.trim() == username) {
        setState(() {
          _usernameExists = exists;
          _isCheckingUsername = false;
        });
      }
    });
  }

  void _handleSignUp() async {
    if (_isLoading || !_canSubmit) return;
    setState(() => _isLoading = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final success = await authProvider.register(
        _nameController.text.trim(),
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _gender,
      );

      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
       if (mounted) {
        setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: const AppHeader(
        title: '',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join KizzuAncien.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The elite social challenge platform.',
                style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 16),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _nameController,
                hintText: 'Full Name',
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _usernameController,
                hintText: 'Unique Username',
                enabled: !_isLoading,
              ),
              if (_usernameController.text.trim().length >= 3) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      if (_isCheckingUsername) ...[
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.zinc500),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Checking availability...',
                          style: TextStyle(color: AppTheme.zinc500, fontSize: 12),
                        ),
                      ] else if (_usernameExists) ...[
                        const Icon(LucideIcons.xCircle, color: Colors.redAccent, size: 14),
                        const SizedBox(width: 8),
                        const Text(
                          'Username is already taken',
                          style: TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ] else ...[
                        const Icon(LucideIcons.checkCircle, color: Colors.green, size: 14),
                        const SizedBox(width: 8),
                        const Text(
                          'Username is available',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Strong Password',
                obscureText: true,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              Text(
                'SELECT GENDER',
                style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderOption('male', LucideIcons.user),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderOption('female', LucideIcons.user2),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Create Account',
                onPressed: (_isLoading || !_canSubmit) ? null : _handleSignUp,
                backgroundColor: primaryColor,
                textColor: Theme.of(context).scaffoldBackgroundColor,
                icon: Icon(LucideIcons.userPlus, size: 20, color: Theme.of(context).scaffoldBackgroundColor),
                isLoading: _isLoading,
              ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: TextSpan(
                      text: "Already a member? ",
                      style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, IconData icon) {
    final isSelected = _gender == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _isLoading ? null : () => setState(() => _gender = value),
      child: Opacity(
        opacity: _isLoading ? 0.6 : 1.0,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : (isDark ? AppTheme.zinc800 : AppTheme.zinc200)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).textTheme.labelSmall?.color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).textTheme.labelSmall?.color,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
