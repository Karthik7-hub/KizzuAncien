import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/avatar_widget.dart';

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
    final bodyMediumColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      appBar: AppHeader(
        title: _getNoteTitle(),
        showBackButton: true,
        actions: _buildActions(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetaInfo(),
            const SizedBox(height: 24),
            if (widget.note.description != null && widget.note.description!.isNotEmpty) ...[
              Text(
                widget.note.description!,
                style: TextStyle(color: bodyMediumColor, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),
            ],
            _buildContent(),
          ],
        ),
      ),
    );
  }

  String _getNoteTitle() {
    switch (widget.note.type) {
      case NoteType.code: return 'Code Note';
      case NoteType.explanation: return 'Explanation';
      case NoteType.image: return 'Images';
      case NoteType.link: return 'Link';
    }
  }

  List<Widget>? _buildActions() {
    if (widget.note.type == NoteType.code) {
      return [
        IconButton(
          icon: Icon(_isWrapped ? LucideIcons.wrapText : LucideIcons.alignLeft, color: Theme.of(context).primaryColor, size: 20),
          onPressed: () => setState(() => _isWrapped = !_isWrapped),
          tooltip: 'Toggle Wrap',
        ),
        IconButton(
          icon: Icon(LucideIcons.copy, color: Theme.of(context).primaryColor, size: 20),
          onPressed: () => _copyToClipboard(widget.note.code),
          tooltip: 'Copy Code',
        ),
      ];
    }
    return null;
  }

  Widget _buildMetaInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        AvatarWidget(user: widget.note.createdBy, size: 32, showBorder: false),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.note.createdBy.name, 
              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14, fontWeight: FontWeight.bold)
            ),
            Text(
              timeago.format(widget.note.createdAt), 
              style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 10, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        const Spacer(),
        if (widget.note.type == NoteType.code)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.zinc900 : AppTheme.zinc100, 
              borderRadius: BorderRadius.circular(8),
              border: isDark ? null : Border.all(color: AppTheme.zinc200),
            ),
            child: Text(
              widget.note.language, 
              style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 10, fontWeight: FontWeight.bold)
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    switch (widget.note.type) {
      case NoteType.code:
        return _buildCodeViewer();
      case NoteType.explanation:
        return _buildExplanationViewer();
      case NoteType.image:
        return _buildImageViewer();
      case NoteType.link:
        return _buildLinkViewer();
    }
  }

  Widget _buildCodeViewer() {
    final lines = widget.note.code.split('\n');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: _isWrapped ? Axis.vertical : Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line numbers
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(lines.length, (i) => Text(
                    '${i + 1} ',
                    style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontFamily: 'monospace', fontSize: 12),
                  )),
                ),
                const SizedBox(width: 16),
                // Code
                SizedBox(
                  width: _isWrapped ? MediaQuery.of(context).size.width - 100 : null,
                  child: SelectableText(
                    widget.note.code,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationViewer() {
    return Text(
      widget.note.explanation,
      style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16, height: 1.6),
    );
  }

  Widget _buildImageViewer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: widget.note.images.map((url) => Padding(
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

  Widget _buildLinkViewer() {
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
            widget.note.title, 
            style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 20, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          Text(widget.note.url, style: const TextStyle(color: Colors.blueAccent, fontSize: 14)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.tryParse(widget.note.url);
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
