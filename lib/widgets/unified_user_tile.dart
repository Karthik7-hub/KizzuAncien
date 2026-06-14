import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import 'avatar_widget.dart';
import 'app_card.dart';

enum UserTileVariant { activity, list, search }

class UnifiedUserTile extends StatelessWidget {
  final User user;
  final UserTileVariant variant;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const UnifiedUserTile({
    super.key,
    required this.user,
    this.variant = UserTileVariant.list,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Row(
      children: [
        AvatarWidget(
          user: user,
          size: variant == UserTileVariant.activity ? 36 : 48,
          showBorder: false,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.name,
                style: TextStyle(
                  fontSize: variant == UserTileVariant.activity ? 13 : 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.white : AppTheme.black,
                ),
              ),
              if (subtitle != null || variant != UserTileVariant.activity)
                Text(
                  subtitle ?? '@${user.username}',
                  style: TextStyle(
                    fontSize: variant == UserTileVariant.activity ? 12 : 13,
                    color: AppTheme.zinc500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );

    if (variant == UserTileVariant.activity) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: content,
    );
  }
}
