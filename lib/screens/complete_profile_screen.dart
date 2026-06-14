import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'main_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final Map<String, dynamic> googleData;
  const CompleteProfileScreen({super.key, required this.googleData});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  String _gender = 'male';
  bool _isLoading = false;

  bool get _canSubmit => _usernameController.text.trim().length >= 3;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_updateState);
    // Auto-generate a suggestion
    final email = widget.googleData['email'] as String? ?? '';
    if (email.contains('@')) {
      _usernameController.text = email.split('@')[0];
    }
  }

  @override
  void dispose() {
    _usernameController.removeListener(_updateState);
    _usernameController.dispose();
    super.dispose();
  }

  void _updateState() => setState(() {});

  void _handleComplete() async {
    if (_isLoading || !_canSubmit) return;

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    try {
      final result = await authProvider.googleLogin(
        widget.googleData,
        gender: _gender,
        username: _usernameController.text.trim(),
      );

      if (result['exists'] == true && mounted) {
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
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Almost there.',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.white, letterSpacing: -1),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete your profile to join KizzuAncien.',
                style: TextStyle(color: AppTheme.zinc500, fontSize: 16),
              ),
              const SizedBox(height: 48),
              const Text(
                'CHOOSE A USERNAME',
                style: TextStyle(color: AppTheme.zinc600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _usernameController,
                hintText: 'Username',
                enabled: !_isLoading,
              ),
              const SizedBox(height: 32),
              const Text(
                'SELECT GENDER',
                style: TextStyle(color: AppTheme.zinc600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildGenderOption('male', LucideIcons.user)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildGenderOption('female', LucideIcons.user2)),
                ],
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'Complete Profile',
                onPressed: (_isLoading || !_canSubmit) ? null : _handleComplete,
                backgroundColor: AppTheme.white,
                textColor: AppTheme.black,
                icon: const Icon(LucideIcons.check, size: 20),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, IconData icon) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: _isLoading ? null : () => setState(() => _gender = value),
      child: Opacity(
        opacity: _isLoading ? 0.6 : 1.0,
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
            Icon(icon, color: isSelected ? AppTheme.black : AppTheme.zinc500, size: 24),
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
    ),
  );
}
}
