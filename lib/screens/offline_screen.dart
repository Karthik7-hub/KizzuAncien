import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class OfflineScreen extends StatefulWidget {
  final Future<void> Function() onRetry;
  
  const OfflineScreen({super.key, required this.onRetry});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      // Use a timeout to prevent infinite loading on the button if 
      // the network is still dead but not throwing immediately.
      await widget.onRetry().timeout(const Duration(seconds: 15));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Still unable to connect. Please try again later.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppTheme.zinc900,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.wifiOff,
                  color: AppTheme.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Connection Lost',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We couldn\'t reach the server. Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.zinc500,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'Try Again',
                isLoading: _isRetrying,
                onPressed: _isRetrying ? null : _handleRetry,
                backgroundColor: AppTheme.white,
                textColor: AppTheme.black,
                icon: const Icon(LucideIcons.refreshCw, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
