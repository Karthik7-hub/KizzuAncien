import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/note.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'avatar_widget.dart';

class NotePreviewCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final Widget? trailing;

  const NotePreviewCard({
    super.key,
    required this.note,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildContent(context),
          if (note.description != null && note.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note.description!,
              style: TextStyle(
                color: isDark ? AppTheme.zinc400 : AppTheme.zinc600,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            height: 0.5, 
            color: isDark ? AppTheme.zinc800.withValues(alpha: 0.5) : AppTheme.zinc200
          ),
          const SizedBox(height: 8),
          _buildAuthorRow(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    IconData icon;
    Color color;

    switch (note.type) {
      case NoteType.code:
        icon = LucideIcons.code;
        color = AppTheme.accent;
        break;
      case NoteType.explanation:
        icon = LucideIcons.fileText;
        color = Colors.green;
        break;
      case NoteType.image:
        icon = LucideIcons.image;
        color = isDark ? AppTheme.zinc300 : AppTheme.zinc600;
        break;
      case NoteType.link:
        icon = LucideIcons.link;
        color = AppTheme.accent;
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            note.title.isEmpty ? _getDefaultTitle() : note.title,
            style: TextStyle(
              color: isDark ? AppTheme.white : AppTheme.zinc950,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing ?? Icon(
          LucideIcons.chevronRight,
          color: isDark ? AppTheme.zinc800 : AppTheme.zinc300,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (note.type) {
      case NoteType.code:
        return Row(
          children: [
            _buildBadge(context, note.language),
            const SizedBox(width: 8),
            _buildBadge(context, '${_getLineCount(note.code)} lines'),
          ],
        );
      case NoteType.explanation:
        return Text(
          note.explanation,
          style: TextStyle(
            color: isDark ? AppTheme.zinc400 : AppTheme.zinc600,
            fontSize: 13,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      case NoteType.image:
        if (note.images.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: note.images.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(note.images[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        );
      case NoteType.link:
        return Text(
          note.url,
          style: const TextStyle(
            color: AppTheme.accent,
            fontSize: 13,
            decoration: TextDecoration.underline,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  Widget _buildBadge(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.zinc900 : AppTheme.zinc100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? AppTheme.zinc500 : AppTheme.zinc600,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAuthorRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        AvatarWidget(user: note.createdBy, size: 20, showBorder: false),
        const SizedBox(width: 8),
        Text(
          note.createdBy.name,
          style: TextStyle(
            color: isDark ? AppTheme.zinc400 : AppTheme.zinc600,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Icon(LucideIcons.clock, size: 10, color: isDark ? AppTheme.zinc500 : AppTheme.zinc400),
        const SizedBox(width: 4),
        Text(
          timeago.format(note.updatedAt),
          style: TextStyle(
            color: isDark ? AppTheme.zinc500 : AppTheme.zinc400,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _getDefaultTitle() {
    switch (note.type) {
      case NoteType.code:
        return 'Untitled Code';
      case NoteType.explanation:
        return 'Untitled Explanation';
      case NoteType.image:
        return 'Untitled Image';
      case NoteType.link:
        return 'Untitled Link';
    }
  }

  int _getLineCount(String text) {
    if (text.isEmpty) return 0;
    return text.split('\n').length;
  }
}
