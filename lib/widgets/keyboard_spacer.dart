import 'package:flutter/material.dart';

/// A widget that isolates rebuilds triggered by keyboard height changes.
/// 
/// By wrapping MediaQuery.of(context).viewInsets.bottom in its own widget,
/// only this spacer rebuilds when the keyboard opens/closes, rather than
/// the entire screen.
class IsolatedKeyboardSpacer extends StatelessWidget {
  final double additionalPadding;

  const IsolatedKeyboardSpacer({
    super.key,
    this.additionalPadding = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // Only this leaf widget rebuilds when viewInsets change
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return SizedBox(
      height: bottomInset > 0 ? bottomInset : additionalPadding,
    );
  }
}
