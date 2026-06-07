import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kizzu_ancien/models/user.dart';
import 'package:kizzu_ancien/providers/auth_provider.dart';
import 'package:kizzu_ancien/providers/truth_dare_provider.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/widgets/custom_button.dart';
import '../widgets/avatar_widget.dart';

class TruthDareScreen extends StatefulWidget {
  final User recipient;
  const TruthDareScreen({super.key, required this.recipient});

  @override
  State<TruthDareScreen> createState() => _TruthDareScreenState();
}

class _TruthDareScreenState extends State<TruthDareScreen> {
  bool _isTruthMode = true;
  final TextEditingController _inputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isLoading = context.watch<TruthDareProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Spend Points',
          style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
              child: Column(
                children: [
                  // Balance Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.zinc900,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppTheme.zinc800),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'YOUR BALANCE',
                          style: TextStyle(color: AppTheme.zinc600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.award, size: 28, color: Colors.amber),
                            const SizedBox(width: 12),
                            Text(
                              '${user?.points ?? 0}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tabs
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.zinc900,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTab(true, 'Truth', '50 pts'),
                        ),
                        Expanded(
                          child: _buildTab(false, 'Dare', '100 pts'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.zinc900.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppTheme.zinc800),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('RECIPIENT', style: TextStyle(color: AppTheme.zinc600, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.black,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.zinc800),
                              ),
                              child: Row(
                                children: [
                                  AvatarWidget(user: widget.recipient, size: 20, showBorder: false),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.recipient.name,
                                    style: const TextStyle(color: AppTheme.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _inputController,
                          maxLines: 6,
                          style: const TextStyle(color: AppTheme.white, fontSize: 18, height: 1.5),
                          decoration: InputDecoration(
                            hintText: _isTruthMode
                                ? 'What do you want to know?'
                                : 'What should they do?',
                            hintStyle: const TextStyle(color: AppTheme.zinc700),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))
                : CustomButton(
                    text: 'Send ${_isTruthMode ? "Truth" : "Dare"}',
                    onPressed: () async {
                      if (_inputController.text.isEmpty) return;
                      bool success;
                      if (_isTruthMode) {
                        success = await context.read<TruthDareProvider>().sendTruth(
                          widget.recipient.id,
                          _inputController.text,
                        );
                      } else {
                        success = await context.read<TruthDareProvider>().sendDare(
                          widget.recipient.id,
                          _inputController.text,
                        );
                      }
                      
                      if (!context.mounted) return;
                      if (success) {
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Insufficient points or error occurred.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    backgroundColor: AppTheme.white,
                    textColor: AppTheme.black,
                    icon: const Icon(LucideIcons.send, size: 20),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(bool mode, String title, String pts) {
    final isSelected = _isTruthMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _isTruthMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.black : AppTheme.zinc500,
              ),
            ),
            Text(
              pts,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.black.withValues(alpha: 0.5) : AppTheme.zinc700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
