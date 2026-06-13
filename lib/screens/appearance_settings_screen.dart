import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: const AppHeader(
        title: 'Appearance',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildThemeTile(
            context,
            'Light',
            'Clean and bright interface',
            LucideIcons.sun,
            ThemeMode.light,
            themeProvider,
          ),
          _buildThemeTile(
            context,
            'Dark',
            'Modern and focused interface',
            LucideIcons.moon,
            ThemeMode.dark,
            themeProvider,
          ),
          _buildThemeTile(
            context,
            'System',
            'Follow your device settings',
            LucideIcons.monitor,
            ThemeMode.system,
            themeProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    ThemeMode mode,
    ThemeProvider provider,
  ) {
    final bool isSelected = provider.themeMode == mode;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => provider.setThemeMode(mode),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : (isDark ? AppTheme.zinc900 : AppTheme.zinc200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.zinc900 : AppTheme.zinc100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : AppTheme.zinc500, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.checkCircle, color: Theme.of(context).primaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}
