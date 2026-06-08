import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kizzu_ancien/models/challenge.dart';
import 'package:kizzu_ancien/providers/challenge_provider.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/widgets/custom_button.dart';
import '../widgets/avatar_widget.dart';

class ReviewScreen extends StatefulWidget {
  final Challenge challenge;
  const ReviewScreen({super.key, required this.challenge});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  Map<String, dynamic>? _submission;
  bool _isDataLoading = true;
  bool _isVerifying = false;
  bool _isDeclining = false;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    final sub = await context.read<ChallengeProvider>().fetchSubmission(widget.challenge.id);
    if (mounted) {
      setState(() {
        _submission = sub;
        _isDataLoading = false;
      });
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
          'Verification',
          style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.zinc900,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AvatarWidget(user: widget.challenge.recipient, size: 36),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('SUBMITTED BY', style: TextStyle(color: AppTheme.zinc600, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      Text(widget.challenge.recipient.name, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                widget.challenge.title,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 12),
                          child: Text(
                            'EVIDENCE PROVIDED',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1.5),
                          ),
                        ),
                        if (_submission?['proofUrl'] != null)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppTheme.zinc900),
                              color: AppTheme.zinc950,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: CachedNetworkImage(
                                imageUrl: _submission!['proofUrl'],
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 200,
                                  color: AppTheme.zinc950,
                                  child: const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2)),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 100,
                                  color: AppTheme.zinc950,
                                  child: const Icon(LucideIcons.imageOff, color: AppTheme.zinc700),
                                ),
                              ),
                            ),
                          ),
                        if (_submission?['proofText'] != null && _submission!['proofText'].toString().isNotEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.zinc900.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppTheme.zinc800),
                            ),
                            child: Text(
                              _submission!['proofText'],
                              style: const TextStyle(color: AppTheme.white, fontSize: 15, height: 1.6),
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  decoration: const BoxDecoration(
                    color: AppTheme.black,
                    border: Border(top: BorderSide(color: AppTheme.zinc900)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Decline',
                          isLoading: _isDeclining,
                          onPressed: (_isVerifying || _isDeclining) ? null : () async {
                            setState(() => _isDeclining = true);
                            final success = await context.read<ChallengeProvider>().reviewSubmission(widget.challenge.id, 'rejected');
                            if (!context.mounted) {
                              return;
                            }
                            if (success) {
                              Navigator.of(context).pop();
                            } else {
                              setState(() => _isDeclining = false);
                            }
                          },
                          backgroundColor: AppTheme.zinc900,
                          textColor: AppTheme.white,
                          borderColor: AppTheme.zinc800,
                          icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Verify',
                          isLoading: _isVerifying,
                          onPressed: (_isVerifying || _isDeclining) ? null : () async {
                            setState(() => _isVerifying = true);
                            final success = await context.read<ChallengeProvider>().reviewSubmission(widget.challenge.id, 'approved');
                            if (!context.mounted) {
                              return;
                            }
                            if (success) {
                              Navigator.of(context).pop();
                            } else {
                              setState(() => _isVerifying = false);
                            }
                          },
                          backgroundColor: AppTheme.white,
                          textColor: AppTheme.black,
                          icon: const Icon(LucideIcons.check, size: 18, color: AppTheme.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
