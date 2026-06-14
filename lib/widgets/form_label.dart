import 'package:flutter/material.dart';

class FormLabel extends StatelessWidget {
  final String label;
  final EdgeInsetsGeometry padding;

  const FormLabel({
    super.key,
    required this.label,
    this.padding = const EdgeInsets.only(left: 4, bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).textTheme.labelLarge?.color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
