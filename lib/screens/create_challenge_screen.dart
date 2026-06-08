import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kizzu_ancien/models/user.dart';
import 'package:kizzu_ancien/providers/challenge_provider.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/widgets/custom_button.dart';
import 'package:kizzu_ancien/widgets/custom_text_field.dart';
import '../widgets/avatar_widget.dart';

class CreateChallengeScreen extends StatefulWidget {
  final User? recipient;
  const CreateChallengeScreen({super.key, this.recipient});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _deadline = 'today';
  String _proofType = 'any';
  bool _isLaunching = false;

  @override
  Widget build(BuildContext context) {
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
          'New Challenge',
          style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.recipient != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.zinc900,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.zinc800),
                      ),
                      child: Row(
                        children: [
                          const Text('Targeting:', style: TextStyle(color: AppTheme.zinc500, fontSize: 14)),
                          const SizedBox(width: 12),
                          AvatarWidget(user: widget.recipient!, size: 32),
                          const SizedBox(width: 10),
                          Text(widget.recipient!.name, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  _buildLabel('CHALLENGE TITLE'),
                  CustomTextField(controller: _titleController, hintText: 'e.g. Morning 5km Run'),
                  const SizedBox(height: 20),
                  _buildLabel('DETAILS'),
                  CustomTextField(controller: _descController, hintText: 'Explain the rules...', maxLines: 4),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('DEADLINE'),
                            _buildDropdown(
                              value: _deadline,
                              items: const [
                                DropdownMenuItem(value: 'today', child: Text('Today')),
                                DropdownMenuItem(value: 'tomorrow', child: Text('Tomorrow')),
                              ],
                              onChanged: (val) => setState(() => _deadline = val!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('PROOF TYPE'),
                            _buildDropdown(
                              value: _proofType,
                              items: const [
                                DropdownMenuItem(value: 'any', child: Text('Any')),
                                DropdownMenuItem(value: 'image', child: Text('Photo')),
                                DropdownMenuItem(value: 'video', child: Text('Video')),
                                DropdownMenuItem(value: 'text', child: Text('Text')),
                              ],
                              onChanged: (val) => setState(() => _proofType = val!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.black.withValues(alpha: 0), AppTheme.black],
              ),
            ),
            child: CustomButton(
              text: 'Launch Challenge',
              isLoading: _isLaunching,
              onPressed: () async {
                if (widget.recipient == null || _isLaunching) return;
                setState(() => _isLaunching = true);
                
                final challengeProvider = context.read<ChallengeProvider>();
                final success = await challengeProvider.createChallenge({
                  'recipientId': widget.recipient!.id,
                  'title': _titleController.text,
                  'description': _descController.text,
                  'deadline': _deadline == 'today' 
                      ? DateTime.now().add(const Duration(hours: 12)).toIso8601String()
                      : DateTime.now().add(const Duration(days: 1)).toIso8601String(),
                  'proofType': _proofType,
                });
                
                if (!context.mounted) return;
                if (success) {
                  Navigator.of(context).pop();
                } else {
                  setState(() => _isLaunching = false);
                }
              },
              backgroundColor: AppTheme.white,
              textColor: AppTheme.black,
              icon: const Icon(LucideIcons.rocket, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.zinc600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.zinc900,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.zinc800.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppTheme.zinc900,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppTheme.zinc500),
          style: const TextStyle(color: AppTheme.white, fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
