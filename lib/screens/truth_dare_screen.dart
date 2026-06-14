import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kizzu_ancien/models/user.dart';
import 'package:kizzu_ancien/providers/truth_dare_provider.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/widgets/custom_button.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/app_header.dart';

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
    final isLoading = context.watch<TruthDareProvider>().isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AppHeader(
        title: 'Spend Points',
        showBackButton: true,
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
                      color: isDark ? AppTheme.zinc900 : AppTheme.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: isDark ? AppTheme.zinc800 : AppTheme.zinc200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'AVAILABLE POINTS',
                          style: TextStyle(color: isDark ? AppTheme.zinc500 : AppTheme.zinc600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                            const Icon(LucideIcons.award, size: 28, color: Colors.amber),
                            const SizedBox(width: 12),
                            Text(
                              '${widget.recipient.relationshipPoints ?? 0}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.white : AppTheme.zinc950,
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
                      color: isDark ? AppTheme.zinc900 : AppTheme.zinc100,
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
                      color: isDark ? AppTheme.zinc900.withValues(alpha: 0.5) : AppTheme.zinc100.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: isDark ? AppTheme.zinc800 : AppTheme.zinc200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('RECIPIENT', style: TextStyle(color: isDark ? AppTheme.zinc500 : AppTheme.zinc600, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.black : AppTheme.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isDark ? AppTheme.zinc800 : AppTheme.zinc200),
                              ),
                              child: Row(
                                children: [
                                  AvatarWidget(user: widget.recipient, size: 20, showBorder: false),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.recipient.name,
                                    style: TextStyle(color: isDark ? AppTheme.white : AppTheme.zinc950, fontSize: 12, fontWeight: FontWeight.bold),
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
                          style: TextStyle(color: isDark ? AppTheme.white : AppTheme.zinc950, fontSize: 18, height: 1.5),
                          decoration: InputDecoration(
                            hintText: _isTruthMode
                                ? 'What do you want to know?'
                                : 'What should they do?',
                            hintStyle: TextStyle(color: isDark ? AppTheme.zinc700 : AppTheme.zinc400),
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
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.paddingOf(context).bottom + 20),
            child: CustomButton(
              text: 'Send ${_isTruthMode ? "Truth" : "Dare"}',
              isLoading: isLoading,
              onPressed: () async {
                if (_inputController.text.isEmpty) return;
                bool success;
                if (_isTruthMode) {
                  success = await context.read<TruthDareProvider>().sendTruth(
                    context,
                    widget.recipient.id,
                    _inputController.text,
                  );
                } else {
                  success = await context.read<TruthDareProvider>().sendDare(
                    context,
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
              backgroundColor: isDark ? AppTheme.white : AppTheme.black,
              textColor: isDark ? AppTheme.black : AppTheme.white,
              icon: Icon(LucideIcons.send, size: 20, color: isDark ? AppTheme.black : AppTheme.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(bool mode, String title, String pts) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _isTruthMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _isTruthMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? AppTheme.white : AppTheme.black) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? (isDark ? AppTheme.black : AppTheme.white) : AppTheme.zinc500,
              ),
            ),
            Text(
              pts,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected 
                    ? (isDark ? AppTheme.black.withValues(alpha: 0.5) : AppTheme.white.withValues(alpha: 0.7)) 
                    : (isDark ? AppTheme.zinc700 : AppTheme.zinc500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
