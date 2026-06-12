import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/challenge.dart';
import '../theme/app_theme.dart';

class NoteViewerScreen extends StatefulWidget {
  final Note note;
  const NoteViewerScreen({super.key, required this.note});

  @override
  State<NoteViewerScreen> createState() => _NoteViewerScreenState();
}

class _NoteViewerScreenState extends State<NoteViewerScreen> {
  bool _isWrapped = true;

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
        title: Text(
          widget.note.type.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc500, letterSpacing: 2),
        ),
        centerTitle: true,
        actions: [
          if (widget.note.type == 'code')
            IconButton(
              icon: Icon(_isWrapped ? LucideIcons.wrapText : LucideIcons.alignLeft, 
                   size: 18, color: _isWrapped ? AppTheme.white : AppTheme.zinc500),
              onPressed: () => setState(() => _isWrapped = !_isWrapped),
              tooltip: 'Toggle Word Wrap',
            ),
          IconButton(
            icon: const Icon(LucideIcons.copy, size: 18, color: AppTheme.zinc500),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.note.content));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'), 
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  width: 200,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.note.title != null && widget.note.title!.isNotEmpty) ...[
                Text(
                  widget.note.title!,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.white),
                ),
                const SizedBox(height: 24),
                Container(height: 1, color: AppTheme.zinc900),
                const SizedBox(height: 32),
              ],
              _buildFullContent(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullContent(BuildContext context) {
    switch (widget.note.type) {
      case 'explanation':
        return MarkdownBody(
          data: widget.note.content,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(color: AppTheme.white, fontSize: 16, height: 1.8),
            listBullet: const TextStyle(color: AppTheme.zinc500),
            h1: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
            code: const TextStyle(backgroundColor: AppTheme.zinc900, fontFamily: 'monospace', fontSize: 14),
          ),
        );
      case 'code':
        return _buildCodeBlock();
      case 'image':
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: widget.note.content,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(height: 300, color: AppTheme.zinc950, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.zinc800))),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pinch to zoom',
              style: TextStyle(color: AppTheme.zinc700, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        );
      default:
        return Text(widget.note.content, style: const TextStyle(color: AppTheme.white));
    }
  }

  Widget _buildCodeBlock() {
    final language = widget.note.metadata?['language'] ?? 'dart';
    final lines = widget.note.content.split('\n');
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF282c34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.zinc900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF21252b),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(
                  language.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.zinc500),
                ),
                const Spacer(),
                const Icon(LucideIcons.code, size: 12, color: AppTheme.zinc600),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line Numbers
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 20, 8, 20),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFF3e4451), width: 1)),
                  ),
                  child: Column(
                    children: List.generate(lines.length, (i) => Text(
                      '${i + 1}',
                      style: const TextStyle(color: Color(0xFF636d83), fontFamily: 'monospace', fontSize: 12, height: 1.5),
                    )),
                  ),
                ),
                // Code Content
                Expanded(
                  child: _isWrapped 
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: HighlightView(
                          widget.note.content,
                          language: language,
                          theme: atomOneDarkTheme,
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.5),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(20),
                        child: HighlightView(
                          widget.note.content,
                          language: language,
                          theme: atomOneDarkTheme,
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.5),
                        ),
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
