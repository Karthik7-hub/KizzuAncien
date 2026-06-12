import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/challenge.dart';
import '../theme/app_theme.dart';
import '../screens/note_viewer_screen.dart';

class NotePreviewCard extends StatelessWidget {
  final Note note;
  final String? displayTitle;
  final bool showOnlyTitle;

  const NotePreviewCard({
    super.key, 
    required this.note, 
    this.displayTitle,
    this.showOnlyTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (note.type == 'link') {
      return _LinkNoteWidget(note: note, displayTitle: displayTitle);
    }

    if (note.type == 'code') {
      return _CodePreviewWidget(note: note, displayTitle: displayTitle, showOnlyTitle: showOnlyTitle);
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => NoteViewerScreen(note: note),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.05);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: animation.drive(tween), child: child),
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.zinc950,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.zinc900),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        note.type.toUpperCase(),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1.2),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 14, color: AppTheme.zinc800),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayTitle ?? (note.title?.isNotEmpty == true ? note.title! : _getDefaultTitle()),
                    style: const TextStyle(color: AppTheme.white, fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!showOnlyTitle) ...[
                    const SizedBox(height: 4),
                    _buildPreviewContent(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;
    switch (note.type) {
      case 'explanation':
        icon = LucideIcons.fileText;
        color = Colors.blueAccent;
        break;
      case 'code':
        icon = LucideIcons.code;
        color = Colors.purpleAccent;
        break;
      case 'image':
        icon = LucideIcons.image;
        color = Colors.greenAccent;
        break;
      default:
        icon = LucideIcons.stickyNote;
        color = AppTheme.zinc500;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _getDefaultTitle() {
    switch (note.type) {
      case 'explanation': return 'Explanation';
      case 'code': return 'Code Solution';
      case 'image': return 'Image Attachment';
      default: return 'Note';
    }
  }

  Widget _buildPreviewContent() {
    if (note.type == 'image') {
      return Container(
        height: 64,
        width: 100,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: AppTheme.zinc900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: note.content,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppTheme.zinc900,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 1, color: AppTheme.zinc800)),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(LucideIcons.imageOff, size: 20, color: AppTheme.zinc800),
            ),
          ),
        ),
      );
    }

    String preview = note.content;
    if (note.type == 'code') {
      final lang = note.metadata?['language'] ?? 'dart';
      final lineCount = note.content.split('\n').length;
      preview = '$lang • $lineCount lines';
      return Text(preview, style: const TextStyle(color: AppTheme.zinc500, fontSize: 13));
    }

    return Text(
      preview,
      style: const TextStyle(color: AppTheme.zinc500, fontSize: 13, height: 1.4),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _LinkNoteWidget extends StatelessWidget {
  final Note note;
  final String? displayTitle;
  const _LinkNoteWidget({required this.note, this.displayTitle});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchURL(note.content),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.zinc950,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.zinc900),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.zinc900,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(LucideIcons.link, color: AppTheme.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'LINK',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1.2),
                      ),
                      const Icon(LucideIcons.externalLink, color: AppTheme.zinc800, size: 14),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayTitle ?? (note.title ?? 'Resource Link'),
                    style: const TextStyle(color: AppTheme.white, fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.content,
                    style: const TextStyle(color: AppTheme.zinc600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodePreviewWidget extends StatefulWidget {
  final Note note;
  final String? displayTitle;
  final bool showOnlyTitle;
  const _CodePreviewWidget({required this.note, this.displayTitle, this.showOnlyTitle = false});

  @override
  State<_CodePreviewWidget> createState() => _CodePreviewWidgetState();
}

class _CodePreviewWidgetState extends State<_CodePreviewWidget> {
  bool _isWrapped = true;

  @override
  Widget build(BuildContext context) {
    final language = widget.note.metadata?['language'] ?? 'dart';
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.zinc950,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.zinc900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                const Icon(LucideIcons.code, size: 14, color: AppTheme.zinc600),
                const SizedBox(width: 8),
                Text(
                  language.toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.zinc600, letterSpacing: 1.2),
                ),
                const Spacer(),
                if (!widget.showOnlyTitle) ...[
                  _buildToolbarButton(
                    icon: _isWrapped ? LucideIcons.wrapText : LucideIcons.alignLeft,
                    onTap: () => setState(() => _isWrapped = !_isWrapped),
                    isActive: _isWrapped,
                  ),
                  _buildToolbarButton(
                    icon: LucideIcons.copy,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.note.content));
                      HapticFeedback.lightImpact();
                    },
                  ),
                ],
                _buildToolbarButton(
                  icon: widget.showOnlyTitle ? LucideIcons.chevronRight : LucideIcons.maximize2,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NoteViewerScreen(note: widget.note)),
                    );
                  },
                ),
              ],
            ),
          ),
          
          if (!widget.showOnlyTitle) ...[
            // Code Content
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.zinc900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.note.content,
                style: const TextStyle(
                  color: AppTheme.zinc300,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                softWrap: _isWrapped,
              ),
            ),
          ],
          
          // Bottom Info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Text(
                  widget.displayTitle ?? (widget.note.title ?? 'Code Solution'),
                  style: const TextStyle(color: AppTheme.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (!widget.showOnlyTitle) ...[
                   const Spacer(),
                   const Icon(LucideIcons.chevronRight, size: 14, color: AppTheme.zinc800),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({required IconData icon, required VoidCallback onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.zinc900 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: isActive ? AppTheme.white : AppTheme.zinc700),
      ),
    );
  }
}
