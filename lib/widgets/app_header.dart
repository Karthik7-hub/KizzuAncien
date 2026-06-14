import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool centerTitle;
  final double elevation;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.centerTitle = false,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return AppBar(
      backgroundColor: bgColor,
      elevation: elevation,
      surfaceTintColor: Colors.transparent,
      titleSpacing: showBackButton ? 0 : 20,
      centerTitle: centerTitle,
      leading: leading ?? (showBackButton
          ? IconButton(
              icon: Icon(LucideIcons.chevronLeft, color: primaryColor, size: 24),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      actions: actions != null ? [...actions!, const SizedBox(width: 8)] : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
