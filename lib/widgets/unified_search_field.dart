import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class UnifiedSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final EdgeInsetsGeometry? margin;

  const UnifiedSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.margin,
  });

  @override
  State<UnifiedSearchField> createState() => _UnifiedSearchFieldState();
}

class _UnifiedSearchFieldState extends State<UnifiedSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild to toggle suffix icon
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      style: TextStyle(
        color: isDark ? AppTheme.white : AppTheme.black,
        fontSize: 14,
      ),
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: isDark ? AppTheme.zinc900 : AppTheme.zinc100,
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: isDark ? AppTheme.zinc600 : AppTheme.zinc400,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          LucideIcons.search,
          color: isDark ? AppTheme.zinc500 : AppTheme.zinc400,
          size: 18,
        ),
        suffixIcon: widget.controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  widget.controller.clear();
                  if (widget.onChanged != null) widget.onChanged!('');
                  if (widget.onClear != null) widget.onClear!();
                },
                child: Icon(
                  LucideIcons.xCircle,
                  color: isDark ? AppTheme.zinc600 : AppTheme.zinc400,
                  size: 16,
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: isDark ? AppTheme.zinc800 : AppTheme.zinc200,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: isDark ? AppTheme.zinc800 : AppTheme.zinc200,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: isDark ? AppTheme.white : AppTheme.black,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
