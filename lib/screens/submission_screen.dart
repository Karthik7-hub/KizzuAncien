import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../models/note.dart';
import '../providers/challenge_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/form_label.dart';
import '../widgets/note_preview_card.dart';
import '../widgets/empty_state.dart';

class SubmissionScreen extends StatefulWidget {
  final Challenge challenge;
  const SubmissionScreen({super.key, required this.challenge});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final List<String> _selectedNoteIds = [];
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);
    
    final challengeProvider = context.read<ChallengeProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Call submitProof with the chosen notes and summary text
    final success = await challengeProvider.submitProof(
      widget.challenge.id,
      proofText: _commentController.text.trim(),
      proofType: widget.challenge.proofType,
      selectedNotes: _selectedNoteIds,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Solution submitted successfully!'), behavior: SnackBarBehavior.floating),
        );
        // Pop back to challenge details (pop submission screen, pop workspace screen)
        navigator.pop();
        navigator.pop();
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to submit solution. Please try again.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = context.watch<ChallengeProvider>();
    final notes = challengeProvider.challengeNotes[widget.challenge.id] ?? [];


    return Scaffold(
      appBar: const AppHeader(
        title: 'Create Submission',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FormLabel(
                    label: 'SUBMISSION SUMMARY',
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                  ),
                  CustomTextField(
                    controller: _commentController,
                    hintText: 'Describe your final answer or solution...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),
                  const FormLabel(
                    label: 'SELECT NOTES FOR SOLUTION',
                    padding: EdgeInsets.only(left: 4, bottom: 4),
                  ),
                  Text(
                    'Choose notes from your workspace that document your final work.',
                    style: TextStyle(
                      fontSize: 11, 
                      color: Theme.of(context).textTheme.labelSmall?.color
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (notes.isEmpty)
                    const EmptyState(
                      icon: LucideIcons.layers,
                      title: 'No notes in workspace',
                      subtitle: 'Go back and add notes to your workspace first.',
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        final isSelected = _selectedNoteIds.contains(note.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildSelectableNoteItem(note, isSelected),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          _buildSubmitActionArea(),
        ],
      ),
    );
  }

  Widget _buildSelectableNoteItem(Note note, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedNoteIds.remove(note.id);
          } else {
            _selectedNoteIds.add(note.id);
          }
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 24, right: 16),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColor : (isDark ? AppTheme.zinc800 : AppTheme.zinc300),
                width: 2,
              ),
            ),
            child: isSelected 
                ? Icon(LucideIcons.check, size: 14, color: Theme.of(context).scaffoldBackgroundColor) 
                : null,
          ),
          Expanded(
            child: NotePreviewCard(
              note: note,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedNoteIds.remove(note.id);
                  } else {
                    _selectedNoteIds.add(note.id);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitActionArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool canSubmit = _selectedNoteIds.isNotEmpty && !_isSubmitting;
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: CustomButton(
            text: 'Submit Final Answer',
            onPressed: canSubmit ? _handleSubmit : null,
            isLoading: _isSubmitting,
            backgroundColor: Theme.of(context).primaryColor,
            textColor: Theme.of(context).scaffoldBackgroundColor,
            icon: Icon(LucideIcons.send, size: 16, color: Theme.of(context).scaffoldBackgroundColor),
          ),
        ),
      ),
    );
  }
}
