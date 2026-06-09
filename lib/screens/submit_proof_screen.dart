import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/avatar_widget.dart';
import '../utils/logger.dart';

class SubmitProofScreen extends StatefulWidget {
  final Challenge challenge;
  const SubmitProofScreen({super.key, required this.challenge});

  @override
  State<SubmitProofScreen> createState() => _SubmitProofScreenState();
}

class _SubmitProofScreenState extends State<SubmitProofScreen> {
  final TextEditingController _textController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress for faster upload
        maxWidth: 1200,   // Prevent massive resolution issues
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      AppLogger.error('Error picking image', e);
    }
  }

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
          'Complete Challenge',
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.zinc900,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppTheme.zinc800),
                    ),
                    child: Column(
                      children: [
                        AvatarWidget(user: widget.challenge.creator, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          widget.challenge.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Requested by ${widget.challenge.creator.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.zinc500, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        'UPLOAD PROOF',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                  if (_imageFile != null)
                    Stack(
                      children: [
                        Container(
                          height: 240,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.zinc800),
                            image: DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => setState(() => _imageFile = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: _buildProofOption(LucideIcons.camera, 'Camera', () => _pickImage(ImageSource.camera))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildProofOption(LucideIcons.image, 'Gallery', () => _pickImage(ImageSource.gallery))),
                      ],
                    ),
                  const SizedBox(height: 24),
                  CustomTextField(controller: _textController, hintText: 'Add a comment about your progress...', maxLines: 4),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: CustomButton(
              text: 'Submit Verification',
              isLoading: context.watch<ChallengeProvider>().isLoading,
              onPressed: () async {
                try {
                  final success = await context.read<ChallengeProvider>().submitProof(
                    widget.challenge.id,
                    proofText: _textController.text,
                    proofType: widget.challenge.proofType,
                    file: _imageFile,
                  );
                  if (success && context.mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                   // Error handled by provider
                }
              },
              backgroundColor: AppTheme.white,
              textColor: AppTheme.black,
              icon: const Icon(LucideIcons.checkCircle2, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.zinc900,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.white, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppTheme.zinc400, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
