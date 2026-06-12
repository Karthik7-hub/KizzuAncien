import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/keyboard_spacer.dart';

class SubmitProofScreen extends StatefulWidget {
  final Challenge challenge;
  final ChallengeSubmission? existingSubmission;
  
  const SubmitProofScreen({super.key, required this.challenge, this.existingSubmission});

  @override
  State<SubmitProofScreen> createState() => _SubmitProofScreenState();
}

class _SubmitProofScreenState extends State<SubmitProofScreen> {
  final List<Note> _notes = [];
  List<Note> _initialNotes = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSubmission != null && widget.existingSubmission!.versions.isNotEmpty) {
      // Initialize with latest version's notes if editing
      final latestVersion = widget.existingSubmission!.versions.last;
      _notes.addAll(latestVersion.notes.map((n) => Note(
        id: n.id,
        type: n.type,
        title: n.title,
        content: n.content,
        metadata: n.metadata != null ? Map<String, String>.from(n.metadata!) : null,
        version: n.version,
        createdAt: n.createdAt,
        updatedAt: n.updatedAt,
      )));
      // Deep copy for change detection
      _initialNotes = List.from(_notes);
    }
  }

  bool _hasChanges() {
    if (widget.existingSubmission == null) return _notes.isNotEmpty;
    if (_notes.length != _initialNotes.length) return true;
    
    for (int i = 0; i < _notes.length; i++) {
      final n1 = _notes[i];
      final n2 = _initialNotes[i];
      if (n1.id != n2.id || n1.content != n2.content || n1.title != n2.title || n1.type != n2.type) {
        return true;
      }
      // Check metadata (specifically for code language)
      if (n1.metadata?.length != n2.metadata?.length) return true;
      if (n1.metadata != null && n2.metadata != null) {
        for (var key in n1.metadata!.keys) {
          if (n1.metadata![key] != n2.metadata![key]) return true;
        }
      }
    }
    return false;
  }

  void _addNote(String type) async {
    if (type == 'explanation') {
      _showEditNoteDialog(Note(id: '', type: 'explanation', content: '', version: 1, createdAt: DateTime.now(), updatedAt: DateTime.now()));
    } else if (type == 'code') {
      _showEditNoteDialog(Note(id: '', type: 'code', content: '', version: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(), metadata: {'language': 'dart'}));
    } else if (type == 'link') {
      _showEditNoteDialog(Note(id: '', type: 'link', content: '', version: 1, createdAt: DateTime.now(), updatedAt: DateTime.now()));
    } else if (type == 'image') {
      _showImageSourceSelection();
    }
  }

  void _showImageSourceSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.zinc950,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.zinc900, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 32),
            const Text(
              'SELECT IMAGE SOURCE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildHorizontalSourceOption(
                    icon: LucideIcons.camera,
                    label: 'Take Photo',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHorizontalSourceOption(
                    icon: LucideIcons.image,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.zinc900,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.white, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    if (_isSubmitting) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
    
    if (image != null) {
      if (mounted) {
        setState(() => _isSubmitting = true);
        try {
          final url = await context.read<ChallengeProvider>().uploadAttachment(File(image.path));
          if (url != null) {
            setState(() {
              _notes.add(Note(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: 'image',
                content: url,
                version: 1,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ));
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: ${e.toString()}'))
            );
          }
        } finally {
          if (mounted) setState(() => _isSubmitting = false);
        }
      }
    }
  }

  void _showEditNoteDialog(Note note, {int? index}) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);
    String selectedLanguage = note.metadata?['language'] ?? 'cpp';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.zinc950,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final bool isContentEmpty = contentController.text.trim().isEmpty;

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${index == null ? "Add" : "Edit"} ${note.type.replaceFirst(note.type[0], note.type[0].toUpperCase())}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.white),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, color: AppTheme.zinc700, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: AppTheme.white),
                      decoration: InputDecoration(
                        hintText: 'Title (Optional)',
                        hintStyle: const TextStyle(color: AppTheme.zinc700),
                        filled: true,
                        fillColor: AppTheme.zinc900,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (note.type == 'code') ...[
                      const Text('LANGUAGE', style: TextStyle(color: AppTheme.zinc600, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: AppTheme.zinc900, borderRadius: BorderRadius.circular(16)),
                        child: DropdownButton<String>(
                          value: selectedLanguage,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: AppTheme.zinc900,
                          items: ['cpp', 'dart', 'javascript', 'python', 'html', 'css', 'java'].map((lang) {
                            return DropdownMenuItem(value: lang, child: Text(lang.toUpperCase(), style: const TextStyle(color: AppTheme.white, fontSize: 13)));
                          }).toList(),
                          onChanged: (val) => setModalState(() => selectedLanguage = val!),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: contentController,
                      onChanged: (_) => setModalState(() {}),
                      maxLines: note.type == 'explanation' || note.type == 'code' ? 8 : 1,
                      style: const TextStyle(color: AppTheme.white, fontFamily: 'monospace', fontSize: 14),
                      decoration: InputDecoration(
                        hintText: note.type == 'link' ? 'https://...' : 'Write something...',
                        hintStyle: const TextStyle(color: AppTheme.zinc700),
                        filled: true,
                        fillColor: AppTheme.zinc900,
                        contentPadding: const EdgeInsets.all(20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: isContentEmpty ? 'Enter Required Fields' : 'Save Note',
                      isLoading: false,
                      onPressed: isContentEmpty ? null : () {
                        String content = contentController.text.trim();
                        if (note.type == 'link') {
                          // More flexible URL validation
                          if (!content.contains('.')) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Please enter a valid link'), backgroundColor: Colors.redAccent)
                             );
                             return;
                          }
                          if (!content.startsWith('http')) {
                            content = 'https://$content';
                          }
                        }

                        final updatedNote = Note(
                          id: note.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : note.id,
                          type: note.type,
                          title: titleController.text.trim(),
                          content: content,
                          metadata: note.type == 'code' ? {'language': selectedLanguage} : null,
                          version: note.version,
                          createdAt: note.createdAt,
                          updatedAt: DateTime.now(),
                        );
                        setState(() {
                          if (index == null) {
                            _notes.add(updatedNote);
                          } else {
                            _notes[index] = updatedNote;
                          }
                        });
                        Navigator.pop(context);
                      },
                      backgroundColor: isContentEmpty ? AppTheme.zinc900 : AppTheme.white,
                      textColor: isContentEmpty ? AppTheme.zinc600 : AppTheme.black,
                    ),
                    const IsolatedKeyboardSpacer(additionalPadding: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleSubmit() async {
    if (!_hasChanges() || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    
    try {
      bool success;
      if (widget.existingSubmission == null) {
        success = await context.read<ChallengeProvider>().submitNotes(widget.challenge.id, _notes);
      } else {
        success = await context.read<ChallengeProvider>().editSubmission(widget.existingSubmission!.id, _notes);
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit. Please try again.')));
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.white),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.existingSubmission == null ? 'NEW SUBMISSION' : 'EDIT SUBMISSION',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _notes.isEmpty 
              ? _buildEmptyState() 
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  itemCount: _notes.length,
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final item = _notes.removeAt(oldIndex);
                      _notes.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    
                    // Smart naming logic for preview
                    String? smartTitle = note.title;
                    if (smartTitle == null || smartTitle.isEmpty) {
                      int typeCount = 0;
                      for (int i = 0; i <= index; i++) {
                        if (_notes[i].type == note.type && (_notes[i].title == null || _notes[i].title!.isEmpty)) {
                          typeCount++;
                        }
                      }
                      smartTitle = 'Untitled ${note.type.replaceFirst(note.type[0], note.type[0].toUpperCase())} $typeCount';
                    }

                    return Padding(
                      key: ValueKey(note.id),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildNoteItem(note, index, smartTitle),
                    );
                  },
                ),
          ),
          _buildBottomActions(),
          const IsolatedKeyboardSpacer(),
        ],
      ),
    );
  }

  Widget _buildNoteItem(Note note, int index, String smartTitle) {
    IconData icon = LucideIcons.fileText;
    if (note.type == 'code') icon = LucideIcons.code;
    if (note.type == 'image') icon = LucideIcons.image;
    if (note.type == 'link') icon = LucideIcons.link;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.zinc900.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: AppTheme.white, size: 20),
        title: Text(
          smartTitle,
          style: const TextStyle(color: AppTheme.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          note.type == 'image' ? 'Image Attachment' : note.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.zinc600, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.edit3, size: 16, color: AppTheme.zinc500),
              onPressed: _isSubmitting ? null : () => _showEditNoteDialog(note, index: index),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 16, color: AppTheme.zinc500),
              onPressed: _isSubmitting ? null : () => setState(() => _notes.removeAt(index)),
            ),
            ReorderableDragStartListener(
              index: index,
              enabled: !_isSubmitting,
              child: const Padding(
                padding: EdgeInsets.only(left: 8, right: 4),
                child: Icon(LucideIcons.gripVertical, size: 18, color: AppTheme.zinc700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.stickyNote, size: 48, color: AppTheme.zinc900),
          SizedBox(height: 16),
          Text(
            'Your submission is empty.\nAdd notes to explain your solution.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.zinc700, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration:
      const BoxDecoration(
        color: AppTheme.black,
        border: Border(top: BorderSide(color: AppTheme.zinc900)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAddAction(LucideIcons.fileText, 'EXPLANATION', () => _addNote('explanation')),
              _buildAddAction(LucideIcons.code, 'CODE', () => _addNote('code')),
              _buildAddAction(LucideIcons.image, 'IMAGE', () => _addNote('image')),
              _buildAddAction(LucideIcons.link, 'LINK', () => _addNote('link')),
            ],
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: widget.existingSubmission == null ? 'Submit Solution' : 'Update & Re-verify',
            isLoading: _isSubmitting,
            onPressed: !_hasChanges() || _isSubmitting ? null : _handleSubmit,
            backgroundColor: AppTheme.white,
            textColor: AppTheme.black,
          ),
        ],
      ),
    );
  }

  Widget _buildAddAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isSubmitting ? null : onTap,
      child: Opacity(
        opacity: _isSubmitting ? 0.5 : 1.0,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.zinc900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.zinc800),
              ),
              child: Icon(icon, color: AppTheme.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppTheme.zinc600, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}
