import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool isScrollable;

  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).textTheme.labelSmall?.color,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.labelLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                subtitle!,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );

    if (isScrollable) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: content,
            ),
          );
        },
      );
    }

    return content;
  }
}
