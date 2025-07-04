import 'package:flutter/material.dart';

extension CtxColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Text color that contrasts with background
  Color onBg([double opacity = 1]) =>
      Theme.of(this).colorScheme.onBackground.withOpacity(opacity);

  // Light card/background fill differing per theme
  Color cardFill([double darkOpacity = 0.1, double lightOpacity = 0.05]) =>
      (isDark ? Colors.white : Colors.black)
          .withOpacity(isDark ? darkOpacity : lightOpacity);

  // Border color subtle
  Color subtleBorder([double darkOpacity = 0.2, double lightOpacity = 0.1]) =>
      (isDark ? Colors.white : Colors.black)
          .withOpacity(isDark ? darkOpacity : lightOpacity);
} 