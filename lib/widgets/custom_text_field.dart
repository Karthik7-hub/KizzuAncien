import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.white, fontSize: 16),
      cursorColor: AppTheme.white,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppTheme.zinc600, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: AppTheme.zinc950,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppTheme.zinc900),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppTheme.zinc900),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppTheme.white, width: 1),
        ),
      ),
    );
  }
}
