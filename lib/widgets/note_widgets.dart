import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/challenge.dart';
import '../theme/app_theme.dart';

class ExplanationNoteWidget extends StatelessWidget {
  final Note note;
  const ExplanationNoteWidget({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.zinc900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.zinc800.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.title != null && note.title!.isNotEmpty) ...[
            Text(
              note.title!.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.zinc500,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
          ],
          MarkdownBody(
            data: note.content,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: AppTheme.white, fontSize: 14, height: 1.6),
              listBullet: const TextStyle(color: AppTheme.zinc500),
              h1: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
              h2: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
              code: const TextStyle(
                backgroundColor: AppTheme.black,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CodeNoteWidget extends StatefulWidget {
  final Note note;
  const CodeNoteWidget({super.key, required this.note});

  @override
  State<CodeNoteWidget> createState() => _CodeNoteWidgetState();
}

class _CodeNoteWidgetState extends State<CodeNoteWidget> {
  bool _isExpanded = false;

  Widget _buildLineNumbers(String code) {
    final int lineCount = code.split('\n').length;
    final String lineNumbers = List.generate(lineCount, (i) => '${i + 1}').join('\n');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFF3e4451), width: 1)),
      ),
      child: Text(
        lineNumbers,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Color(0xFF636d83),
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String language = widget.note.metadata?['language'] ?? 'dart';
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF282c34), // Atom One Dark background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.zinc800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  language.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc500),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.copy, size: 14, color: AppTheme.zinc500),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.note.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard'), duration: Duration(seconds: 1)),
                    );
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(_isExpanded ? LucideIcons.minimize2 : LucideIcons.maximize2, size: 14, color: AppTheme.zinc500),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: _isExpanded ? double.infinity : 300,
            ),
            child: SingleChildScrollView(
              physics: _isExpanded ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
              scrollDirection: Axis.vertical,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLineNumbers(widget.note.content),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: HighlightView(
                        widget.note.content,
                        language: language,
                        theme: atomOneDarkTheme,
                        padding: const EdgeInsets.all(16),
                        textStyle: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_isExpanded && widget.note.content.split('\n').length > 15)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppTheme.black.withValues(alpha: 0.8)],
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: const Icon(LucideIcons.chevronDown, size: 16, color: AppTheme.zinc500),
              ),
            ),
        ],
      ),
    );
  }
}

class ImageNoteWidget extends StatelessWidget {
  final Note note;
  const ImageNoteWidget({super.key, required this.note});

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, note.content),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.zinc800),
          color: AppTheme.zinc950,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(
                imageUrl: note.content,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(height: 200, color: AppTheme.zinc900, child: const Center(child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))),
                errorWidget: (context, url, error) => Container(height: 100, color: AppTheme.zinc900, child: const Icon(LucideIcons.imageOff, color: AppTheme.zinc700)),
              ),
              if (note.title != null && note.title!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    note.title!,
                    style: const TextStyle(color: AppTheme.zinc400, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class LinkNoteWidget extends StatelessWidget {
  final Note note;
  const LinkNoteWidget({super.key, required this.note});

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.zinc950,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.zinc900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.link, color: AppTheme.white, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title ?? 'Resource Link',
                    style: const TextStyle(color: AppTheme.white, fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.content,
                    style: const TextStyle(color: AppTheme.zinc600, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.externalLink, color: AppTheme.zinc700, size: 16),
          ],
        ),
      ),
    );
  }
}
