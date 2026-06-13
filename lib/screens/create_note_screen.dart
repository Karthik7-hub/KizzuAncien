import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/note.dart';
import '../providers/challenge_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/form_label.dart';

class CreateNoteScreen extends StatefulWidget {
  final String challengeId;
  final NoteType? initialType;
  final Note? noteToEdit;

  const CreateNoteScreen({
    super.key, 
    required this.challengeId, 
    this.initialType,
    this.noteToEdit,
  });

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();
  
  bool _isKeyboardOpen = false;
  
  late NoteType _selectedType;
  String _selectedLanguage = 'C++';
  List<String> _remoteImages = [];
  final List<File> _selectedImages = [];
  bool _isSaving = false;

  final List<String> _languages = ['C++', 'Python', 'Java', 'JavaScript', 'Dart'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.noteToEdit != null) {
      final note = widget.noteToEdit!;
      _titleController.text = note.title;
      _descriptionController.text = note.description ?? '';
      _selectedType = note.type;
      
      switch (note.type) {
        case NoteType.code:
          _contentController.text = note.code;
          _selectedLanguage = note.language;
          break;
        case NoteType.explanation:
          _contentController.text = note.explanation;
          break;
        case NoteType.image:
          _remoteImages = List<String>.from(note.images);
          break;
        case NoteType.link:
          _urlController.text = note.url;
          break;
      }
    } else {
      _selectedType = widget.initialType ?? NoteType.explanation;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) return;
    final view = View.maybeOf(context) ?? WidgetsBinding.instance.platformDispatcher.views.first;
    final double bottomInset = view.viewInsets.bottom;
    final bool isKeyboardOpen = bottomInset > 0;
    if (isKeyboardOpen != _isKeyboardOpen) {
      setState(() {
        _isKeyboardOpen = isKeyboardOpen;
      });
    }
  }

  bool get _canSave {
    if (_isSaving) return false;
    switch (_selectedType) {
      case NoteType.code:
        return _contentController.text.trim().isNotEmpty;
      case NoteType.explanation:
        return _contentController.text.trim().isNotEmpty;
      case NoteType.image:
        return _remoteImages.isNotEmpty || _selectedImages.isNotEmpty;
      case NoteType.link:
        return _urlController.text.trim().isNotEmpty && Uri.tryParse(_urlController.text.trim())?.hasAbsolutePath == true;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    if (source == ImageSource.camera) {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } else {
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((f) => File(f.path)));
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_canSave) return;
    
    setState(() => _isSaving = true);
    
    final Map<String, dynamic> content = {};
    switch (_selectedType) {
      case NoteType.code:
        content['code'] = _contentController.text.trim();
        content['language'] = _selectedLanguage;
        break;
      case NoteType.explanation:
        content['explanation'] = _contentController.text.trim();
        break;
      case NoteType.image:
        content['images'] = _remoteImages;
        break;
      case NoteType.link:
        content['url'] = _urlController.text.trim();
        break;
    }

    final provider = context.read<ChallengeProvider>();
    bool success;
    
    if (widget.noteToEdit != null) {
      success = await provider.updateNote(
        widget.challengeId,
        widget.noteToEdit!.id,
        {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'type': _selectedType.name,
          'content': content,
        },
        files: _selectedType == NoteType.image ? _selectedImages : null,
      );
    } else {
      success = await provider.createNote(
        widget.challengeId,
        {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'type': _selectedType.name,
          'content': content,
        },
        files: _selectedType == NoteType.image ? _selectedImages : null,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save note. Please try again.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppHeader(
        title: widget.noteToEdit != null ? 'Edit Note' : 'Create Note',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, _isKeyboardOpen ? 340.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.noteToEdit == null && widget.initialType == null) ...[
                    _buildTypeSelector(),
                    const SizedBox(height: 32),
                  ] else ...[
                    _buildTypeHeader(),
                    const SizedBox(height: 24),
                  ],
                  _buildLabel('TITLE'),
                  CustomTextField(
                    controller: _titleController,
                    hintText: 'Note Title',
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('DESCRIPTION (OPTIONAL)'),
                  CustomTextField(
                    controller: _descriptionController,
                    hintText: 'Short summary...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  _buildTypeSpecificFields(),
                ],
              ),
            ),
          ),
          if (!_isKeyboardOpen) _buildActionArea(),
        ],
      ),
    );
  }

  Widget _buildTypeHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String labelText;
    IconData iconData;
    switch (_selectedType) {
      case NoteType.code:
        labelText = 'Code Template';
        iconData = LucideIcons.code;
        break;
      case NoteType.explanation:
        labelText = 'Text Explanation';
        iconData = LucideIcons.fileText;
        break;
      case NoteType.image:
        labelText = 'Image Attachment';
        iconData = LucideIcons.image;
        break;
      case NoteType.link:
        labelText = 'External Resource Link';
        iconData = LucideIcons.link;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.black : AppTheme.zinc100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOTE TYPE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.labelSmall?.color,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  labelText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: NoteType.values.map((type) {
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(type.name.toUpperCase()),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedType = type);
              },
              selectedColor: primaryColor,
              backgroundColor: isDark ? AppTheme.zinc900 : AppTheme.zinc100,
              labelStyle: TextStyle(
                color: isSelected ? bgColor : AppTheme.zinc500,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? primaryColor : (isDark ? AppTheme.zinc800 : AppTheme.zinc200)),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeSpecificFields() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (_selectedType) {
      case NoteType.code:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('LANGUAGE'),
            _buildLanguageDropdown(),
            const SizedBox(height: 24),
            _buildLabel('CODE'),
            CustomTextField(
              controller: _contentController,
              hintText: 'Paste code here...',
              maxLines: 10,
            ),
          ],
        );
      case NoteType.explanation:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('EXPLANATION'),
            CustomTextField(
              controller: _contentController,
              hintText: 'Write your explanation...',
              maxLines: 8,
            ),
          ],
        );
      case NoteType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('IMAGES'),
            const SizedBox(height: 12),
            if (_remoteImages.isNotEmpty || _selectedImages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._remoteImages.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final url = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppTheme.zinc800 : AppTheme.zinc200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(child: CircularProgressIndicator(color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 1.5)),
                                errorWidget: (context, url, err) => const Icon(LucideIcons.imageOff),
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () => setState(() => _remoteImages.removeAt(idx)),
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(LucideIcons.x, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    ..._selectedImages.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final file = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                          border: Border.all(color: isDark ? AppTheme.zinc800 : AppTheme.zinc200),
                        ),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImages.removeAt(idx)),
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(LucideIcons.x, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceBtn(
                    LucideIcons.camera, 
                    'Take Photo', 
                    () => _pickImage(ImageSource.camera)
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImageSourceBtn(
                    LucideIcons.image, 
                    'Gallery', 
                    () => _pickImage(ImageSource.gallery)
                  ),
                ),
              ],
            ),
          ],
        );
      case NoteType.link:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('URL'),
            CustomTextField(
              controller: _urlController,
              hintText: 'https://...',
              keyboardType: TextInputType.url,
            ),
          ],
        );
    }
  }

  Widget _buildLanguageDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.zinc900 : AppTheme.zinc100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.zinc800 : AppTheme.zinc200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          dropdownColor: Theme.of(context).cardTheme.color,
          isExpanded: true,
          icon: Icon(LucideIcons.chevronDown, color: Theme.of(context).textTheme.labelSmall?.color, size: 16),
          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14),
          onChanged: (val) {
            if (val != null) setState(() => _selectedLanguage = val);
          },
          items: _languages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return FormLabel(
      label: text,
      padding: const EdgeInsets.only(left: 4, bottom: 8),
    );
  }

  Widget _buildActionArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200)),
      ),
      child: SafeArea(
        top: false,
        child: CustomButton(
          text: widget.noteToEdit != null ? 'Update Note' : 'Save Note',
          onPressed: _canSave ? _handleSave : null,
          isLoading: _isSaving,
          backgroundColor: Theme.of(context).primaryColor,
          textColor: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
    );
  }

  Widget _buildImageSourceBtn(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.black : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).textTheme.labelSmall?.color, size: 24),
            const SizedBox(height: 8),
            Text(
              label, 
              style: TextStyle(
                color: Theme.of(context).textTheme.labelLarge?.color, 
                fontSize: 12, 
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
      ),
    );
  }
}
