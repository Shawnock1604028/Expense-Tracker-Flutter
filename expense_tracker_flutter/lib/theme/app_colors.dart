import 'package:flutter/material.dart';

abstract final class AppColors {
  /// Soft ash tone for profile / highlight cards.
  static Color profileCardAsh(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF3D434A) : const Color(0xFFD8DCE2);
  }

  static Color profileCardAshBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF525A63) : const Color(0xFFC4CAD3);
  }
}
