import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

enum ChallengeCategory { all, received, sent }

class ChallengeFilterDropdown extends StatelessWidget {
  final ChallengeCategory selectedCategory;
  final ValueChanged<ChallengeCategory> onCategoryChanged;

  const ChallengeFilterDropdown({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<ChallengeCategory>(
      initialValue: selectedCategory,
      onSelected: onCategoryChanged,
      color: isDark ? AppTheme.zinc950 : AppTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), 
        side: BorderSide(color: isDark ? AppTheme.zinc900 : AppTheme.zinc200),
      ),
      itemBuilder: (context) => [
        _buildItem(context, ChallengeCategory.all, 'All Challenges', LucideIcons.layers),
        _buildItem(context, ChallengeCategory.received, 'Received', LucideIcons.arrowDownLeft),
        _buildItem(context, ChallengeCategory.sent, 'Sent', LucideIcons.arrowUpRight),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.zinc900.withValues(alpha: 0.5) : AppTheme.zinc100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppTheme.zinc800 : AppTheme.zinc200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIcon(selectedCategory), size: 14, color: isDark ? AppTheme.zinc400 : AppTheme.zinc500),
            const SizedBox(width: 8),
            Text(
              _getLabel(selectedCategory),
              style: TextStyle(
                color: isDark ? AppTheme.white : AppTheme.zinc950,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 14, color: isDark ? AppTheme.zinc600 : AppTheme.zinc400),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<ChallengeCategory> _buildItem(BuildContext context, ChallengeCategory value, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedCategory == value;
    final Color activeColor = isDark ? AppTheme.white : AppTheme.zinc950;
    final Color inactiveColor = isDark ? AppTheme.zinc500 : AppTheme.zinc400;
    final Color inactiveTextColor = isDark ? AppTheme.zinc400 : AppTheme.zinc600;

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: isSelected ? activeColor : inactiveColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveTextColor,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.all: return LucideIcons.layers;
      case ChallengeCategory.received: return LucideIcons.arrowDownLeft;
      case ChallengeCategory.sent: return LucideIcons.arrowUpRight;
    }
  }

  String _getLabel(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.all: return 'All';
      case ChallengeCategory.received: return 'Received';
      case ChallengeCategory.sent: return 'Sent';
    }
  }
}
