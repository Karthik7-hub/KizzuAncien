import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
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

  void _handleSignUp() async {
    if (_isLoading) return;
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
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.white),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Join KizzuAncien.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The elite social challenge platform.',
                style: TextStyle(color: AppTheme.zinc500, fontSize: 16),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _nameController,
                hintText: 'Full Name',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _usernameController,
                hintText: 'Unique Username',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Strong Password',
                obscureText: true,
              ),
              const SizedBox(height: 24),
              const Text(
                'SELECT GENDER',
                style: TextStyle(color: AppTheme.zinc600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
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
                onPressed: _isLoading ? null : _handleSignUp,
                backgroundColor: AppTheme.white,
                textColor: AppTheme.black,
                icon: const Icon(LucideIcons.userPlus, size: 20),
                isLoading: _isLoading,
              ),
              const SizedBox(height: 32),
              Center(
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).pop();
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Already a member? ",
                        style: TextStyle(color: AppTheme.zinc600, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Log in',
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, IconData icon) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white : AppTheme.zinc900,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.white : AppTheme.zinc800),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.black : AppTheme.zinc500,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.black : AppTheme.zinc500,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
