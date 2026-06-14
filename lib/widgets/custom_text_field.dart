import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final TextEditingController? controller;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.controller,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      enabled: enabled,
      onChanged: onChanged,
      style: TextStyle(
        color: enabled
            ? (isDark ? AppTheme.white : AppTheme.zinc950)
            : (isDark ? AppTheme.zinc500 : AppTheme.zinc400),
        fontSize: 16,
      ),
      cursorColor: isDark ? AppTheme.white : AppTheme.black,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? AppTheme.zinc600 : AppTheme.zinc400,
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: enabled
            ? (isDark ? AppTheme.zinc950 : AppTheme.white)
            : (isDark ? AppTheme.zinc900.withValues(alpha: 0.5) : AppTheme.zinc100),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(
            color: isDark ? AppTheme.zinc900 : AppTheme.zinc200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(
            color: isDark ? AppTheme.zinc900 : AppTheme.zinc200,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(
            color: isDark ? AppTheme.zinc950 : AppTheme.zinc200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide(
            color: isDark ? AppTheme.white : AppTheme.black,
            width: 1,
          ),
        ),
      ),
    );
  }
}
