import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/avatar_widget.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../utils/code_highlighter.dart';
import 'edit_note_screen.dart';

class NoteViewerScreen extends StatefulWidget {
  final Note note;
  const NoteViewerScreen({super.key, required this.note});

  @override
  State<NoteViewerScreen> createState() => _NoteViewerScreenState();
}

class _NoteViewerScreenState extends State<NoteViewerScreen> {
  bool _isWrapped = true;

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challengeProvider = context.watch<ChallengeProvider>();
    final notes = challengeProvider.challengeNotes[widget.note.challengeId] ?? [];
    final note = notes.firstWhere((n) => n.id == widget.note.id, orElse: () => widget.note);
    final user = context.watch<AuthProvider>().user;
    final bool canEdit = user != null && note.createdBy.id == user.id;

    final bodyMediumColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      appBar: AppHeader(
        title: _getNoteTitle(note),
        showBackButton: true,
        actions: _buildActions(note, canEdit),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetaInfo(note),
            const SizedBox(height: 24),
            if (note.description != null && note.description!.isNotEmpty) ...[
              Text(
                note.description!,
                style: TextStyle(color: bodyMediumColor, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),
            ],
            _buildContent(note),
          ],
        ),
      ),
    );
  }

  String _getNoteTitle(Note note) {
    switch (note.type) {
      case NoteType.code: return 'Code Note';
      case NoteType.explanation: return 'Explanation';
      case NoteType.image: return 'Images';
      case NoteType.link: return 'Link';
    }
  }

  List<Widget>? _buildActions(Note note, bool canEdit) {
    final actions = <Widget>[];

    if (canEdit) {
      actions.add(
        IconButton(
          icon: Icon(LucideIcons.edit2, color: Theme.of(context).primaryColor, size: 20),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditNoteScreen(
                  challengeId: note.challengeId,
                  note: note,
                ),
              ),
            );
          },
          tooltip: 'Edit Note',
        ),
      );
    }

    if (note.type == NoteType.code) {
      actions.addAll([
        IconButton(
          icon: Icon(_isWrapped ? LucideIcons.wrapText : LucideIcons.alignLeft, color: Theme.of(context).primaryColor, size: 20),
          onPressed: () => setState(() => _isWrapped = !_isWrapped),
          tooltip: 'Toggle Wrap',
        ),
        IconButton(
          icon: Icon(LucideIcons.copy, color: Theme.of(context).primaryColor, size: 20),
          onPressed: () => _copyToClipboard(note.code),
          tooltip: 'Copy Code',
        ),
      ]);
    }

    return actions.isNotEmpty ? actions : null;
  }

  Widget _buildMetaInfo(Note note) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        AvatarWidget(user: note.createdBy, size: 32, showBorder: false),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.createdBy.name, 
              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14, fontWeight: FontWeight.bold)
            ),
            Text(
              timeago.format(note.createdAt), 
              style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 10, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        const Spacer(),
        if (note.type == NoteType.code)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.zinc900 : AppTheme.zinc100, 
              borderRadius: BorderRadius.circular(8),
              border: isDark ? null : Border.all(color: AppTheme.zinc200),
            ),
            child: Text(
              note.language, 
              style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 10, fontWeight: FontWeight.bold)
            ),
          ),
      ],
    );
  }

  Widget _buildContent(Note note) {
    switch (note.type) {
      case NoteType.code:
        return _buildCodeViewer(note);
      case NoteType.explanation:
        return _buildExplanationViewer(note);
      case NoteType.image:
        return _buildImageViewer(note);
      case NoteType.link:
        return _buildLinkViewer(note);
    }
  }

  Widget _buildCodeViewer(Note note) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseStyle = TextStyle(
      color: Theme.of(context).primaryColor,
      fontFamily: 'monospace',
      fontSize: 12,
      height: 1.5,
    );

    final highlightedSpan = CodeHighlighter.highlight(
      code: note.code,
      language: note.language,
      context: context,
      baseStyle: baseStyle,
    );

    final codeLines = CodeHighlighter.splitHighlightedLines(highlightedSpan, baseStyle);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isWrapped
              ? SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(codeLines.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.labelSmall?.color,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text.rich(
                                codeLines[index],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectionArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(codeLines.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.labelSmall?.color,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text.rich(
                                codeLines[index],
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildExplanationViewer(Note note) {
    return Text(
      note.explanation,
      style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16, height: 1.6),
    );
  }

  Widget _buildImageViewer(Note note) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: note.images.map((url) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          onTap: () => _showFullScreenImage(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: url,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200, 
                color: isDark ? AppTheme.zinc900 : AppTheme.zinc100, 
                child: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor, strokeWidth: 2))
              ),
              errorWidget: (context, url, error) => Container(
                height: 100, 
                color: isDark ? AppTheme.zinc900 : AppTheme.zinc100, 
                child: Icon(LucideIcons.imageOff, color: Theme.of(context).textTheme.labelSmall?.color)
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildLinkViewer(Note note) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color, 
              shape: BoxShape.circle, 
              border: Border.all(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200)
            ),
            child: Icon(LucideIcons.externalLink, color: Theme.of(context).primaryColor, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            note.title, 
            style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 20, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          Text(note.url, style: const TextStyle(color: Colors.blueAccent, fontSize: 14)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.tryParse(note.url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open the link.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Open in Browser', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String url) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.white)),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    )));
  }
}
