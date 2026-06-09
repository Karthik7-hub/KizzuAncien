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
    return PopupMenuButton<ChallengeCategory>(
      initialValue: selectedCategory,
      onSelected: onCategoryChanged,
      color: AppTheme.zinc950,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.zinc900)),
      itemBuilder: (context) => [
        _buildItem(ChallengeCategory.all, 'All Challenges', LucideIcons.layers),
        _buildItem(ChallengeCategory.received, 'Received', LucideIcons.arrowDownLeft),
        _buildItem(ChallengeCategory.sent, 'Sent', LucideIcons.arrowUpRight),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.zinc900.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.zinc800),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIcon(selectedCategory), size: 14, color: AppTheme.zinc400),
            const SizedBox(width: 8),
            Text(
              _getLabel(selectedCategory),
              style: const TextStyle(color: AppTheme.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.zinc600),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<ChallengeCategory> _buildItem(ChallengeCategory value, String label, IconData icon) {
    final isSelected = selectedCategory == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: isSelected ? AppTheme.white : AppTheme.zinc500),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.white : AppTheme.zinc400,
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
